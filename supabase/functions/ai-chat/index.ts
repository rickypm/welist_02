// supabase/functions/ai-chat/index.ts
// 
// AI Chat Edge Function with Usage Limits
// - Free users: 3 AI chats per day
// - Paid users:  Unlimited
// - OpenAI API key is stored here securely

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Get secrets from environment
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')! 
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env. get('SUPABASE_SERVICE_ROLE_KEY')!

// Configuration
const FREE_DAILY_LIMIT = 3

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ChatRequest {
  message: string
  city:  string
  userId?:  string
  history?: Array<{ role: string; content: string }>
  skipAI?: boolean  // If true, only return search results
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { message, city, userId, history, skipAI }: ChatRequest = await req.json()

    if (!message) {
      return new Response(
        JSON.stringify({ success: false, error: 'Message is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // ============================================================
    // CHECK USAGE LIMIT (for authenticated users)
    // ============================================================
    
    let canUseAI = true
    let remaining = FREE_DAILY_LIMIT
    let isPaidUser = false
    let limitReached = false

    if (userId) {
      // Check user's AI usage limit
      const { data:  limitCheck, error: limitError } = await supabase
        .rpc('check_ai_usage_limit', { 
          p_user_id:  userId, 
          p_daily_limit: FREE_DAILY_LIMIT 
        })

      if (! limitError && limitCheck) {
        canUseAI = limitCheck. canUse
        remaining = limitCheck.remaining
        isPaidUser = limitCheck.isPaid
        limitReached = ! canUseAI && ! isPaidUser
      }
    }

    // ============================================================
    // IF LIMIT REACHED OR SKIP AI - RETURN SEARCH ONLY
    // ============================================================
    
    if (limitReached || skipAI) {
      // Extract search intent locally (no AI call)
      const searchIntent = extractSearchIntent(message)
      
      // Search for professionals
      let matchedProfessionals: string[] = []
      if (searchIntent?. category) {
        const { data: professionals } = await supabase
          . from('professionals')
          .select('id, display_name, profession, city, rating, is_verified')
          .eq('city', city)
          .eq('is_available', true)
          .or(`profession.ilike.%${searchIntent.category}%,services.cs.{${searchIntent.category}}`)
          .limit(10)

        if (professionals) {
          matchedProfessionals = professionals.map(p => p.id)
        }
      }

      // Generate limit-reached message
      const limitMessage = limitReached
        ? `🔒 You've reached your daily limit of ${FREE_DAILY_LIMIT} AI chat requests.\n\n` +
          `Don't worry!  I can still help you find services.  ` +
          (searchIntent?.category 
            ? `Here are some ${formatCategory(searchIntent.category)} professionals in ${city}. `
            : `Browse the categories below or try a simple search.`) +
          `\n\n💡 **Upgrade to a paid plan for unlimited AI assistance!**`
        : `Here are some results for your search in ${city}. `

      return new Response(
        JSON.stringify({
          success: true,
          message: limitMessage,
          searchIntent: searchIntent,
          matchedProfessionals: matchedProfessionals. length > 0 ? matchedProfessionals : null,
          limitReached: limitReached,
          remaining: remaining,
          isPaid: isPaidUser,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ============================================================
    // CALL OPENAI (User has remaining quota or is paid)
    // ============================================================

    // Get categories for context
    const { data: categories } = await supabase
      .from('categories')
      .select('name, slug')
      .eq('is_active', true)

    const categoryList = categories?.map(c => c.name).join(', ') || 
      'Electrician, Plumber, Carpenter, Painter, AC Repair, Cleaning, Tutoring, Beauty, Mechanic, Legal, Medical, IT, Photography, Catering, Event Planning, Pest Control'

    // System prompt
    const systemPrompt = `You are WeList AI, a helpful assistant for finding local services in ${city}, India. 

Your job is to: 
1. Understand what service the user needs
2. Ask clarifying questions if needed
3. Help them find the right professional

Available service categories: ${categoryList}

Guidelines:
- Be friendly, helpful, and concise
- If user asks for a service, identify the category
- If unclear, ask one clarifying question
- Keep responses under 100 words
- Always be polite and professional
- If user greets you, greet back and ask how you can help find services

When you identify a service need, include this JSON at the end of your response:
[SEARCH_INTENT:  {"category": "category-slug", "query": "user's original request"}]`

    // Build messages array
    const messages = [
      { role: 'system', content: systemPrompt },
    ]

    // Add history if provided (last 6 messages max)
    if (history && history.length > 0) {
      const recentHistory = history.slice(-6)
      messages.push(...recentHistory)
    }

    // Add current message
    messages.push({ role: 'user', content: message })

    // Call OpenAI API
    const openAIResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: messages,
        max_tokens: 300,
        temperature:  0.7,
      }),
    })

    const openAIData = await openAIResponse.json()

    if (openAIData.error) {
      console.error('OpenAI Error:', openAIData.error)
      return new Response(
        JSON.stringify({ success: false, error: openAIData.error. message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let aiMessage = openAIData.choices[0].message.content

    // Extract search intent if present
    let searchIntent = null
    const intentMatch = aiMessage.match(/\[SEARCH_INTENT:\s*({.*?})\]/s)
    if (intentMatch) {
      try {
        searchIntent = JSON. parse(intentMatch[1])
        // Remove the intent JSON from the displayed message
        aiMessage = aiMessage.replace(/\[SEARCH_INTENT:\s*{.*?}\]/s, '').trim()
      } catch (e) {
        console.error('Failed to parse search intent:', e)
      }
    }

    // If we have a search intent, find matching professionals
    let matchedProfessionals: string[] = []
    if (searchIntent?.category) {
      const { data: professionals } = await supabase
        .from('professionals')
        .select('id')
        .eq('city', city)
        .eq('is_available', true)
        .or(`profession.ilike.%${searchIntent.category}%,services.cs.{${searchIntent. category}}`)
        .limit(10)

      if (professionals) {
        matchedProfessionals = professionals.map(p => p.id)
      }
    }

    // ============================================================
    // INCREMENT USAGE COUNT (for free users)
    // ============================================================
    
    if (userId && !isPaidUser) {
      await supabase. rpc('increment_ai_usage', { p_user_id: userId })
      remaining = Math.max(0, remaining - 1)
    }

    // Log chat for analytics
    if (userId) {
      const sessionId = crypto.randomUUID()
      await supabase.from('ai_chat_logs').insert([
        {
          user_id: userId,
          session_id: sessionId,
          role: 'user',
          content: message,
        },
        {
          user_id: userId,
          session_id: sessionId,
          role: 'assistant',
          content: aiMessage,
          matched_professionals: matchedProfessionals.length > 0 ?  matchedProfessionals : null,
        }
      ])
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: aiMessage,
        searchIntent: searchIntent,
        matchedProfessionals: matchedProfessionals.length > 0 ? matchedProfessionals : null,
        limitReached: false,
        remaining: isPaidUser ? -1 : remaining,
        isPaid: isPaidUser,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('AI Chat Error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type':  'application/json' } }
    )
  }
})

// ============================================================
// HELPER FUNCTIONS
// ============================================================

function extractSearchIntent(message: string): { category?:  string; query?: string } | null {
  const categories:  Record<string, string[]> = {
    'electrician': ['electrician', 'electric', 'wiring', 'power', 'light', 'fan', 'switch'],
    'plumber': ['plumber', 'plumbing', 'pipe', 'water', 'tap', 'leak', 'drain', 'toilet'],
    'carpenter': ['carpenter', 'carpentry', 'furniture', 'wood', 'cabinet', 'door'],
    'painter': ['painter', 'painting', 'paint', 'wall', 'color'],
    'ac-repair': ['ac', 'air conditioner', 'cooling', 'hvac'],
    'cleaning': ['cleaning', 'cleaner', 'housekeeping', 'maid', 'deep clean'],
    'tutoring':  ['tutor', 'teacher', 'teaching', 'coaching', 'tuition'],
    'beauty': ['beauty', 'salon', 'parlour', 'haircut', 'makeup', 'facial'],
    'mechanic': ['mechanic', 'car', 'bike', 'vehicle', 'garage'],
    'legal': ['lawyer', 'legal', 'advocate', 'law', 'court'],
    'medical': ['doctor', 'medical', 'clinic', 'health'],
    'it-tech': ['computer', 'laptop', 'it', 'tech', 'software'],
    'photography': ['photographer', 'photography', 'photo', 'video'],
    'catering': ['catering', 'caterer', 'food', 'cook', 'chef'],
    'event-planning':  ['event', 'wedding', 'party', 'decoration'],
    'pest-control': ['pest', 'cockroach', 'termite', 'insect', 'rat'],
  }

  const lowerMessage = message.toLowerCase()

  for (const [category, keywords] of Object.entries(categories)) {
    for (const keyword of keywords) {
      if (lowerMessage.includes(keyword)) {
        return { category, query: message }
      }
    }
  }

  return null
}

function formatCategory(slug: string): string {
  return slug
    .replace(/-/g, ' ')
    .split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}