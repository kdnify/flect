import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  console.log('🚀 Function started, method:', req.method)
  
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    console.log('✅ CORS preflight handled')
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📖 Parsing request body...')
    // Parse request body
    const { originalText } = await req.json()
    console.log('📝 Original text received:', originalText?.substring(0, 100) + '...')
    
    if (!originalText) {
      throw new Error('No original text provided')
    }

    console.log('🤖 Calling OpenAI API...')
    
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
            content: `You are an AI assistant that extracts actionable tasks from brain dump text. 
            
            Your job is to:
            1. Read the user's brain dump text
            2. Extract specific, actionable tasks 
            3. Improve and clarify task descriptions to be concrete and actionable
            4. Assign appropriate priority levels (high, medium, low)
            5. Extract and parse due dates from natural language (tomorrow, next week, Friday, etc.)
            6. Return the results in the exact JSON format specified
            
            Guidelines:
            - Extract only clear, actionable tasks (not general thoughts or observations)
            - Make task titles concise but descriptive (max 50 characters)
            - Make descriptions specific and actionable (what exactly needs to be done)
            - Assign priority based on urgency and importance mentioned in the text
            - Use present tense for task titles ("Walk the dog", not "Walking the dog")
            - Parse natural language dates: "tomorrow", "next week", "Friday", "in 3 days", "by Monday", "end of month"
            - Convert dates to ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ) using current date as reference
            - If no specific date mentioned, leave due_date as null
            - Consider today as ${new Date().toISOString().split('T')[0]}
            
            Return response in this exact JSON format:
            {
              "id": "generated-id",
              "title": "Enhanced title for the brain dump", 
              "tasks": [
                {
                  "id": "task-1",
                  "title": "Concise task title",
                  "description": "Detailed, actionable description of what needs to be done",
                  "priority": "high|medium|low",
                  "is_completed": false,
                  "due_date": "2024-01-15T00:00:00Z or null if no date mentioned"
                }
              ]
            }`
          },
          {
            role: 'user',
            content: `Extract actionable tasks from this brain dump: "${originalText}"`
          }
        ],
        temperature: 0.7,
        max_tokens: 1000
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
    
    // Extract the content from OpenAI response
    const aiContent = openaiData.choices[0]?.message?.content
    if (!aiContent) {
      throw new Error('No content in OpenAI response')
    }

    console.log('🔍 Parsing AI response...')
    let parsedResponse
    try {
      parsedResponse = JSON.parse(aiContent)
    } catch (parseError) {
      console.error('❌ Failed to parse AI response as JSON:', parseError)
      console.error('❌ AI content:', aiContent)
      throw new Error('Invalid JSON response from AI')
    }

    console.log('✅ Successfully processed brain dump')
    console.log('📊 Extracted tasks:', parsedResponse.tasks?.length || 0)

    // Return the parsed response directly (not wrapped in another object)
    return new Response(JSON.stringify(parsedResponse), {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'application/json' 
      },
    })

  } catch (error) {
    console.error('💥 Function error:', error)
    
    // Return a fallback response in case of errors
    const fallbackResponse = {
      id: `fallback-${Date.now()}`,
      title: "Brain Dump Entry",
      tasks: [] // Empty tasks array on error
    }
    
    return new Response(JSON.stringify(fallbackResponse), {
      headers: { 
        ...corsHeaders, 
        'Content-Type': 'application/json' 
      },
    })
  }
}) 