import Foundation
import SwiftUI

// MARK: - Calendar Day State
enum CalendarDayState {
    case hasCheckIn(mood: String)
    case streakGap
    case noCheckIn
}

// MARK: - AI Response Models
struct CheckInAIResponse: Codable {
    let aiResponse: String
    let insights: [AIInsight]
    let themes: ThemeAnalysis
    let engagementLevel: String
}

struct AIInsight: Codable {
    let type: String
    let title: String
    let description: String
    let confidence: Double
}

struct ThemeAnalysis: Codable {
    let happiness: [String]
    let improvement: [String]
}

@MainActor
class CheckInService: ObservableObject {
    static let shared = CheckInService()
    
    @Published var checkIns: [DailyCheckIn] = []
    @Published var userInsights: [UserInsight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let storageKey = "flect_check_ins"
    private let insightsKey = "flect_insights"
    private let userDefaults = UserDefaults.standard
    
    // Helper to get the current app date (DEV-ONLY override)
    var now: Date {
        #if DEBUG
        return DevTools.currentAppDate ?? Date()
        #else
        return Date()
        #endif
    }

    // Update all usages of Date() in this file to use 'now' instead, for all date logic (e.g., streaks, today, calendar, etc.)
    
    private init() {
        loadCheckIns()
        
        // Only load sample data if explicitly requested (not on fresh user)
        // Sample data will be loaded by loadSampleDataIfNeeded() when appropriate
    }
    
    // MARK: - Check-in Management
    
    func submitCheckIn(
        happyThing: String,
        improveThing: String,
        moodName: String,
        date: Date? = nil,
        energy: Int? = nil,
        sleep: Int? = nil,
        social: Int? = nil,
        highlight: String? = nil,
        wellbeingScore: Int? = nil
    ) async throws -> DailyCheckIn {
        isLoading = true
        errorMessage = nil
        
        // Use provided date or simulated date (now) - NEVER use real Date()
        let checkInDate = date ?? now
        
        // Create the check-in with the correct date
        let checkIn = DailyCheckIn(
            date: checkInDate, // Always use simulated date in dev/testing
            happyThing: happyThing,
            improveThing: improveThing,
            moodName: moodName,
            completionState: .completed,
            energy: energy,
            sleep: sleep,
            social: social,
            highlight: highlight,
            wellbeingScore: wellbeingScore
        )
        
        // Add to local storage
        checkIns.append(checkIn)
        saveCheckIns()
        
        // Record in journey tracking
        UserPreferencesService.shared.recordCheckIn()
        
        // Process with AI for insights (async, doesn't block UI)
        Task {
            await processCheckInWithAI(checkIn)
        }
        
        isLoading = false
        return checkIn
    }
    
    func getTodaysCheckIn() -> DailyCheckIn? {
        return checkIns.first { Calendar.current.isDate($0.date, inSameDayAs: now) }
    }
    
    func hasCheckedInToday() -> Bool {
        return getTodaysCheckIn() != nil
    }
    
    // MARK: - AI Processing
    
    private func processCheckInWithAI(_ checkIn: DailyCheckIn) async {
        do {
            print("🤖 Processing check-in with AI...")
            
            // Prepare user history for context
            let recentHistory = getRecentCheckIns(limit: 10).map { checkIn in
                [
                    "happyThing": checkIn.happyThing,
                    "improveThing": checkIn.improveThing,
                    "date": ISO8601DateFormatter().string(from: checkIn.date)
                ]
            }
            
            // Call the Supabase Edge Function
            let url = URL(string: "https://rinjdpgdcdmtmadabqdf.supabase.co/functions/v1/process-check-in")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpbmpkcGdkY2RtdG1hZGFicWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0OTQ5MjcsImV4cCI6MjA2NzA3MDkyN30.vtWSWgvZgU1vIFG-wrAjBOi_jmIElwsttAkUvi1kVBg", forHTTPHeaderField: "Authorization")
            
            let requestBody: [String: Any] = [
                "happyThing": checkIn.happyThing,
                "improveThing": checkIn.improveThing,
                "userHistory": recentHistory,
                "journeyDay": UserPreferencesService.shared.journeyDay,
                "journeyStage": UserPreferencesService.shared.journeyStage.rawValue,
                "totalCheckIns": UserPreferencesService.shared.totalCheckIns,
                "consecutiveCheckInDays": UserPreferencesService.shared.consecutiveCheckInDays
            ]
            
            print("🚀 Journey Info - Day: \(UserPreferencesService.shared.journeyDay), Stage: \(UserPreferencesService.shared.journeyStage.rawValue), Total: \(UserPreferencesService.shared.totalCheckIns), Consecutive: \(UserPreferencesService.shared.consecutiveCheckInDays)")
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Make the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ AI processing failed - falling back to simple response")
                await fallbackProcessing(checkIn)
                return
            }
            
            // Parse the AI response
            let aiResponse = try JSONDecoder().decode(CheckInAIResponse.self, from: data)
            
            print("✅ AI processing successful!")
            print("💭 AI Response: \(aiResponse.aiResponse)")
            
            // Update the check-in with AI response
            await MainActor.run {
                if let index = self.checkIns.firstIndex(where: { $0.id == checkIn.id }) {
                    self.checkIns[index] = DailyCheckIn(
                        id: checkIn.id,
                        date: checkIn.date,
                        happyThing: checkIn.happyThing,
                        improveThing: checkIn.improveThing,
                        moodName: checkIn.moodName,
                        completionState: .followUpPending,
                        aiResponse: aiResponse.aiResponse,
                        aiQuestionAsked: aiResponse.aiResponse,
                        followUpCompleted: false
                    )
                    self.saveCheckIns()
                }
                
                // Process AI insights
                self.processAIInsights(aiResponse.insights)
            }
            
        } catch {
            print("🔥 AI processing error: \(error)")
            await fallbackProcessing(checkIn)
        }
    }
    
