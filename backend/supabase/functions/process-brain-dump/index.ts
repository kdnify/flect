import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parse request body
    const { originalText } = await req.json()
    
    if (!originalText || originalText.trim().length === 0) {
      throw new Error('Original text is required')
    }

    // Create initial journal entry with pending status
    const { data: journalEntry, error: insertError } = await supabaseClient
      .from('journal_entries')
      .insert({
        original_text: originalText,
        processing_status: 'processing'
      })
      .select()
      .single()

    if (insertError) {
      throw new Error(`Failed to create journal entry: ${insertError.message}`)
    }

    // Process with OpenAI
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
            content: `You are an AI assistant that helps process unstructured journal entries. 
            
            Your task is to:
            1. Transform the raw text into a well-structured, coherent journal entry
            2. Create an appropriate title (max 60 characters)
            3. Analyze the overall mood/emotion (one word: happy, sad, stressed, excited, neutral, anxious, grateful, frustrated, etc.)
            4. Extract any actionable tasks mentioned in the text
            
            Return your response as a JSON object with this exact structure:
            {
              "title": "Brief descriptive title",
              "processedContent": "Well-structured journal entry that maintains the original meaning but improves clarity and flow",
              "mood": "single_word_mood",
              "tasks": [
                {
                  "title": "Task title",
                  "description": "Brief task description",
                  "priority": "high|medium|low"
                }
              ]
            }
            
            Make the processed content feel natural and personal, not robotic. Keep the original voice and emotions.`
          },
          {
            role: 'user',
            content: originalText
          }
        ],
        temperature: 0.7,
        max_tokens: 1000
      })
    })

    if (!openaiResponse.ok) {
      throw new Error(`OpenAI API error: ${openaiResponse.status}`)
    }

    const openaiData = await openaiResponse.json()
    const aiResponse = JSON.parse(openaiData.choices[0].message.content)

    // Update journal entry with processed content
    const { error: updateError } = await supabaseClient
      .from('journal_entries')
      .update({
        processed_content: aiResponse.processedContent,
        title: aiResponse.title,
        mood: aiResponse.mood,
        processing_status: 'completed',
        updated_at: new Date().toISOString()
      })
      .eq('id', journalEntry.id)

    if (updateError) {
      throw new Error(`Failed to update journal entry: ${updateError.message}`)
    }

    // Insert extracted tasks
    if (aiResponse.tasks && aiResponse.tasks.length > 0) {
      const tasksToInsert = aiResponse.tasks.map((task: any) => ({
        journal_entry_id: journalEntry.id,
        title: task.title,
        description: task.description,
        priority: task.priority || 'medium'
      }))

      const { error: tasksError } = await supabaseClient
        .from('tasks')
        .insert(tasksToInsert)

      if (tasksError) {
        console.error('Failed to insert tasks:', tasksError)
        // Don't throw here - journal entry is more important than tasks
      }
    }

    // Return the complete processed entry
    const { data: finalEntry, error: fetchError } = await supabaseClient
      .from('journal_entries')
      .select(`
        *,
        tasks (*)
      `)
      .eq('id', journalEntry.id)
      .single()

    if (fetchError) {
      throw new Error(`Failed to fetch final entry: ${fetchError.message}`)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        data: finalEntry 
      }),
      { 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    )

  } catch (error) {
    console.error('Error processing brain dump:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        status: 500,
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    )
  }
}) 