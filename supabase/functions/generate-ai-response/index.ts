import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  console.log('🤖 AI Chat Function started, method:', req.method)
  
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    console.log('✅ CORS preflight handled')
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📖 Parsing request body...')
    const { 
      message, 
      personalityType, 
      goalContext, 
      recentCheckIns, 
      conversationHistory 
    } = await req.json()
    
    console.log('💬 Message received:', message?.substring(0, 100) + '...')
    console.log('🧠 Personality:', personalityType)
    console.log('🎯 Goals:', goalContext?.length || 0)
    
    if (!message) {
      throw new Error('No message provided')
    }

    console.log('🤖 Calling OpenAI API...')
    
    // Build personality-specific system prompt
    const systemPrompt = buildSystemPrompt(personalityType, goalContext, recentCheckIns)
    
    // Build conversation context
    const conversationContext = buildConversationContext(conversationHistory, message)
    
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages: [
          {
            role: 'system',
            content: systemPrompt
          },
          ...conversationContext,
          {
            role: 'user',
            content: message
          }
        ],
        temperature: 0.7,
        max_tokens: 500
      })
    })

    if (!openaiResponse.ok) {
      console.error('❌ OpenAI API error:', openaiResponse.status, openaiResponse.statusText)
      const errorText = await openaiResponse.text()
      console.error('❌ Error details:', errorText)
      throw new Error(`OpenAI API error: ${openaiResponse.status}`)
    }

    const openaiData = await openaiResponse.json()
    console.log('✅ OpenAI response received')
    
    const aiContent = openaiData.choices[0]?.message?.content
    if (!aiContent) {
      throw new Error('No content in OpenAI response')
    }

    console.log('✅ Successfully generated AI response')

    return new Response(JSON.stringify({ 
      response: aiContent,
      personalityType: personalityType,
      timestamp: new Date().toISOString()
    }), {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'application/json' 
      },
    })

  } catch (error) {
    console.error('💥 Function error:', error)
    
    // Return a fallback response in case of errors
    const fallbackResponse = {
      response: "I'm having trouble processing that right now. Could you try rephrasing your message? I'm here to help! 💙",
      personalityType: personalityType || "supporter",
      timestamp: new Date().toISOString()
    }
    
    return new Response(JSON.stringify(fallbackResponse), {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'application/json' 
      },
    })
  }
})

function buildSystemPrompt(personalityType: string, goalContext: any[], recentCheckIns: any[]) {
  const personalityPrompts = {
    'encourager': 'You are a warm, supportive AI coach who focuses on encouragement and positive reinforcement. You celebrate small wins and help users see their progress. Use encouraging language and remind them of their strengths.',
    'achiever': 'You are a results-focused AI coach who emphasizes progress and goal achievement. You help users break down challenges into actionable steps and track their progress toward specific outcomes.',
    'explorer': 'You are a curious, open-minded AI coach who encourages experimentation and discovery. You help users explore new approaches and think creatively about their goals and challenges.',
    'supporter': 'You are a caring, empathetic AI coach who focuses on emotional support and understanding. You validate feelings and help users process their experiences with compassion.',
    'minimalist': 'You are a clear, direct AI coach who values simplicity and focus. You help users identify what truly matters and eliminate unnecessary complexity from their goals.',
    'reflector': 'You are a thoughtful, introspective AI coach who encourages deep reflection and self-awareness. You help users understand patterns in their behavior and make meaningful insights.'
  }

  const personalityPrompt = personalityPrompts[personalityType as keyof typeof personalityPrompts] || personalityPrompts['supporter']
  
  const goalContextText = goalContext?.length > 0 
    ? `\n\nActive Goals: ${goalContext.map(g => `${g.category} - ${g.title} (${g.progressPercentage}% complete)`).join(', ')}`
    : ''

  const recentMoodText = recentCheckIns?.length > 0
    ? `\n\nRecent Mood Pattern: ${recentCheckIns.slice(-3).map(c => c.moodName).join(' → ')}`
    : ''

  return `You are flect, an AI personal coach designed to help users with their personal growth and goal achievement. 

${personalityPrompt}

Your role is to:
1. Provide personalized, supportive guidance based on the user's personality type
2. Help users reflect on their progress and challenges
3. Offer actionable advice and encouragement
4. Reference their active goals when relevant
5. Maintain a conversational, friendly tone
6. Use emojis sparingly but effectively to add warmth
7. Keep responses concise (2-3 sentences) but meaningful

${goalContextText}
${recentMoodText}

Remember: You're not a therapist, but a supportive coach helping users achieve their personal goals. Always be encouraging and solution-focused.`
}

function buildConversationContext(conversationHistory: any[], currentMessage: string) {
  if (!conversationHistory || conversationHistory.length === 0) {
    return []
  }

  // Take the last 5 messages for context (to stay within token limits)
  const recentMessages = conversationHistory.slice(-5)
  
  return recentMessages.map(msg => ({
    role: msg.type === 'user' ? 'user' : 'assistant',
    content: msg.content
  }))
} 