    private func fallbackProcessing(_ checkIn: DailyCheckIn) async {
        let engagementLevel = calculateUserEngagement()
        
        if engagementLevel.shouldGetSmartQuestions {
            let aiResponse = generateSmartResponse(for: checkIn, engagement: engagementLevel)
            
            await MainActor.run {
                if let index = self.checkIns.firstIndex(where: { $0.id == checkIn.id }) {
                    self.checkIns[index] = DailyCheckIn(
                        id: checkIn.id,
                        date: checkIn.date,
                        happyThing: checkIn.happyThing,
                        improveThing: checkIn.improveThing,
                        moodName: checkIn.moodName,
                        completionState: .followUpPending,
                        aiResponse: aiResponse,
                        aiQuestionAsked: aiResponse,
                        followUpCompleted: false
                    )
                    self.saveCheckIns()
                }
            }
        }
        
        // Always generate insights for testing and immediate feedback
        await generateInsights()
    }
    
    private func processAIInsights(_ aiInsights: [AIInsight]) {
        for aiInsight in aiInsights {
            let insightType: InsightType
            switch aiInsight.type {
            case "pattern": insightType = .pattern
            case "suggestion": insightType = .suggestion
            case "milestone": insightType = .milestone
            case "correlation": insightType = .correlation
            case "prediction": insightType = .prediction
            case "streak": insightType = .streak
            default: insightType = .pattern
            }
            
            let userInsight = UserInsight(
                type: insightType,
                title: aiInsight.title,
                description: aiInsight.description,
                confidence: aiInsight.confidence,
                dataPoints: Int(aiInsight.confidence * 100)
            )
            
            userInsights.append(userInsight)
        }
        
        saveInsights()
    }
    
    private func generateSmartResponse(for checkIn: DailyCheckIn, engagement: UserEngagementLevel) -> String {
        // This will be replaced with actual AI processing
        let responses = [
            "How did \(checkIn.improveThing) go yesterday?",
            "I notice you often mention \(extractKeyword(from: checkIn.happyThing)). What makes it special?",
            "You've been consistent with check-ins! What's motivating you?",
            "Any progress on \(checkIn.improveThing) today?"
        ]
        
        return responses.randomElement() ?? "How are you feeling about your progress?"
    }
    
    private func extractKeyword(from text: String) -> String {
        let commonWords = ["with", "and", "the", "a", "an", "to", "for", "of", "in", "on", "at"]
        let words = text.lowercased().components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        return words.first { !commonWords.contains($0) && $0.count > 2 } ?? "that"
    }
    
    // MARK: - Insights Generation
    
