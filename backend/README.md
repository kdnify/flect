# Flect Backend - Supabase + AI Integration

**Phase 1: AI-First Backend (v0.2)**

## 🎯 Goals
- Replace mock AI with real AI processing
- Replace local storage with Supabase database
- Keep it simple - no users yet, just AI functionality

## 🏗️ Architecture

```
Supabase Stack:
├── Database (PostgreSQL)
│   ├── journal_entries table
│   ├── tasks table
│   └── processing_status table
├── Edge Functions
│   ├── process-brain-dump (AI processing)
│   ├── extract-tasks (Task extraction)
│   └── analyze-sentiment (Future)
└── Real-time (WebSocket)
    └── AI processing status updates
```

## 📊 Database Schema

### journal_entries
```sql
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  original_text TEXT NOT NULL,
  processed_content TEXT,
  title TEXT,
  mood VARCHAR(50),
  processing_status VARCHAR(20) DEFAULT 'pending'
);
```

### tasks
```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id UUID REFERENCES journal_entries(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  priority VARCHAR(10) DEFAULT 'medium'
);
```

## 🤖 AI Integration Plan

### Edge Function: process-brain-dump
```typescript
// Input: { originalText: string }
// Output: { title, processedContent, mood, tasks[] }

1. Send to OpenAI/Claude for processing
2. Extract structured content
3. Identify tasks
4. Analyze mood/sentiment
5. Update database
6. Trigger real-time update
```

## 🔄 iOS Integration Points

### Replace in StorageService.swift:
- `saveJournalEntry()` → Supabase API call
- `loadJournalEntries()` → Supabase query
- Add real-time subscription for processing status

### Replace in AIService.swift:
- `processText()` → Call Supabase Edge Function
- Add processing status tracking
- Real-time updates during AI processing

## 🚀 Setup Steps

1. **Create Supabase Project**
2. **Set up database schema**
3. **Create Edge Functions**
4. **Update iOS app to use Supabase**
5. **Add AI API keys**
6. **Test end-to-end flow**

## 🔑 Environment Variables

```bash
SUPABASE_URL=your-project-url
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-key
OPENAI_API_KEY=your-openai-key
# OR
ANTHROPIC_API_KEY=your-claude-key
```

## 📱 iOS Changes Needed

- Add Supabase iOS SDK
- Update StorageService to use REST API
- Update AIService to call Edge Functions
- Add real-time processing status
- Handle network errors gracefully

---

**Next Phase (v0.3)**: Add user authentication and multi-user support 