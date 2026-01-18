// supabase/functions/verify-payment/index.ts
// 
// This Edge Function verifies Razorpay payment signatures
// Razorpay Secret Key is stored here securely, NOT in client app

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createHmac } from "https://deno.land/std@0.168.0/node/crypto.ts"

// Get secrets from environment
const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface VerifyRequest {
  razorpay_order_id: string
  razorpay_payment_id: string
  razorpay_signature: string
  userId:  string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { 
      razorpay_order_id, 
      razorpay_payment_id, 
      razorpay_signature,
      userId 
    }: VerifyRequest = await req.json()

    // Validate required fields
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required payment fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate expected signature
    const body = razorpay_order_id + "|" + razorpay_payment_id
    const expectedSignature = createHmac('sha256', RAZORPAY_KEY_SECRET)
      .update(body)
      .digest('hex')

    // Verify signature
    const isValid = expectedSignature === razorpay_signature

    if (!isValid) {
      console.error('Invalid payment signature')
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Invalid payment signature.  Payment may be fraudulent.' 
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Signature valid - update database
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Record the successful payment
    const { error:  txnError } = await supabase
      .from('payment_transactions')
      .update({
        status: 'success',
        payment_id: razorpay_payment_id,
        signature: razorpay_signature,
        updated_at: new Date().toISOString(),
      })
      .eq('order_id', razorpay_order_id)

    if (txnError) {
      console.error('Failed to update transaction:', txnError)
    }

    // Get the transaction to find subscription details
    const { data: transaction } = await supabase
      . from('payment_transactions')
      .select('subscription_id, metadata')
      .eq('order_id', razorpay_order_id)
      .single()

    // Activate subscription if present
    if (transaction?.subscription_id) {
      await supabase
        .from('subscriptions')
        .update({
          status: 'active',
          payment_id: razorpay_payment_id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', transaction.subscription_id)

      // Update user's subscription plan
      const metadata = transaction.metadata as any
      if (metadata?.planId && userId) {
        await supabase
          .from('users')
          .update({
            subscription_plan: metadata.planId,
            unlocks_remaining: metadata.unlocks || 0,
            updated_at: new Date().toISOString(),
          })
          .eq('id', userId)
      }
    }

    // Track event
    if (userId) {
      await supabase. from('events').insert({
        user_id: userId,
        event_type: 'payment_success',
        event_data: {
          order_id: razorpay_order_id,
          payment_id: razorpay_payment_id,
        },
      })
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Payment verified and subscription activated! ',
        paymentId: razorpay_payment_id,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Verify Payment Error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type':  'application/json' } }
    )
  }
})