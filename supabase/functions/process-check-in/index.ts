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
  const basePrompt = `You are an intelligent personal companion that analyzes daily check-ins to provide insights and ask thoughtful follow-up questions.

Your job is to:
1. Analyze the user's complete check-in data (mood, energy, sleep, social, highlight)
2. Look for patterns in their history (if available)
3. Generate a thoughtful, personalized follow-up question for tomorrow
4. Identify any behavioral patterns or themes
5. Provide gentle encouragement and insights
6. Consider wellbeing score trends

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
    "improvement": ["theme1", "theme2"],
    "wellbeing": ["theme1", "theme2"]
  },
  "engagementLevel": "new|developing|engaged|dedicated"
}`

  // Day-specific prompts for the first 7 days
  const daySpecificPrompts: { [key: number]: string } = {
    1: `You are welcoming a brand new user to their reflection journey. This is their very first check-in!

Focus on:
- Making them feel welcome and comfortable
- Explaining the value of daily reflection
- Asking simple, encouraging questions
- Building confidence in the process

Tone: Warm, welcoming, encouraging
Question style: Simple, curiosity-driven
Avoid: Complex analysis, overwhelming insights

${basePrompt}`,

    2: `This is day 2 of their journey! They're building momentum.

Focus on:
- Celebrating their return
- Noticing any patterns from their first two entries
- Encouraging consistency
- Making reflection feel natural

Tone: Encouraging, supportive
Question style: Building on yesterday's response
Avoid: Too much analysis, pressure

${basePrompt}`,

    3: `Day 3! They're developing a habit. This is a crucial momentum-building day.

Focus on:
- Celebrating the 3-day streak
- Connecting dots between their entries
- Encouraging deeper reflection
- Building excitement for the journey

Tone: Excited, celebratory
Question style: Connecting patterns
Avoid: Overwhelming complexity

${basePrompt}`,

    4: `Day 4 - They're showing real commitment! Building a sustainable practice.

Focus on:
- Acknowledging their growing consistency
- Noticing emerging patterns
- Encouraging self-discovery
- Preparing them for deeper insights

Tone: Proud, insightful
Question style: Pattern recognition
Avoid: Too much pressure

${basePrompt}`,

    5: `Day 5! They're approaching a full week. This is habit formation territory.

Focus on:
- Celebrating their dedication
- Highlighting their progress
- Encouraging deeper self-awareness
- Building anticipation for weekly insights

Tone: Proud, anticipatory
Question style: Deeper reflection
Avoid: Overwhelming expectations

${basePrompt}`,

    6: `Day 6 - Almost a full week! They're building something special.

Focus on:
- Preparing them for their first weekly review
- Celebrating their consistency
- Encouraging reflection on the week
- Building excitement for insights

Tone: Excited, reflective
Question style: Weekly perspective
Avoid: Too much focus on the future

${basePrompt}`,

    7: `Day 7! Their first full week complete! This is a major milestone.

Focus on:
- Celebrating their first week achievement
- Encouraging reflection on their journey so far
- Preparing them for deeper insights
- Building excitement for continued growth

Tone: Celebratory, proud
Question style: Weekly reflection
Avoid: Overwhelming with too much analysis

${basePrompt}`
  }

  // Stage-based prompts for ongoing users
  const stageBasedPrompts: { [key: string]: string } = {
    'first_week': `They're in their first week of consistent use. Building foundation and momentum.

Focus on:
- Encouraging daily habit formation
- Simple pattern recognition
- Building confidence in the process
- Making reflection feel rewarding

Tone: Supportive, encouraging
Question style: Simple but engaging
Avoid: Complex analysis

${basePrompt}`,

    'second_week': `They're in their second week! Developing deeper patterns and insights.

Focus on:
- Connecting dots between entries
- Encouraging deeper self-awareness
- Building on established patterns
- Preparing for more sophisticated insights

Tone: Insightful, encouraging
Question style: Pattern-based questions
Avoid: Overwhelming complexity

${basePrompt}`,

    'first_month': `They're approaching a month! Developing a sustainable practice.

Focus on:
- Celebrating their consistency
- Deeper pattern analysis
- Encouraging self-discovery
- Building long-term engagement

Tone: Proud, insightful
Question style: Deeper reflection
Avoid: Too much pressure

${basePrompt}`,

    'consistent': `They're a consistent user with a strong habit! Deep engagement.

Focus on:
- Sophisticated pattern analysis
- Encouraging deeper insights
- Building on their established practice
- Supporting continued growth

Tone: Insightful, supportive
Question style: Deep, reflective
Avoid: Being too casual

${basePrompt}`,

    'engaged': `They're deeply engaged with their growth journey.

Focus on:
- Advanced insights and analysis
- Encouraging deeper self-discovery
- Supporting their continued evolution
- Building on their expertise

Tone: Sophisticated, supportive
Question style: Advanced reflection
Avoid: Oversimplifying

${basePrompt}`,

    'casual': `They're using the app casually, checking in when they feel like it.

Focus on:
- Making each check-in valuable
- Encouraging more consistent use
- Building engagement without pressure
- Supporting their flexible approach

Tone: Welcoming, supportive
Question style: Engaging but not overwhelming
Avoid: Too much pressure to be consistent

${basePrompt}`
  }

  // Special prompts for milestones
  if (consecutiveCheckInDays >= 7 && consecutiveCheckInDays % 7 === 0) {
    return `🎉 WEEKLY STREAK MILESTONE! They've completed ${consecutiveCheckInDays} consecutive days!

Focus on:
- Celebrating their incredible consistency
- Acknowledging their dedication
- Encouraging reflection on their weekly journey
- Building excitement for continued growth

Tone: Celebratory, proud, excited
Question style: Weekly reflection and celebration
Special: Include a milestone celebration in insights

${basePrompt}`
  }

  if (totalCheckIns === 10 || totalCheckIns === 25 || totalCheckIns === 50 || totalCheckIns === 100) {
    return `🏆 MILESTONE ACHIEVEMENT! They've completed ${totalCheckIns} total check-ins!

Focus on:
- Celebrating their milestone achievement
- Acknowledging their commitment to growth
- Encouraging reflection on their journey
- Building excitement for future milestones

Tone: Celebratory, proud, inspiring
Question style: Milestone reflection
Special: Include a milestone celebration in insights

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