#!/bin/bash

# Test script for journey-based prompt switching
# This script tests the backend with different journey stages

BASE_URL="https://rinjdpgdcdmtmadabqdf.supabase.co/functions/v1/process-check-in"
AUTH_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpbmpkcGdkY2RtdG1hZGFicWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0OTQ5MjcsImV4cCI6MjA2NzA3MDkyN30.vtWSWgvZgU1vIFG-wrAjBOi_jmIElwsttAkUvi1kVBg"

echo "🧪 Testing Journey-Based Prompt Switching"
echo "=========================================="

# Test Day 1 (New User)
echo ""
echo "📅 Testing Day 1 (New User):"
curl -X POST "$BASE_URL" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "happyThing": "Had a great conversation with a friend",
    "improveThing": "Want to exercise more regularly",
    "userHistory": [],
    "journeyDay": 1,
    "journeyStage": "onboarding",
    "totalCheckIns": 1,
    "consecutiveCheckInDays": 1
  }' | jq '.aiResponse' | head -3

# Test Day 3 (Building Habit)
echo ""
echo "📅 Testing Day 3 (Building Habit):"
curl -X POST "$BASE_URL" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "happyThing": "Completed my morning routine",
    "improveThing": "Need to manage stress better",
    "userHistory": [
      {"happyThing": "Had a great conversation with a friend", "improveThing": "Want to exercise more regularly"},
      {"happyThing": "Finished a project at work", "improveThing": "Want to read more books"}
    ],
    "journeyDay": 3,
    "journeyStage": "onboarding",
    "totalCheckIns": 3,
    "consecutiveCheckInDays": 3
  }' | jq '.aiResponse' | head -3

# Test Day 7 (First Week Complete)
echo ""
echo "📅 Testing Day 7 (First Week Complete):"
curl -X POST "$BASE_URL" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "happyThing": "Reflected on my week and feel proud",
    "improveThing": "Want to be more patient with myself",
    "userHistory": [
      {"happyThing": "Had a great conversation with a friend", "improveThing": "Want to exercise more regularly"},
      {"happyThing": "Finished a project at work", "improveThing": "Want to read more books"},
      {"happyThing": "Completed my morning routine", "improveThing": "Need to manage stress better"},
      {"happyThing": "Spent time with family", "improveThing": "Want to learn a new skill"},
      {"happyThing": "Helped a colleague", "improveThing": "Need to prioritize better"},
      {"happyThing": "Had a peaceful evening", "improveThing": "Want to be more organized"}
    ],
    "journeyDay": 7,
    "journeyStage": "onboarding",
    "totalCheckIns": 7,
    "consecutiveCheckInDays": 7
  }' | jq '.aiResponse' | head -3

# Test Consistent User (Week 2)
echo ""
echo "📅 Testing Consistent User (Week 2):"
curl -X POST "$BASE_URL" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "happyThing": "Noticed patterns in my mood and energy",
    "improveThing": "Want to develop better coping strategies",
    "userHistory": [
      {"happyThing": "Had a great conversation with a friend", "improveThing": "Want to exercise more regularly"},
      {"happyThing": "Finished a project at work", "improveThing": "Want to read more books"},
      {"happyThing": "Completed my morning routine", "improveThing": "Need to manage stress better"},
      {"happyThing": "Spent time with family", "improveThing": "Want to learn a new skill"},
      {"happyThing": "Helped a colleague", "improveThing": "Need to prioritize better"},
      {"happyThing": "Had a peaceful evening", "improveThing": "Want to be more organized"},
      {"happyThing": "Reflected on my week and feel proud", "improveThing": "Want to be more patient with myself"}
    ],
    "journeyDay": 14,
    "journeyStage": "second_week",
    "totalCheckIns": 14,
    "consecutiveCheckInDays": 14
  }' | jq '.aiResponse' | head -3

# Test Milestone (25 check-ins)
echo ""
echo "📅 Testing Milestone (25 check-ins):"
curl -X POST "$BASE_URL" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "happyThing": "Celebrated my progress and growth",
    "improveThing": "Want to help others on their journey",
    "userHistory": [],
    "journeyDay": 30,
    "journeyStage": "first_month",
    "totalCheckIns": 25,
    "consecutiveCheckInDays": 25
  }' | jq '.aiResponse' | head -3

echo ""
echo "✅ Journey-based prompt testing complete!" 