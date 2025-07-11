import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  console.log('🎯 Check-in processing function started, method:', req.method)
  
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    console.log('✅ CORS preflight handled')
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📖 Parsing check-in request...')
    const { happyThing, improveThing, userHistory } = await req.json()
    
    console.log('📝 Happy thing:', happyThing?.substring(0, 50) + '...')
    console.log('📝 Improve thing:', improveThing?.substring(0, 50) + '...')
    console.log('📚 User history entries:', userHistory?.length || 0)
    
    if (!happyThing || !improveThing) {
      throw new Error('Both happyThing and improveThing are required')
    }

    console.log('🤖 Calling OpenAI API for check-in analysis...')
    
    // Build context from user history
    const historyContext = userHistory && userHistory.length > 0 
      ? `Previous check-ins for context:\n${userHistory.map((entry: any, idx: number) => 
          `${idx + 1}. Happy: "${entry.happyThing}" | Improve: "${entry.improveThing}"`
        ).join('\n')}\n\n`
      : 'This appears to be a new user with no previous check-ins.\n\n'

    // Call OpenAI API
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
            content: `You are an intelligent personal companion that analyzes daily check-ins to provide insights and ask thoughtful follow-up questions.

Your job is to:
1. Analyze the user's happiness and improvement responses
2. Look for patterns in their history (if available)
3. Generate a thoughtful, personalized follow-up question for tomorrow
4. Identify any behavioral patterns or themes
5. Provide gentle encouragement and insights

Guidelines for follow-up questions:
- Week 1 users: Ask simple, encouraging questions about their responses
- Week 2-4 users: Start connecting dots between entries
- Month+ users: Ask deeper questions about patterns and insights
- Make questions personal and specific to their responses
- Keep questions positive and forward-looking
- Avoid being pushy or clinical

Response format (JSON):
{
  "aiResponse": "A warm, thoughtful follow-up question for tomorrow",
  "insights": [
    {
      "type": "pattern|encouragement|suggestion|milestone",
      "title": "Brief insight title",
      "description": "Encouraging description of what you noticed",
      "confidence": 0.0-1.0
    }
  ],
  "themes": {
    "happiness": ["theme1", "theme2"],
    "improvement": ["theme1", "theme2"]
  },
  "engagementLevel": "new|developing|engaged|dedicated"
}`
          },
          {
            role: 'user',
            content: `${historyContext}Today's check-in:
Happy thing: "${happyThing}"
Thing to improve: "${improveThing}"

Please analyze this check-in and provide insights with a thoughtful follow-up question.`
          }
        ],
        temperature: 0.8,
        max_tokens: 800
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

    console.log('🔍 Parsing AI analysis...')
    let parsedResponse
    try {
      parsedResponse = JSON.parse(aiContent)
    } catch (parseError) {
      console.error('❌ Failed to parse AI response as JSON:', parseError)
      console.error('❌ AI content:', aiContent)
      
      // Fallback to simple response if JSON parsing fails
      parsedResponse = {
        aiResponse: "Thanks for sharing! How did today's experience make you feel?",
        insights: [{
          type: "encouragement",
          title: "Keep reflecting",
          description: "Daily check-ins help build self-awareness.",
          confidence: 0.8
        }],
        themes: {
          happiness: [],
          improvement: []
        },
        engagementLevel: "developing"
      }
    }

    console.log('✅ Successfully processed check-in')
    console.log('💭 AI question:', parsedResponse.aiResponse?.substring(0, 50) + '...')
    console.log('🔍 Insights found:', parsedResponse.insights?.length || 0)

    return new Response(JSON.stringify(parsedResponse), {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'application/json' 
      },
    })

  } catch (error) {
    console.error('💥 Check-in processing error:', error)
    
    // Return a simple fallback response
    const fallbackResponse = {
      aiResponse: "Thank you for checking in today! What's one small thing you're looking forward to tomorrow?",
      insights: [{
        type: "encouragement",
        title: "Building healthy habits",
        description: "Regular reflection is a powerful tool for personal growth.",
        confidence: 0.7
      }],
      themes: {
        happiness: [],
        improvement: []
      },
      engagementLevel: "developing"
    }
    
    return new Response(JSON.stringify(fallbackResponse), {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'application/json' 
      },
    })
  }
}) 