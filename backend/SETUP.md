# Flect Backend Setup Guide

## 🚀 Quick Setup Steps

### 1. Database Setup
1. Go to your Supabase project: https://rinjdpgdcdmtmadabqdf.supabase.co
2. Navigate to **SQL Editor**
3. Copy and paste the entire contents of `schema.sql`
4. Click **Run** to create the tables

### 2. Get Your Service Role Key
1. In Supabase, go to **Settings** → **API**
2. Copy the **service_role** key (not the anon key)
3. You'll need this for the Edge Function

### 3. Deploy Edge Function
```bash
# Install Supabase CLI if you haven't
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref rinjdpgdcdmtmadabqdf

# Set environment variables for the function
supabase secrets set OPENAI_API_KEY=your-openai-key-here

# Deploy the function
supabase functions deploy process-brain-dump
```

### 4. Get Your OpenAI API Key
1. Go to https://platform.openai.com/api-keys
2. Create a new API key
3. Set it as a secret in Supabase (step 3 above)

### 5. Test the Setup
Once deployed, your Edge Function will be available at:
```
https://rinjdpgdcdmtmadabqdf.supabase.co/functions/v1/process-brain-dump
```

Test it with:
```bash
curl -X POST 'https://rinjdpgdcdmtmadabqdf.supabase.co/functions/v1/process-brain-dump' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"originalText": "Had a stressful day at work. Need to finish the report and call mom."}'
```

## 🔧 Environment Variables Needed

### For Edge Function (set via `supabase secrets set`):
- `OPENAI_API_KEY` - Your OpenAI API key

### For iOS App:
- `SUPABASE_URL` - https://rinjdpgdcdmtmadabqdf.supabase.co
- `SUPABASE_ANON_KEY` - Your anon public key

## 📱 Next: Update iOS App

Once the backend is set up, we'll:
1. Add Supabase iOS SDK to the Xcode project
2. Update `StorageService.swift` to use Supabase API
3. Update `AIService.swift` to call the Edge Function
4. Add real-time processing status updates

## 🐛 Troubleshooting

**Edge Function not deploying?**
- Make sure you're logged into Supabase CLI
- Check that your project is linked correctly
- Verify your OpenAI API key is set as a secret

**Database errors?**
- Check that the schema.sql ran successfully
- Verify table permissions in Supabase dashboard
- Make sure real-time is enabled for the tables

**OpenAI API errors?**
- Verify your API key is valid and has credits
- Check the API key is set correctly as a secret
- Monitor usage in OpenAI dashboard 