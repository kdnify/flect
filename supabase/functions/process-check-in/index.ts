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
    const { 
      happyThing, 
      improveThing, 
      userHistory,
      energy,
      sleep,
      social,
      highlight,
      wellbeingScore,
      journeyDay,
      journeyStage,
      totalCheckIns,
      consecutiveCheckInDays
    } = await req.json()
    
    console.log('📝 Happy thing:', happyThing?.substring(0, 50) + '...')
    console.log('📝 Improve thing:', improveThing?.substring(0, 50) + '...')
    console.log('📚 User history entries:', userHistory?.length || 0)
    console.log('⚡ Energy:', energy)
    console.log('😴 Sleep:', sleep)
    console.log('👥 Social:', social)
    console.log('✨ Highlight:', highlight)
    console.log('📊 Wellbeing Score:', wellbeingScore)
    console.log('🚀 Journey Day:', journeyDay)
    console.log('🎯 Journey Stage:', journeyStage)
    console.log('📈 Total Check-ins:', totalCheckIns)
    console.log('🔥 Consecutive Days:', consecutiveCheckInDays)
    
    if (!happyThing || !improveThing) {
      throw new Error('Both happyThing and improveThing are required')
    }

    console.log('🤖 Calling OpenAI API for check-in analysis...')
    
    // Build context from user history
    const historyContext = userHistory && userHistory.length > 0 
      ? `Previous check-ins for context:\n${userHistory.map((entry: any, idx: number) => 
          `${idx + 1}. Happy: "${entry.happyThing}" | Improve: "${entry.improveThing}" | Energy: ${entry.energy} | Sleep: ${entry.sleep} | Social: ${entry.social} | Highlight: ${entry.highlight}`
        ).join('\n')}\n\n`
      : 'This appears to be a new user with no previous check-ins.\n\n'

    // Get journey-appropriate system prompt
    const systemPrompt = getJourneyBasedPrompt(journeyDay, journeyStage, totalCheckIns, consecutiveCheckInDays)

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
            content: systemPrompt
          },
          {
            role: 'user',
            content: `${historyContext}Today's check-in:
Happy thing: "${happyThing}"
Thing to improve: "${improveThing}"
Energy Level: ${energy === 0 ? "Low" : energy === 1 ? "Medium" : "High"}
Sleep Quality: ${sleep === 0 ? "Bad" : sleep === 1 ? "Okay" : "Great"}
Social Interaction: ${social === 0 ? "Alone" : social === 1 ? "Some" : "With Others"}
Day's Highlight: "${highlight}"
Wellbeing Score: ${wellbeingScore}

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

// MARK: - Journey-Based Prompt Selection

function getJourneyBasedPrompt(journeyDay: number, journeyStage: string, totalCheckIns: number, consecutiveCheckInDays: number): string {
  const basePrompt = `You are a wise, supportive companion. Your job is to give ONE short, personal response that:

1. References something specific from their check-in (their happy thing, improve thing, or highlight)
2. Connects to their goals if mentioned
3. Asks ONE thoughtful question that encourages action
4. Keeps it under 2 sentences total

IMPORTANT: 
- Be specific to what they actually wrote
- Don't be generic or fake
- Make it feel like you actually read their entry
- Ask about something they mentioned wanting to improve
- Keep it short and actionable

Response format (JSON):
{
  "aiResponse": "One short, specific response with a call to action",
  "insights": [
    {
      "type": "pattern|encouragement|suggestion|milestone",
      "title": "Brief insight title", 
      "description": "Short encouraging note",
      "confidence": 0.0-1.0
    }
  ],
  "themes": {
    "happiness": ["theme1", "theme2"],
    "improvement": ["theme1", "theme2"],
    "wellbeing": ["theme1", "theme2"]
  },
  "engagementLevel": "new|developing|engaged|dedicated"
}`

  // Day-specific prompts for the first 7 days
  const daySpecificPrompts: { [key: number]: string } = {
    1: `Welcome! This is their first check-in. Be warm and specific about what they shared. Ask about their improvement goal.

${basePrompt}`,

    2: `Day 2! Reference something from their entry and ask about their improvement area.

${basePrompt}`,

    3: `Day 3! They're building momentum. Connect to their content and ask about progress on their goal.

${basePrompt}`,

    4: `Day 4! They're showing commitment. Be specific about their entry and encourage their improvement area.

${basePrompt}`,

    5: `Day 5! Almost a week. Reference their highlight and ask about their improvement goal.

${basePrompt}`,

    6: `Day 6! Building something special. Connect to their content and ask about their improvement area.

${basePrompt}`,

    7: `Day 7! First week complete! Celebrate briefly, then ask about their improvement goal.

${basePrompt}`
  }

  // Stage-based prompts for ongoing users
  const stageBasedPrompts: { [key: string]: string } = {
    'first_week': `First week user. Be specific about their content and ask about their improvement goal.

${basePrompt}`,

    'second_week': `Second week! Reference their entry and ask about progress on their improvement area.

${basePrompt}`,

    'first_month': `Approaching a month! Connect to their content and encourage their improvement goal.

${basePrompt}`,

    'consistent': `Consistent user. Be specific about their entry and ask about their improvement area.

${basePrompt}`,

    'engaged': `Engaged user. Reference their content and ask about their improvement goal.

${basePrompt}`,

    'casual': `Casual user. Be specific about their entry and ask about their improvement area.

${basePrompt}`
  }

  // Special prompts for milestones
  if (consecutiveCheckInDays >= 7 && consecutiveCheckInDays % 7 === 0) {
    return `🎉 ${consecutiveCheckInDays} day streak! Celebrate briefly, then ask about their improvement goal.

${basePrompt}`
  }

  if (totalCheckIns === 10 || totalCheckIns === 25 || totalCheckIns === 50 || totalCheckIns === 100) {
    return `🏆 ${totalCheckIns} check-ins! Celebrate briefly, then ask about their improvement goal.

${basePrompt}`
  }

  // Return day-specific prompt if available
  if (daySpecificPrompts[journeyDay]) {
    return daySpecificPrompts[journeyDay]
  }

  // Return stage-based prompt if available
  if (stageBasedPrompts[journeyStage]) {
    return stageBasedPrompts[journeyStage]
  }

  // Default prompt
  return basePrompt
}