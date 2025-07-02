-- Flect Database Schema
-- Run this in your Supabase SQL editor

-- Journal entries table
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

-- Tasks table
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id UUID REFERENCES journal_entries(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT FALSE,
  priority VARCHAR(10) DEFAULT 'medium'
);

-- Enable real-time subscriptions for both tables
ALTER PUBLICATION supabase_realtime ADD TABLE journal_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;

-- Create indexes for better performance
CREATE INDEX idx_journal_entries_created_at ON journal_entries(created_at DESC);
CREATE INDEX idx_journal_entries_status ON journal_entries(processing_status);
CREATE INDEX idx_tasks_journal_entry_id ON tasks(journal_entry_id);
CREATE INDEX idx_tasks_completed ON tasks(is_completed);

-- Sample data for testing (optional)
INSERT INTO journal_entries (original_text, processed_content, title, mood, processing_status) VALUES
(
  'Had a really stressful day at work today. Need to finish the presentation by tomorrow and also remember to call mom.',
  'Today was challenging at work with tight deadlines creating stress. The upcoming presentation deadline is weighing on my mind, but I''m managing the pressure. It''s also important to maintain personal connections during busy times.',
  'Stressful Work Day and Personal Reminders',
  'stressed',
  'completed'
);

INSERT INTO tasks (journal_entry_id, title, description, priority) VALUES
(
  (SELECT id FROM journal_entries LIMIT 1),
  'Finish presentation',
  'Complete the work presentation due tomorrow',
  'high'
),
(
  (SELECT id FROM journal_entries LIMIT 1),
  'Call mom',
  'Remember to call mom and catch up',
  'medium'
); 