    private func generateInsights() async {
        let recentCheckIns = checkIns.suffix(21) // Last 3 weeks
        let allCheckIns = checkIns
        
        var newInsights: [UserInsight] = []
        
        // 1. Happiness Pattern Analysis
        if let happinessInsight = await analyzeHappinessPatterns(checkIns: Array(recentCheckIns)) {
            newInsights.append(happinessInsight)
        }
        
        // 2. Improvement Theme Analysis  
        if let improvementInsight = await analyzeImprovementThemes(checkIns: Array(recentCheckIns)) {
            newInsights.append(improvementInsight)
        }
        
        // 3. Temporal Pattern Analysis
        if let temporalInsight = await analyzeTemporalPatterns(checkIns: Array(allCheckIns)) {
            newInsights.append(temporalInsight)
        }
        
        // 4. Progress Pattern Analysis
        if allCheckIns.count >= 14 {
            if let progressInsight = await analyzeProgressPatterns(checkIns: Array(allCheckIns)) {
                newInsights.append(progressInsight)
            }
        }
        
        // 5. Milestone Celebration
        if let milestoneInsight = generateMilestoneInsights() {
            newInsights.append(milestoneInsight)
        }
        
        // Update insights with confidence-based filtering
        userInsights = newInsights.filter { $0.confidence >= 0.6 }
        saveInsights()
        
        print("💡 Generated \(userInsights.count) high-confidence insights")
    }
    
    // MARK: - Happiness Pattern Analysis
    
    private func analyzeHappinessPatterns(checkIns: [DailyCheckIn]) async -> UserInsight? {
        let happyEntries = checkIns.compactMap { $0.happyThing }
        guard happyEntries.count >= 5 else { return nil }
        
        // Categorize happiness themes
        let themes = categorizeHappinessThemes(entries: happyEntries)
        let topThemes = themes.sorted { $0.value > $1.value }.prefix(2)
        
        guard let primaryTheme = topThemes.first else { return nil }
        
        let confidence = calculateConfidence(
            occurrences: primaryTheme.value,
            total: happyEntries.count,
            minOccurrences: 3
        )
        
        let description: String
        
        switch primaryTheme.key {
        case .exercise:
            description = "You're consistently happiest when being active - exercise and movement bring you joy"
        case .social:
            description = "Your happiness peaks during social connections and time with others"
        case .achievement:
            description = "Completing goals and achieving milestones consistently lifts your mood"
        case .nature:
            description = "You feel most content when spending time outdoors or in nature"
        case .creativity:
            description = "Creative activities and self-expression bring you consistent happiness"
        case .learning:
            description = "Learning new things and personal growth fuel your happiness"
        case .relaxation:
            description = "Rest and relaxation activities consistently improve your mood"
        default:
            description = "You have consistent patterns in what brings you happiness"
        }
        
        return UserInsight(
            type: .pattern,
            title: "Happiness Pattern",
            description: description,
            confidence: confidence,
            dataPoints: happyEntries.count,
            metadata: InsightMetadata(
                relatedCheckInIds: Array(checkIns.suffix(7).map { $0.id }),
                keywords: [primaryTheme.key.rawValue]
            )
        )
    }
    
    // MARK: - Improvement Theme Analysis
    
    private func analyzeImprovementThemes(checkIns: [DailyCheckIn]) async -> UserInsight? {
        let improvementEntries = checkIns.compactMap { $0.improveThing }
        guard improvementEntries.count >= 5 else { return nil }
        
        let themes = categorizeImprovementThemes(entries: improvementEntries)
        let topThemes = themes.sorted { $0.value > $1.value }.prefix(2)
        
        guard let primaryTheme = topThemes.first else { return nil }
        
        let confidence = calculateConfidence(
            occurrences: primaryTheme.value,
            total: improvementEntries.count,
            minOccurrences: 3
        )
        
        let description: String
        
        switch primaryTheme.key {
        case .health:
            description = "Health and wellness improvements are your primary focus area"
        case .productivity:
            description = "You're consistently working on productivity and time management"
        case .social:
            description = "Strengthening relationships and social connections is important to you"
        case .learning:
            description = "Skill development and learning new things drive your growth"
        case .mindfulness:
            description = "Mental wellness and mindfulness practices are your growth priority"
        case .organization:
            description = "Getting organized and creating structure is a recurring theme"
        default:
            description = "You have clear areas where you're focused on improvement"
        }
        
        return UserInsight(
            type: .suggestion,
            title: "Growth Focus",
            description: description,
            confidence: confidence,
            dataPoints: improvementEntries.count,
            metadata: InsightMetadata(
                relatedCheckInIds: Array(checkIns.suffix(5).map { $0.id }),
                keywords: [primaryTheme.key.rawValue]
            )
        )
    }
    
    // MARK: - Temporal Pattern Analysis
    
    private func analyzeTemporalPatterns(checkIns: [DailyCheckIn]) async -> UserInsight? {
        guard checkIns.count >= 14 else { return nil }
        
        let calendar = Calendar.current
        var weekdayMoods: [Int: Double] = [:]
        var weekendMoods: [Int: Double] = [:]
        
        for checkIn in checkIns {
            let weekday = calendar.component(.weekday, from: checkIn.date)
            let moodScore = calculateMoodScore(checkIn: checkIn)
            
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                weekendMoods[weekday] = (weekendMoods[weekday] ?? 0) + moodScore
            } else {
                weekdayMoods[weekday] = (weekdayMoods[weekday] ?? 0) + moodScore
            }
        }
        
