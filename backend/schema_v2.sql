-- Flect Database Schema v2.0 - Progressive Intelligence Update
-- Run this in your Supabase SQL editor to add new check-in and insights system

-- ============================================================================
-- DAILY CHECK-INS TABLE
-- ============================================================================

CREATE TABLE daily_check_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Core check-in data
  check_in_date DATE NOT NULL DEFAULT CURRENT_DATE,
  happy_thing TEXT NOT NULL,
  improve_thing TEXT NOT NULL,
  mood_emoji VARCHAR(10) NOT NULL DEFAULT '😌',
  
  -- AI interaction
  completion_state VARCHAR(30) DEFAULT 'completed',
  ai_response TEXT,
  ai_question_asked TEXT,
  follow_up_completed BOOLEAN DEFAULT FALSE,
  
  -- Engagement tracking
  days_since_creation INTEGER DEFAULT 0,
  
  -- Ensure one check-in per day (future: per user)
  UNIQUE(check_in_date)
);

-- ============================================================================
-- USER INSIGHTS TABLE
-- ============================================================================

CREATE TABLE user_insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Insight content
  insight_type VARCHAR(20) NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  
  -- Confidence and validity
  confidence DECIMAL(3,2) NOT NULL DEFAULT 0.5, -- 0.00 to 1.00
  data_points INTEGER NOT NULL DEFAULT 1,
  valid_until TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Metadata
  related_check_in_ids UUID[] DEFAULT '{}',
  keywords TEXT[] DEFAULT '{}',
  frequency_data JSONB DEFAULT '{}',
  
  CHECK (confidence >= 0.0 AND confidence <= 1.0),
  CHECK (insight_type IN ('pattern', 'correlation', 'prediction', 'suggestion', 'milestone', 'streak'))
);

-- ============================================================================
-- USER ENGAGEMENT TRACKING
-- ============================================================================

CREATE TABLE user_engagement (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Engagement metrics
  total_check_ins INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  days_since_install INTEGER DEFAULT 0,
  average_check_ins_per_week DECIMAL(5,2) DEFAULT 0.0,
  
  -- Tier and permissions
  engagement_tier INTEGER DEFAULT 0, -- 0=newcomer, 1=exploring, 2=engaged, 3=committed
  should_get_smart_questions BOOLEAN DEFAULT FALSE,
  should_get_deep_insights BOOLEAN DEFAULT FALSE,
  
  -- Single row for now (future: per user)
  CONSTRAINT single_engagement_row CHECK (id = id)
);

-- ============================================================================
-- PATTERN ANALYSIS CACHE
-- ============================================================================

CREATE TABLE pattern_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Analysis metadata
  analysis_type VARCHAR(30) NOT NULL,
  date_range_start DATE NOT NULL,
  date_range_end DATE NOT NULL,
  
  -- Analysis results
  happiness_keywords JSONB DEFAULT '{}',
  improvement_keywords JSONB DEFAULT '{}',
  mood_patterns JSONB DEFAULT '{}',
  correlation_data JSONB DEFAULT '{}',
  
  -- Performance
  check_in_count INTEGER NOT NULL,
  analysis_confidence DECIMAL(3,2) DEFAULT 0.5,
  
  CHECK (analysis_type IN ('weekly', 'monthly', 'quarterly', 'yearly'))
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Daily check-ins indexes
CREATE INDEX idx_daily_check_ins_date ON daily_check_ins(check_in_date DESC);
CREATE INDEX idx_daily_check_ins_state ON daily_check_ins(completion_state);
CREATE INDEX idx_daily_check_ins_ai_response ON daily_check_ins(ai_response) WHERE ai_response IS NOT NULL;

-- User insights indexes
CREATE INDEX idx_user_insights_type ON user_insights(insight_type);
CREATE INDEX idx_user_insights_active ON user_insights(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_user_insights_confidence ON user_insights(confidence DESC);
CREATE INDEX idx_user_insights_valid ON user_insights(valid_until) WHERE valid_until IS NOT NULL;

-- Pattern analysis indexes
CREATE INDEX idx_pattern_analysis_type ON pattern_analysis(analysis_type);
CREATE INDEX idx_pattern_analysis_date ON pattern_analysis(date_range_end DESC);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Auto-update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply auto-update triggers
CREATE TRIGGER update_daily_check_ins_updated_at 
    BEFORE UPDATE ON daily_check_ins 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_insights_updated_at 
    BEFORE UPDATE ON user_insights 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_engagement_updated_at 
    BEFORE UPDATE ON user_engagement 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pattern_analysis_updated_at 
    BEFORE UPDATE ON pattern_analysis 
    FOR EACH ROW EXECUTE FUNCTION update_pattern_analysis_updated_at_column();

-- ============================================================================
-- REAL-TIME SUBSCRIPTIONS
-- ============================================================================

-- Enable real-time for check-ins and insights
ALTER PUBLICATION supabase_realtime ADD TABLE daily_check_ins;
ALTER PUBLICATION supabase_realtime ADD TABLE user_insights;
ALTER PUBLICATION supabase_realtime ADD TABLE user_engagement;

-- ============================================================================
-- SAMPLE DATA FOR TESTING
-- ============================================================================

-- Insert initial user engagement row
INSERT INTO user_engagement (
    total_check_ins,
    current_streak,
    longest_streak,
    days_since_install,
    engagement_tier,
    should_get_smart_questions,
    should_get_deep_insights
) VALUES (
    0, 0, 0, 0, 0, FALSE, FALSE
);

-- Sample check-ins for testing
INSERT INTO daily_check_ins (check_in_date, happy_thing, improve_thing, mood_emoji, completion_state) VALUES
(CURRENT_DATE - INTERVAL '2 days', 'Had amazing coffee with Sarah', 'Get more sleep and exercise', '😊', 'completed'),
(CURRENT_DATE - INTERVAL '1 day', 'Finished the big work presentation', 'Organize my desk and workspace', '🤔', 'follow_up_pending');

-- Sample insights for testing
INSERT INTO user_insights (insight_type, title, description, confidence, data_points) VALUES
('pattern', 'You''re happiest about social connections', 'Coffee with friends appears in 60% of your happy moments', 0.85, 5),
('suggestion', 'Sleep seems to be a recurring focus', 'You''ve mentioned sleep improvement 3 times this week', 0.72, 3),
('streak', '2 day check-in streak! 🔥', 'You''re building consistency with daily reflection', 1.0, 2);

-- ============================================================================
-- CLEANUP FUNCTIONS (FOR DEVELOPMENT)
-- ============================================================================

-- Function to reset all check-in data (development only)
CREATE OR REPLACE FUNCTION reset_checkin_system()
RETURNS VOID AS $$
BEGIN
    DELETE FROM pattern_analysis;
    DELETE FROM user_insights;
    DELETE FROM daily_check_ins;
    UPDATE user_engagement SET 
        total_check_ins = 0,
        current_streak = 0,
        longest_streak = 0,
        days_since_install = 0,
        engagement_tier = 0,
        should_get_smart_questions = FALSE,
        should_get_deep_insights = FALSE;
END;
$$ LANGUAGE plpgsql;

-- Note: Original journal_entries and tasks tables remain unchanged
-- This allows both systems to coexist during the transition 