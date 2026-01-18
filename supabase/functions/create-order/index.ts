// supabase/functions/create-order/index.ts
// 
// This Edge Function creates Razorpay orders
// Razorpay Keys are stored here securely, NOT in client app

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Get secrets from environment
const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')!
const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')!
const SUPABASE_URL = Deno. env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env. get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateOrderRequest {
  amount: number  // Amount in paise
  currency: string
  planId: string
  planType: string
  userId: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { amount, currency, planId, planType, userId }: CreateOrderRequest = await req.json()

    // Validate
    if (!amount || amount < 100) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid amount' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type':  'application/json' } }
      )
    }

    if (!userId) {
      return new Response(
        JSON.stringify({ success: false, error: 'User ID required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Razorpay order
    const auth = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`)
    
    const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: amount,
        currency: currency || 'INR',
        receipt: `welist_${userId}_${Date.now()}`,
        notes: {
          planId: planId,
          planType: planType,
          userId: userId,
        },
      }),
    })

    const razorpayData = await razorpayResponse.json()

    if (razorpayData.error) {
      console.error('Razorpay Error:', razorpayData.error)
      return new Response(
        JSON.stringify({ success: false, error: razorpayData.error.description }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Determine unlocks based on plan
    const planUnlocks:  Record<string, number> = {
      'basic': 3,
      'plus': 8,
      'pro': 15,
      'starter': 0,
      'business': 0,
    }

    // Create subscription record
    const { data: subscription, error: subError } = await supabase
      .from('subscriptions')
      .insert({
        owner_id: userId,
        owner_type: planType === 'partner' ? 'professional' : 'user',
        plan:  planId,
        status: 'pending',
        amount: amount / 100,
        currency: currency || 'INR',
        order_id: razorpayData.id,
        start_date: new Date().toISOString(),
        end_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      })
      .select()
      .single()

    if (subError) {
      console.error('Subscription Error:', subError)
    }

    // Create transaction record
    await supabase.from('payment_transactions').insert({
      user_id: userId,
      subscription_id: subscription?. id,
      amount: amount / 100,
      currency: currency || 'INR',
      payment_provider: 'razorpay',
      order_id: razorpayData.id,
      status: 'pending',
      description: `Subscription:  ${planId}`,
      metadata: {
        planId: planId,
        planType: planType,
        unlocks: planUnlocks[planId] || 0,
      },
    })

    return new Response(
      JSON.stringify({
        success: true,
        orderId: razorpayData.id,
        amount: razorpayData.amount,
        currency: razorpayData.currency,
      }),
      { headers: { ... corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Create Order Error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers:  { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})