        let avgWeekdayMood = weekdayMoods.values.reduce(0, +) / Double(weekdayMoods.values.count)
        let avgWeekendMood = weekendMoods.values.reduce(0, +) / Double(weekendMoods.values.count)
        
        let difference = abs(avgWeekendMood - avgWeekdayMood)
        guard difference > 0.3 else { return nil } // Significant difference threshold
        
        let confidence = min(0.9, difference * 2) // Scale difference to confidence
        
        let description: String
        
        if avgWeekendMood > avgWeekdayMood {
            description = "Your mood tends to be significantly better on weekends than weekdays"
        } else {
            description = "You maintain better consistency and mood during structured weekdays"
        }
        
        return UserInsight(
            type: .pattern,
            title: "Weekly Pattern",
            description: description,
            confidence: confidence,
            dataPoints: checkIns.count,
            metadata: InsightMetadata(
                relatedCheckInIds: Array(checkIns.suffix(10).map { $0.id }),
                timePatterns: ["weekday_avg": String(avgWeekdayMood), "weekend_avg": String(avgWeekendMood)]
            )
        )
    }
    
    // MARK: - Progress Pattern Analysis
    
    private func analyzeProgressPatterns(checkIns: [DailyCheckIn]) async -> UserInsight? {
        guard checkIns.count >= 14 else { return nil }
        
        let recentEntries = Array(checkIns.suffix(7))
        let olderEntries = Array(checkIns.suffix(14).prefix(7))
        
        let recentMoodScore = recentEntries.map { calculateMoodScore(checkIn: $0) }.reduce(0, +) / Double(recentEntries.count)
        let olderMoodScore = olderEntries.map { calculateMoodScore(checkIn: $0) }.reduce(0, +) / Double(olderEntries.count)
        
        let improvement = recentMoodScore - olderMoodScore
        guard abs(improvement) > 0.2 else { return nil } // Significant change threshold
        
        let confidence = min(0.85, abs(improvement) * 3)
        
        let description: String
        
        if improvement > 0 {
            description = "Your overall mood and satisfaction have improved noticeably this week"
        } else {
            description = "You've had some challenging days recently - this is normal and temporary"
        }
        
        return UserInsight(
            type: .correlation,
            title: improvement > 0 ? "Positive Trend" : "Gentle Reminder",
            description: description,
            confidence: confidence,
            dataPoints: recentEntries.count,
            metadata: InsightMetadata(
                relatedCheckInIds: recentEntries.map { $0.id }
            )
        )
    }
    
    // MARK: - Milestone Celebration
    
    private func generateMilestoneInsights() -> UserInsight? {
        let currentStreak = calculateCurrentStreak()
        if currentStreak >= 30 { // Example milestone
            let confidence = calculateConfidence(
                occurrences: 1, // Only one milestone per user
                total: 1,
                minOccurrences: 1
            )
            return UserInsight(
                type: .milestone,
                title: "30 Day Streak! 🔥",
                description: "You've been consistent with your daily check-ins for 30 days! Keep up the great habit.",
                confidence: confidence,
                dataPoints: currentStreak
            )
        }
        return nil
    }
    
    // MARK: - Theme Categorization
    
    private enum HappinessTheme: String {
        case exercise, social, achievement, nature, creativity, learning, relaxation, work, food, other
    }
    
    private enum ImprovementTheme: String {
        case health, productivity, social, learning, mindfulness, organization, finance, habits, other
    }
    
    private func categorizeHappinessThemes(entries: [String]) -> [HappinessTheme: Int] {
        var themes: [HappinessTheme: Int] = [:]
        
        let exerciseKeywords = ["workout", "run", "gym", "exercise", "walk", "bike", "swim", "yoga", "sport", "active", "movement", "hike"]
        let socialKeywords = ["friend", "family", "dinner", "talk", "call", "visit", "party", "date", "together", "social", "people", "community"]
        let achievementKeywords = ["finished", "completed", "accomplished", "achieved", "success", "goal", "done", "progress", "win", "milestone"]
        let natureKeywords = ["outside", "park", "nature", "sun", "beach", "garden", "outdoor", "fresh air", "walk", "hike", "weather"]
        let creativityKeywords = ["art", "music", "write", "create", "design", "paint", "photo", "creative", "project", "craft", "build"]
        let learningKeywords = ["learn", "read", "study", "course", "book", "discover", "understand", "knowledge", "skill", "research"]
        let relaxationKeywords = ["relax", "rest", "calm", "peace", "quiet", "sleep", "nap", "meditation", "bath", "comfort", "chill"]
        let workKeywords = ["work", "job", "project", "meeting", "career", "colleague", "office", "task", "professional", "business"]
        let foodKeywords = ["food", "cook", "eat", "meal", "restaurant", "coffee", "dinner", "lunch", "recipe", "taste", "delicious"]
        
        for entry in entries {
            let lowercased = entry.lowercased()
            var categorized = false
            
            if exerciseKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.exercise, default: 0] += 1
                categorized = true
            }
            if socialKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.social, default: 0] += 1
                categorized = true
            }
            if achievementKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.achievement, default: 0] += 1
                categorized = true
            }
            if natureKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.nature, default: 0] += 1
                categorized = true
            }
            if creativityKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.creativity, default: 0] += 1
                categorized = true
            }
            if learningKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.learning, default: 0] += 1
                categorized = true
            }
            if relaxationKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.relaxation, default: 0] += 1
                categorized = true
            }
            if workKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.work, default: 0] += 1
                categorized = true
            }
            if foodKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.food, default: 0] += 1
                categorized = true
            }
            
            if !categorized {
                themes[.other, default: 0] += 1
            }
        }
        
        return themes
    }
    
    private func categorizeImprovementThemes(entries: [String]) -> [ImprovementTheme: Int] {
        var themes: [ImprovementTheme: Int] = [:]
        
        let healthKeywords = ["sleep", "exercise", "eat", "health", "diet", "water", "workout", "nutrition", "fitness", "wellness", "medical", "doctor"]
        let productivityKeywords = ["organize", "time", "productive", "focus", "efficient", "manage", "plan", "schedule", "priority", "work", "task"]
        let socialKeywords = ["social", "friend", "family", "relationship", "communicate", "connect", "people", "partner", "dating", "network"]
        let learningKeywords = ["learn", "study", "read", "skill", "course", "education", "knowledge", "practice", "improve", "develop"]
        let mindfulnessKeywords = ["meditate", "mindful", "stress", "anxiety", "mental", "calm", "peace", "breathe", "present", "gratitude", "therapy"]
        let organizationKeywords = ["clean", "organize", "declutter", "tidy", "organize", "sort", "arrange", "space", "room", "house"]
        let financeKeywords = ["money", "budget", "save", "spend", "financial", "invest", "debt", "income", "expense", "cost"]
        let habitsKeywords = ["habit", "routine", "consistent", "daily", "regular", "practice", "discipline", "commitment", "change", "behavior"]
        
        for entry in entries {
            let lowercased = entry.lowercased()
            var categorized = false
            
            if healthKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.health, default: 0] += 1
                categorized = true
            }
            if productivityKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.productivity, default: 0] += 1
                categorized = true
            }
            if socialKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.social, default: 0] += 1
                categorized = true
            }
            if learningKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.learning, default: 0] += 1
                categorized = true
            }
            if mindfulnessKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.mindfulness, default: 0] += 1
                categorized = true
            }
            if organizationKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.organization, default: 0] += 1
                categorized = true
            }
            if financeKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.finance, default: 0] += 1
                categorized = true
            }
            if habitsKeywords.contains(where: { lowercased.contains($0) }) {
                themes[.habits, default: 0] += 1
                categorized = true
            }
            
            if !categorized {
                themes[.other, default: 0] += 1
            }
        }
        
        return themes
    }
    
    // MARK: - Mood Scoring
    
    private func calculateMoodScore(checkIn: DailyCheckIn) -> Double {
        var score = 0.5 // Neutral baseline
        
        // Analyze happiness text sentiment
        let happyText = checkIn.happyThing
        score += analyzeSentiment(text: happyText) * 0.4
        
        // Analyze improvement text (less weight as it's about problems)
        let improveText = checkIn.improveThing
        let improveSentiment = analyzeSentiment(text: improveText)
        // Negative sentiment in improvement area is normal, so we invert and scale down
        score += (1.0 - improveSentiment) * 0.1
        
        // Factor in mood name
        let moodName = checkIn.moodName
        score += calculateMoodNameSentiment(moodName: moodName) * 0.3
        
        // Completion state affects mood
        switch checkIn.completionState {
        case .completed:
            score += 0.2
        case .followUpCompleted:
            score += 0.1
        case .pending, .followUpPending:
            score += 0.0
        }
        
        return max(0.0, min(1.0, score))
    }
    
    private func analyzeSentiment(text: String) -> Double {
        let positiveWords = ["happy", "great", "good", "amazing", "wonderful", "excellent", "fantastic", "awesome", "love", "enjoy", "fun", "beautiful", "peaceful", "successful", "accomplished", "excited", "grateful", "blessed", "perfect", "delicious", "comfortable", "relaxed", "proud", "confident", "energized", "refreshed", "satisfied", "content", "joyful", "pleasant"]
        let negativeWords = ["bad", "terrible", "awful", "horrible", "hate", "stress", "tired", "exhausted", "difficult", "hard", "challenging", "frustrating", "annoying", "disappointing", "sad", "worried", "anxious", "overwhelmed", "busy", "rushed", "sick", "pain", "struggle", "problem", "issue", "conflict", "argument"]
        
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var positiveCount = 0
        var negativeCount = 0
        
        for word in words {
            if positiveWords.contains(word) {
                positiveCount += 1
            } else if negativeWords.contains(word) {
                negativeCount += 1
            }
        }
        
        let totalSentimentWords = positiveCount + negativeCount
        guard totalSentimentWords > 0 else { return 0.5 } // Neutral if no sentiment words
        
        return Double(positiveCount) / Double(totalSentimentWords)
    }
    
    private func calculateMoodNameSentiment(moodName: String) -> Double {
        switch moodName {
        case "Great", "Amazing", "Wonderful", "Excellent", "Fantastic", "Awesome", "Love", "Enjoy", "Fun", "Beautiful", "Peaceful", "Successful", "Accomplished", "Excited", "Grateful", "Blessed", "Perfect", "Delicious", "Comfortable", "Relaxed", "Proud", "Confident", "Energized", "Refreshed", "Satisfied", "Content", "Joyful", "Pleasant":
            return 0.9
        case "Good", "Great", "Wonderful", "Excellent", "Fantastic", "Awesome", "Love", "Enjoy", "Fun", "Beautiful", "Peaceful", "Successful", "Accomplished", "Excited", "Grateful", "Blessed", "Perfect", "Delicious", "Comfortable", "Relaxed", "Proud", "Confident", "Energized", "Refreshed", "Satisfied", "Content", "Joyful", "Pleasant":
            return 0.7
        case "Okay", "Neutral", "Good", "Great", "Wonderful", "Excellent", "Fantastic", "Awesome", "Love", "Enjoy", "Fun", "Beautiful", "Peaceful", "Successful", "Accomplished", "Excited", "Grateful", "Blessed", "Perfect", "Delicious", "Comfortable", "Relaxed", "Proud", "Confident", "Energized", "Refreshed", "Satisfied", "Content", "Joyful", "Pleasant":
            return 0.5
        case "Rough", "Bad", "Terrible", "Awful", "Horrible", "Hate", "Stress", "Tired", "Exhausted", "Difficult", "Hard", "Challenging", "Frustrating", "Annoying", "Disappointing", "Sad", "Worried", "Anxious", "Overwhelmed", "Busy", "Rushed", "Sick", "Pain", "Struggle", "Problem", "Issue", "Conflict", "Argument":
            return 0.3
        case "Sad", "Worried", "Anxious", "Overwhelmed", "Sick", "Pain", "Struggle", "Problem", "Issue", "Conflict", "Argument":
            return 0.1
        default:
            return 0.5
        }
    }
    
    // MARK: - Confidence Calculation
    
    private func calculateConfidence(occurrences: Int, total: Int, minOccurrences: Int) -> Double {
        guard total > 0 else { return 0.0 }
        
        let frequency = Double(occurrences) / Double(total)
        let sufficientData = occurrences >= minOccurrences
        
        if !sufficientData {
            return 0.0
        }
        
        // Higher frequency = higher confidence, but cap it
        let frequencyConfidence = min(0.9, frequency * 2.0)
        
        // More data points = higher confidence
        let dataConfidence = min(0.9, Double(total) / 20.0)
        
        return (frequencyConfidence + dataConfidence) / 2.0
    }
    
    // MARK: - User Engagement
    
    func calculateUserEngagement() -> UserEngagementLevel {
        let daysSinceInstall = daysSinceFirstCheckIn()
        let totalCheckIns = checkIns.count
        let currentStreak = calculateCurrentStreak()
        let longestStreak = calculateLongestStreak()
        let averagePerWeek = calculateAverageCheckInsPerWeek()
        
        return UserEngagementLevel(
            daysSinceInstall: daysSinceInstall,
            totalCheckIns: totalCheckIns,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageCheckInsPerWeek: averagePerWeek
        )
    }
    
    /// Returns dates that are part of the current streak, including gap allowances
    func getCurrentStreakDates() -> [Date] {
        let sortedCheckIns = checkIns.sorted { $0.date > $1.date }
        var streakDates: [Date] = []
        var currentDate = Calendar.current.startOfDay(for: now)
        
        for checkIn in sortedCheckIns {
            let checkInDate = Calendar.current.startOfDay(for: checkIn.date)
            
            if Calendar.current.isDate(checkInDate, inSameDayAs: currentDate) {
                streakDates.append(checkInDate)
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if checkInDate < currentDate {
                // Allow for one day gap (e.g., if someone checks in late)
                let daysBetween = Calendar.current.dateComponents([.day], from: checkInDate, to: currentDate).day ?? 0
                if daysBetween <= 1 {
                    streakDates.append(checkInDate)
                    currentDate = Calendar.current.startOfDay(for: checkIn.date)
                    currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            }
        }
        
        return streakDates.sorted()
    }
    
    /// Returns dates for the last 7 days that should be highlighted in the calendar
    /// This includes both actual check-ins and streak-eligible dates
    func getCalendarDates() -> [Date] {
        let calendar = Calendar.current
        let today = now
        let last7Days = (0..<7).compactMap { 
            calendar.date(byAdding: .day, value: -6 + $0, to: today)
        }
        
        let streakDates = getCurrentStreakDates()
        let streakDateSet = Set(streakDates.map { calendar.startOfDay(for: $0) })
        
        return last7Days.map { date in
            let startOfDay = calendar.startOfDay(for: date)
            return startOfDay
        }
    }
    
    /// Returns the calendar state for each date in the last 7 days
    func getCalendarState() -> [Date: CalendarDayState] {
        let calendar = Calendar.current
        let today = now
        let last7Days = (0..<7).compactMap { 
            calendar.date(byAdding: .day, value: -6 + $0, to: today)
        }
        
        let streakDates = getCurrentStreakDates()
        let streakDateSet = Set(streakDates.map { calendar.startOfDay(for: $0) })
        
        var calendarState: [Date: CalendarDayState] = [:]
        
        for date in last7Days {
            let startOfDay = calendar.startOfDay(for: date)
            let checkIn = getCheckInForDate(date)
            
            if let checkIn = checkIn {
                // Has a check-in
                calendarState[date] = .hasCheckIn(mood: checkIn.moodName)
            } else if streakDateSet.contains(startOfDay) {
                // Part of current streak but no check-in (gap day)
                calendarState[date] = .streakGap
            } else {
                // No check-in and not part of streak
                calendarState[date] = .noCheckIn
            }
        }
        
        return calendarState
    }
    
    private func daysSinceFirstCheckIn() -> Int {
        guard let firstCheckIn = checkIns.min(by: { $0.createdAt < $1.createdAt }) else { return 0 }
        return Calendar.current.dateComponents([.day], from: firstCheckIn.createdAt, to: now).day ?? 0
    }
    
    private func calculateCurrentStreak() -> Int {
        let sortedCheckIns = checkIns.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: now)
        
        for checkIn in sortedCheckIns {
            let checkInDate = Calendar.current.startOfDay(for: checkIn.date)
            
            if Calendar.current.isDate(checkInDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if checkInDate < currentDate {
                // Allow for one day gap (e.g., if someone checks in late)
                let daysBetween = Calendar.current.dateComponents([.day], from: checkInDate, to: currentDate).day ?? 0
                if daysBetween <= 1 {
                    streak += 1
                    currentDate = Calendar.current.startOfDay(for: checkIn.date)
                    currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else {
                    break
                }
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        // Implementation for longest streak calculation
        // This is a simplified version
        return max(calculateCurrentStreak(), 0)
    }
    
    private func calculateAverageCheckInsPerWeek() -> Double {
        let days = max(daysSinceFirstCheckIn(), 1)
        let weeks = Double(days) / 7.0
        return Double(checkIns.count) / weeks
    }
    
    // MARK: - Data Persistence
    
    func loadTodaysCheckIn() {
        loadCheckIns()
        // Method loads today's check-in as part of the general check-ins loading process
        // Today's check-in can be accessed via getTodaysCheckIn() method
    }
    
    func getCheckInForDate(_ date: Date) -> DailyCheckIn? {
        let targetDate = Calendar.current.startOfDay(for: date)
        return checkIns.first { checkIn in
            let checkInDate = Calendar.current.startOfDay(for: checkIn.date)
            return Calendar.current.isDate(checkInDate, inSameDayAs: targetDate)
        }
    }
    
    func saveCheckIn(_ checkIn: DailyCheckIn) {
        // Add or update check-in
        if let index = checkIns.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: checkIn.date) }) {
            checkIns[index] = checkIn
        } else {
            checkIns.append(checkIn)
        }
        
        // Sort by date
        checkIns.sort { $0.date > $1.date }
        
        // Save to UserDefaults
        saveCheckIns()
        
        // Debug: Log the date being saved
        #if DEBUG
        print("💾 Saved check-in for date: \(checkIn.date)")
        print("   Simulated date (now): \(now)")
        print("   Real date: \(Date())")
        #endif
    }
    
    private func loadCheckIns() {
        // Load persisted check-ins
        guard let data = userDefaults.data(forKey: storageKey) else {
            checkIns = [] // No sample data by default
            return
        }
        
        do {
            checkIns = try JSONDecoder().decode([DailyCheckIn].self, from: data)
        } catch {
            print("Failed to load check-ins: \(error)")
            checkIns = [] // No sample data fallback
        }
    }
    
    // Change from private to internal so DevTools can call it
    func saveCheckIns() {
        do {
            let data = try JSONEncoder().encode(checkIns)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to save check-ins: \(error)")
        }
    }
    
    private func loadInsights() {
        guard let data = userDefaults.data(forKey: insightsKey) else {
            userInsights = []
            return
        }
        
        do {
            userInsights = try JSONDecoder().decode([UserInsight].self, from: data)
        } catch {
            print("Failed to load insights: \(error)")
            userInsights = []
        }
    }
    
    private func saveInsights() {
        do {
            let data = try JSONEncoder().encode(userInsights)
            userDefaults.set(data, forKey: insightsKey)
        } catch {
            print("Failed to save insights: \(error)")
        }
    }
    
    // MARK: - Sample Data
    
    private func createSampleCheckIns() -> [DailyCheckIn] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now) // Use simulated date
        let moods = ["Rough", "Okay", "Neutral", "Good", "Great"]
        var sampleCheckIns: [DailyCheckIn] = []
        
        // Create check-ins for the last 7 days, cycling through moods
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let mood = moods[dayOffset % moods.count]
            let happyThing = "Sample happy thing for \(mood)"
            let improveThing = "Sample improve thing for \(mood)"
            let checkIn = DailyCheckIn(
                date: date, // Use calculated date (based on simulated today)
                happyThing: happyThing,
                improveThing: improveThing,
                moodName: mood,
                completionState: .completed
            )
            sampleCheckIns.append(checkIn)
        }
        return sampleCheckIns
    }
    
    // MARK: - Public API
    
    func getRecentCheckIns(limit: Int = 10) -> [DailyCheckIn] {
        return Array(checkIns.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    /// Load sample data for testing streak calculation and calendar display
    func loadSampleDataForTesting() {
        let sampleCheckIns = createSampleCheckIns()
        checkIns = sampleCheckIns
        saveCheckIns()
        print("📊 Loaded \(sampleCheckIns.count) sample check-ins for testing")
        print("🔥 Current streak: \(calculateCurrentStreak()) days")
        print("📅 Streak dates: \(getCurrentStreakDates().map { Calendar.current.component(.day, from: $0) })")
    }
    
    func getActiveInsights() -> [UserInsight] {
        return userInsights.filter { $0.isActive && !$0.isExpired }
    }
    
    func clearAllData() {
        checkIns.removeAll()
        userDefaults.removeObject(forKey: storageKey) // Remove persisted check-ins
        saveCheckIns()
    }
    
    func resetToFreshState() {
        clearAllData()
        // Don't load sample data - keep it completely clean for new user experience
    }
    
    func resetToSampleData() {
        // Clear existing data first
        clearAllData()
        
        // Load fresh sample data
        checkIns = createSampleCheckIns()
        userInsights = []
        saveCheckIns()
        saveInsights()
        
        print("🔄 Reset to sample data - \(checkIns.count) check-ins loaded")
        print("📅 Today's date: \(DateFormatter().string(from: now))")
        print("🔍 Has checked in today: \(hasCheckedInToday())")
        
        if let todaysCheckIn = getTodaysCheckIn() {
            print("⚠️ WARNING: Found today's check-in in sample data!")
            print("   Date: \(todaysCheckIn.date)")
            print("   Happy: \(todaysCheckIn.happyThing)")
        } else {
            print("✅ Today is available for new check-in")
        }
        
        // Generate insights from sample data
        Task {
            await generateInsights()
            print("💡 Generated insights from sample data")
        }
    }
} 