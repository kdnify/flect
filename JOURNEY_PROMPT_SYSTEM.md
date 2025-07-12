# Journey-Based Prompt Switching System

## 🎯 Overview

The Flect app now features a sophisticated journey-based prompt switching system that tailors AI coach responses based on the user's journey stage, check-in count, and engagement level.

## 🚀 Features Implemented

### 1. User Journey Tracking
- **Journey Start Date**: Automatically set when onboarding is completed
- **Total Check-ins**: Tracks cumulative check-ins
- **Consecutive Days**: Tracks daily streaks
- **Journey Day**: Calculates current day in journey
- **Journey Stage**: Categorizes user into engagement levels

### 2. Journey Stages
- **Onboarding** (Days 1-3): New users getting comfortable
- **First Week** (Days 4-7): Building momentum and habits
- **Second Week** (Days 8-14): Developing deeper patterns
- **First Month** (Days 15-30): Sustainable practice development
- **Consistent** (7+ day streaks): Strong habit formation
- **Engaged** (10+ total check-ins): Deep engagement
- **Casual** (Flexible usage): Occasional users

### 3. Day-Specific Prompts (First 7 Days)
Each day has a carefully crafted prompt that:
- **Day 1**: Welcoming, simple questions, building confidence
- **Day 2**: Celebrating return, encouraging consistency
- **Day 3**: Celebrating 3-day streak, connecting patterns
- **Day 4**: Acknowledging commitment, pattern recognition
- **Day 5**: Celebrating dedication, deeper self-awareness
- **Day 6**: Preparing for weekly review, building excitement
- **Day 7**: Celebrating first week, weekly reflection

### 4. Milestone Recognition
- **Weekly Streaks**: Every 7 consecutive days
- **Total Check-ins**: 10, 25, 50, 100 check-ins
- **Special Celebrations**: Milestone-specific prompts

## 🔧 Technical Implementation

### Frontend (iOS)
```swift
// UserPreferencesService.swift
@Published var journeyStartDate: Date?
@Published var totalCheckIns: Int
@Published var consecutiveCheckInDays: Int
@Published var lastCheckInDate: Date?

// Journey tracking methods
func startJourney()
func recordCheckIn()
var journeyDay: Int
var journeyStage: JourneyStage
```

### Backend (Supabase Edge Function)
```typescript
// process-check-in/index.ts
function getJourneyBasedPrompt(
  journeyDay: number, 
  journeyStage: string, 
  totalCheckIns: number, 
  consecutiveCheckInDays: number
): string
```

### Data Flow
1. User completes onboarding → `startJourney()` called
2. User submits check-in → `recordCheckIn()` called
3. Journey data sent to backend with check-in
4. Backend selects appropriate prompt based on journey stage
5. AI generates personalized response using journey-specific prompt

## 📊 Prompt Selection Logic

### Priority Order:
1. **Milestone Prompts** (highest priority)
   - Weekly streaks (7, 14, 21, etc. consecutive days)
   - Total check-in milestones (10, 25, 50, 100)
2. **Day-Specific Prompts** (days 1-7)
3. **Stage-Based Prompts** (ongoing users)
4. **Default Prompt** (fallback)

### Prompt Characteristics by Stage:

#### Onboarding (Days 1-3)
- **Tone**: Warm, welcoming, encouraging
- **Questions**: Simple, curiosity-driven
- **Focus**: Building confidence, explaining value
- **Avoid**: Complex analysis, overwhelming insights

#### First Week (Days 4-7)
- **Tone**: Encouraging, supportive, celebratory
- **Questions**: Pattern recognition, consistency
- **Focus**: Habit formation, momentum building
- **Avoid**: Too much pressure, complexity

#### Second Week+
- **Tone**: Insightful, encouraging, proud
- **Questions**: Deeper reflection, pattern analysis
- **Focus**: Self-discovery, sustainable practice
- **Avoid**: Oversimplifying, being too casual

#### Consistent Users
- **Tone**: Sophisticated, supportive, insightful
- **Questions**: Advanced reflection, deep analysis
- **Focus**: Continued growth, expertise building
- **Avoid**: Being too casual, oversimplifying

## 🧪 Testing

A comprehensive test script (`test_journey_prompts.sh`) validates:
- Day 1 new user experience
- Day 3 habit building
- Day 7 first week completion
- Week 2 consistent usage
- Milestone celebrations

## 🎯 Benefits

### For Users:
- **Personalized Experience**: AI responses match their journey stage
- **Progressive Engagement**: Complexity increases with experience
- **Milestone Recognition**: Celebrations for achievements
- **Consistent Motivation**: Appropriate encouragement at each stage

### For App:
- **Higher Retention**: Personalized experience increases engagement
- **Better Onboarding**: New users get appropriate guidance
- **Scalable System**: Easy to add new stages and prompts
- **Data-Driven**: Journey tracking provides valuable insights

## 🔮 Future Enhancements

### Potential Additions:
1. **Personality-Based Prompts**: Combine journey stage with personality type
2. **Goal-Specific Prompts**: Tailor to user's selected wellness goals
3. **Seasonal Prompts**: Special prompts for holidays, seasons
4. **Mood-Based Prompts**: Adjust tone based on recent mood trends
5. **Activity Prompts**: Reference specific activities or habits

### Advanced Features:
1. **A/B Testing**: Test different prompts for each stage
2. **Dynamic Prompts**: Generate prompts based on real-time data
3. **User Feedback**: Allow users to rate prompt effectiveness
4. **Machine Learning**: Optimize prompts based on user engagement

## 📝 Usage Examples

### Day 1 Response:
> "I'm glad to hear that you had a great conversation with your friend! How do you feel these social interactions impact your day? Also, about your desire to exercise more regularly, what kind of exercise routine are you envisioning?"

### Day 7 Response:
> "Fantastic work on your 7-day streak! What will you do to maintain this positive momentum?"

### Milestone Response:
> "As you continue on your journey of growth and helping others, can you think of a specific way you'd like to contribute to someone else's journey tomorrow?"

## 🚀 Deployment Status

✅ **Frontend**: Journey tracking implemented and tested
✅ **Backend**: Prompt switching deployed and functional
✅ **Integration**: Data flow working correctly
✅ **Testing**: Comprehensive test suite validated

The system is now live and providing personalized AI coach responses based on each user's unique journey! 