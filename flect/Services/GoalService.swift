import Foundation

class GoalService: ObservableObject {
    static let shared = GoalService()
    
    @Published var activeGoals: [TwelveWeekGoal] = []
    @Published var completedGoals: [TwelveWeekGoal] = []
    @Published var dailyProgress: [DailyGoalProgress] = []
    @Published var dailyBrainDumps: [DailyBrainDump] = []
    @Published var chatSessions: [ChatSession] = []
    @Published var isFirstTimeUser: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let goalsKey = "twelve_week_goals"
    private let completedGoalsKey = "completed_goals"
    private let dailyProgressKey = "daily_goal_progress"
    private let dailyBrainDumpsKey = "daily_brain_dumps"
    private let chatSessionsKey = "ai_chat_sessions"
    private let firstTimeUserKey = "is_first_time_goal_user"
    
    private init() {
        loadGoals()
        loadChatSessions()
        
        // Only load sample data if explicitly requested (not on fresh user)
        // Sample data will be loaded by loadSampleDataIfNeeded() when appropriate
    }
    
    // MARK: - Goal Management
    
    func createGoal(
        title: String,
        description: String,
        category: GoalCategory,
        communicationStyle: CommunicationStyle = .encouraging,
        accountabilityLevel: AccountabilityLevel = .moderate
    ) -> TwelveWeekGoal {
        
        let aiContext = GoalAIContext(
            preferredCommunicationStyle: communicationStyle,
            accountabilityLevel: accountabilityLevel
        )
        
        let goal = TwelveWeekGoal(
            title: title,
            description: description,
            category: category,
            aiContext: aiContext
        )
        
        // Create default milestones (every 3 weeks)
        let milestones = createDefaultMilestones(for: goal)
        var goalWithMilestones = goal
        goalWithMilestones.milestones = milestones
        
        activeGoals.append(goalWithMilestones)
        saveGoals()
        
        return goalWithMilestones
    }
    
    func updateGoalProgress(_ goalId: UUID, progress: Double) {
        if let index = activeGoals.firstIndex(where: { $0.id == goalId }) {
            activeGoals[index].currentProgress = min(max(progress, 0.0), 1.0)
            
            // Check if goal is completed
            if activeGoals[index].currentProgress >= 1.0 {
                activeGoals[index].isCompleted = true
                completeGoal(goalId)
            }
            
            saveGoals()
        }
    }
    
    func completeGoal(_ goalId: UUID) {
        if let index = activeGoals.firstIndex(where: { $0.id == goalId }) {
            var completedGoal = activeGoals[index]
            completedGoal.isCompleted = true
            completedGoal.isActive = false
            
            completedGoals.append(completedGoal)
            activeGoals.remove(at: index)
            
            saveGoals()
        }
    }
    
    func deleteGoal(_ goalId: UUID) {
        activeGoals.removeAll { $0.id == goalId }
        completedGoals.removeAll { $0.id == goalId }
        dailyProgress.removeAll { $0.goalId == goalId }
        saveGoals()
        saveDailyProgress()
    }
    
    // MARK: - Daily Progress Tracking
    
    func addDailyProgress(
        goalId: UUID,
        progressRating: Int,
        progressNote: String,
        moodImpact: MoodImpact,
        activitiesAligned: [String]
    ) {
        let progress = DailyGoalProgress(
            goalId: goalId,
            progressRating: progressRating,
            progressNote: progressNote,
            moodImpact: moodImpact,
            activitiesAligned: activitiesAligned
        )
        
        // Remove existing progress for today if it exists
        let today = Calendar.current.startOfDay(for: Date())
        dailyProgress.removeAll { 
            $0.goalId == goalId && Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        
        dailyProgress.append(progress)
        
        // Update overall goal progress based on daily ratings
        updateGoalProgressFromDailyRatings(goalId: goalId)
        
        saveDailyProgress()
    }
    
    func getDailyProgress(for goalId: UUID, date: Date = Date()) -> DailyGoalProgress? {
        return dailyProgress.first { 
            $0.goalId == goalId && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func getDailyProgressThisWeek(for goalId: UUID) -> [DailyGoalProgress] {
        let calendar = Calendar.current
        let now = Date()
        
        return dailyProgress.filter { progress in
            progress.goalId == goalId &&
            (calendar.dateInterval(of: .weekOfYear, for: now)?.contains(progress.date) ?? false)
        }.sorted { $0.date < $1.date }
    }
    
    private func updateGoalProgressFromDailyRatings(goalId: UUID) {
        let progressEntries = dailyProgress.filter { $0.goalId == goalId }
        guard !progressEntries.isEmpty else { return }
        
        // Calculate progress based on daily ratings and time elapsed
        let averageRating = progressEntries.reduce(0) { $0 + $1.progressRating } / progressEntries.count
        let daysSinceStart = progressEntries.count
        let targetDays = 84 // 12 weeks * 7 days
        
        // Progress = (average rating / 5) * (days completed / target days)
        let calculatedProgress = (Double(averageRating) / 5.0) * (Double(daysSinceStart) / Double(targetDays))
        
        updateGoalProgress(goalId, progress: calculatedProgress)
    }
    
    // MARK: - Brain Dump Management
    
    func saveDailyBrainDump(_ brainDump: DailyBrainDump) {
        // Remove existing brain dump for today if it exists
        let today = Calendar.current.startOfDay(for: Date())
        dailyBrainDumps.removeAll { 
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        
        // Add the new brain dump
        dailyBrainDumps.append(brainDump)
        saveDailyBrainDumps()
    }
    
    func getTodaysBrainDump() -> DailyBrainDump? {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyBrainDumps.first { 
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }
    
    func getBrainDump(for date: Date) -> DailyBrainDump? {
        return dailyBrainDumps.first { 
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func getBrainDumpsThisWeek() -> [DailyBrainDump] {
        let calendar = Calendar.current
        let now = Date()
        
        return dailyBrainDumps.filter { brainDump in
            calendar.dateInterval(of: .weekOfYear, for: now)?.contains(brainDump.date) ?? false
        }.sorted { $0.date < $1.date }
    }
    
    func getAllBrainDumps() -> [DailyBrainDump] {
        return dailyBrainDumps.sorted { $0.date > $1.date }
    }
    
    // MARK: - AI Chat Management
    
    func createChatSession(from brainDump: DailyBrainDump, mood: String) -> ChatSession {
        let session = ChatSession(
            goalContext: Array(brainDump.goalsWorkedOn),
            brainDumpContext: brainDump.brainDumpContent,
            moodContext: mood,
            sessionType: .dailyReflection
        )
        
        // Add welcome message from AI
        var sessionWithWelcome = session
        let welcomeMessage = createWelcomeMessage(for: session)
        sessionWithWelcome.addMessage(welcomeMessage)
        
        chatSessions.append(sessionWithWelcome)
        saveChatSessions()
        
        return sessionWithWelcome
    }
    
    func createNextDayAdviceSession() -> ChatSession? {
        // Get yesterday's context
        guard let yesterdayContext = getYesterdayContext() else { return nil }
        
        let session = ChatSession(
            goalContext: yesterdayContext.previousGoals,
            brainDumpContext: "Morning insights based on yesterday's reflection",
            moodContext: "Starting fresh today",
            sessionType: .nextDayAdvice,
            previousDayContext: yesterdayContext
        )
        
        // Add AI advice message based on yesterday
        var sessionWithAdvice = session
        let adviceMessage = createNextDayAdviceMessage(with: yesterdayContext)
        sessionWithAdvice.addMessage(adviceMessage)
        
        chatSessions.append(sessionWithAdvice)
        saveChatSessions()
        
        return sessionWithAdvice
    }
    
    @MainActor func shouldShowNextDayAdvice() -> Bool {
        // Show if:
        // 1. There's yesterday's check-in data (from CheckInService)
        // 2. User hasn't seen today's advice yet
        // 3. It's a new day since last check-in
        
        // Check if we have yesterday's check-in data
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayCheckIn = CheckInService.shared.getCheckInForDate(yesterday)
        guard yesterdayCheckIn != nil else { return false }
        
        // Check if we already have today's advice session
        let today = Calendar.current.startOfDay(for: Date())
        let hasAdviceToday = chatSessions.contains { session in
            session.sessionType == .nextDayAdvice && 
            Calendar.current.isDate(session.date, inSameDayAs: today)
        }
        
        return !hasAdviceToday
    }
    
    private func getYesterdayContext() -> PreviousDayContext? {
        guard let yesterdayBrainDump = getYesterdayBrainDump() else { return nil }
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayMood = getYesterdayMood() ?? "😐 Okay"
        
        // Extract challenges and wins from brain dump
        let challenges = extractChallenges(from: yesterdayBrainDump.brainDumpContent)
        let wins = extractWins(from: yesterdayBrainDump.brainDumpContent)
        
        // Calculate mood trend
        let moodTrend = calculateMoodTrend()
        
        return PreviousDayContext(
            previousDate: yesterday,
            previousMood: yesterdayMood,
            previousGoals: Array(yesterdayBrainDump.goalsWorkedOn),
            previousReflection: yesterdayBrainDump.brainDumpContent,
            previousChallenges: challenges,
            previousWins: wins,
            moodTrend: moodTrend
        )
    }
    
    private func getYesterdayBrainDump() -> DailyBrainDump? {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return dailyBrainDumps.first { brainDump in
            Calendar.current.isDate(brainDump.date, inSameDayAs: yesterday)
        }
    }
    
    private func getYesterdayMood() -> String? {
        // This would need to be integrated with CheckInService
        // For now, return a placeholder
        return "😊 Good"
    }
    
    private func extractChallenges(from content: String) -> [String] {
        let challengeKeywords = ["difficult", "hard", "struggle", "challenge", "problem", "tough", "stressed", "overwhelmed", "failed", "didn't", "couldn't", "skip", "missed"]
        
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let challenges = sentences.filter { sentence in
            let lowercased = sentence.lowercased()
            return challengeKeywords.contains { keyword in
                lowercased.contains(keyword)
            }
        }.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        
        return Array(challenges.prefix(3)) // Limit to 3 challenges
    }
    
    private func extractWins(from content: String) -> [String] {
        let winKeywords = ["great", "good", "awesome", "excellent", "proud", "accomplished", "achieved", "completed", "success", "win", "happy", "excited", "motivated", "progress"]
        
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let wins = sentences.filter { sentence in
            let lowercased = sentence.lowercased()
            return winKeywords.contains { keyword in
                lowercased.contains(keyword)
            }
        }.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        
        return Array(wins.prefix(3)) // Limit to 3 wins
    }
    
    private func calculateMoodTrend() -> MoodTrend {
        // Analyze last 7 days of mood data
        // For now, return stable as placeholder
        // This would integrate with CheckInService mood history
        return .stable
    }
    
    private func createNextDayAdviceMessage(with context: PreviousDayContext) -> ChatMessage {
        let advice = generateNextDayAdvice(with: context)
        
        let messageContext = MessageContext(
            intentType: .advice,
            confidence: 0.9,
            goalReferences: context.previousGoals,
            actionSuggestions: extractActionSuggestions(from: advice)
        )
        
        return ChatMessage(
            content: advice,
            type: .ai,
            messageContext: messageContext
        )
    }
    
    private func generateNextDayAdvice(with context: PreviousDayContext) -> String {
        var advice = ""
        
        // Start with mood-based greeting
        advice += generateMoodBasedGreeting(context.moodTrend)
        advice += "\n\n"
        
        // Acknowledge yesterday's work
        if !context.previousGoals.isEmpty {
            let goalNames = activeGoals.filter { context.previousGoals.contains($0.id) }
                .map { $0.title }
                .joined(separator: " and ")
            advice += "I saw you worked on \(goalNames) yesterday. "
        }
        
        // Celebrate wins
        if !context.previousWins.isEmpty {
            advice += "I'm particularly excited about: \(context.previousWins.first!). "
        }
        
        advice += "\n\n"
        
        // Address challenges and provide advice
        if !context.previousChallenges.isEmpty {
            advice += "I noticed you mentioned some challenges. Here's my take: "
            advice += generateChallengeAdvice(context.previousChallenges.first!)
            advice += "\n\n"
        }
        
        // Provide forward-looking advice
        advice += generateForwardAdvice(context)
        
        // Add mood-specific encouragement
        advice += "\n\n"
        advice += context.moodTrend.advice
        
        return advice
    }
    
    private func generateMoodBasedGreeting(_ trend: MoodTrend) -> String {
        switch trend {
        case .improving:
            return "Good morning! I can see you're on an upward trajectory. ✨"
        case .declining:
            return "Morning! Let's make today a turning point. 🌅"
        case .stable:
            return "Good morning! Your consistency is impressive. 🎯"
        case .volatile:
            return "Good morning! Let's bring some calm to your day. 🧘‍♀️"
        }
    }
    
    private func generateChallengeAdvice(_ challenge: String) -> String {
        let lowercased = challenge.lowercased()
        
        if lowercased.contains("time") || lowercased.contains("busy") {
            return "Time feels scarce when we're overwhelmed. Try breaking your goals into 10-minute chunks today."
        } else if lowercased.contains("motivated") || lowercased.contains("energy") {
            return "Motivation follows action, not the other way around. Start with the smallest possible step."
        } else if lowercased.contains("skip") || lowercased.contains("missed") {
            return "Missing a day doesn't break your progress - but the story you tell yourself about it can. Today is a fresh start."
        } else {
            return "Challenges are information, not judgments. What can this teach you about your approach?"
        }
    }
    
    private func generateForwardAdvice(_ context: PreviousDayContext) -> String {
        let goalCount = context.previousGoals.count
        
        if goalCount == 0 {
            return "Today might be a good day to choose one small thing that matters to you and give it some attention."
        } else if goalCount == 1 {
            return "You're focused, which I love. Let's build on yesterday's momentum with one clear action today."
        } else {
            return "You're juggling multiple goals - that takes skill. Pick your most important one for today and let the rest support it."
        }
    }
    
    private func extractActionSuggestions(from advice: String) -> [String] {
        // Extract actionable suggestions from advice text
        var suggestions: [String] = []
        
        if advice.contains("10-minute chunks") {
            suggestions.append("Break goals into 10-minute focused sessions")
        }
        if advice.contains("smallest possible step") {
            suggestions.append("Start with the tiniest action you can take")
        }
        if advice.contains("fresh start") {
            suggestions.append("Begin again today without judgment")
        }
        if advice.contains("one clear action") {
            suggestions.append("Choose one specific action for today")
        }
        
        return suggestions
    }
    
    func getTodaysChatSession() -> ChatSession? {
        let today = Calendar.current.startOfDay(for: Date())
        return chatSessions.first { 
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }
    
    func addMessageToSession(_ sessionId: UUID, message: ChatMessage) {
        if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
            chatSessions[index].addMessage(message)
            saveChatSessions()
        }
    }
    
    func getAIResponse(for message: String, in sessionId: UUID) async -> ChatMessage {
        // TODO: Integrate with OpenAI API
        // For now, return a mock response
        
        guard let session = chatSessions.first(where: { $0.id == sessionId }) else {
            return ChatMessage(
                content: "I'm sorry, I couldn't process your message. Please try again.",
                type: .ai
            )
        }
        
        let mockResponse = generateMockAIResponse(for: message, context: session)
        return ChatMessage(content: mockResponse, type: .ai)
    }
    
    private func createWelcomeMessage(for session: ChatSession) -> ChatMessage {
        let relevantGoals = activeGoals.filter { session.goalContext.contains($0.id) }
        
        if relevantGoals.isEmpty {
            return ChatMessage(
                content: "Hi! I see you've completed your daily check-in. How are you feeling about your progress today? I'm here to help you reflect and plan ahead! 💪",
                type: .ai
            )
        } else {
            let goalNames = relevantGoals.map { $0.category.emoji + " " + $0.title }.joined(separator: ", ")
            return ChatMessage(
                content: "Great job completing your daily reflection! I see you worked on: \(goalNames). I've read your thoughts and I'm excited to dive deeper with you. What would you like to explore first? 🚀",
                type: .ai
            )
        }
    }
    
    private func generateMockAIResponse(for message: String, context: ChatSession) -> String {
        // Mock AI responses based on common patterns
        let lowercaseMessage = message.lowercased()
        
        if lowercaseMessage.contains("stuck") || lowercaseMessage.contains("difficult") || lowercaseMessage.contains("hard") {
            return "I hear that you're facing some challenges. That's completely normal - growth often comes with obstacles. What specific part feels most challenging right now? Sometimes breaking it down into smaller steps can help. 💪"
        }
        
        if lowercaseMessage.contains("good") || lowercaseMessage.contains("great") || lowercaseMessage.contains("progress") {
            return "That's fantastic! I love hearing about your progress. What do you think made the difference today? Understanding what works can help you replicate this success. 🌟"
        }
        
        if lowercaseMessage.contains("motivation") || lowercaseMessage.contains("motivated") {
            return "Motivation can definitely fluctuate - that's human! What usually helps you get back on track? Remember, small consistent actions often matter more than waiting for perfect motivation. What's one small thing you could do tomorrow? 🎯"
        }
        
        if lowercaseMessage.contains("goal") || lowercaseMessage.contains("target") {
            let relevantGoals = activeGoals.filter { context.goalContext.contains($0.id) }
            if let firstGoal = relevantGoals.first {
                return "I see you're working on \(firstGoal.category.emoji) \(firstGoal.title). You're \(firstGoal.progressPercentage)% complete - that's real progress! What's your next milestone? 🎯"
            }
        }
        
        // Default response
        return "Thanks for sharing that with me. I can see you're putting thought into your growth. What would be most helpful to focus on right now? I'm here to support you however I can! 💙"
    }
    
    // MARK: - Milestone Management
    
    func completeMilestone(_ milestoneId: UUID, for goalId: UUID) {
        if let goalIndex = activeGoals.firstIndex(where: { $0.id == goalId }),
           let milestoneIndex = activeGoals[goalIndex].milestones.firstIndex(where: { $0.id == milestoneId }) {
            
            activeGoals[goalIndex].milestones[milestoneIndex].isCompleted = true
            activeGoals[goalIndex].milestones[milestoneIndex].completedDate = Date()
            
            // Update overall progress based on completed milestones
            let completedWeight = activeGoals[goalIndex].completedMilestones
                .reduce(0) { $0 + $1.progressWeight }
            activeGoals[goalIndex].currentProgress = min(completedWeight, 1.0)
            
            saveGoals()
        }
    }
    
    private func createDefaultMilestones(for goal: TwelveWeekGoal) -> [GoalMilestone] {
        let calendar = Calendar.current
        var milestones: [GoalMilestone] = []
        
        // Create 4 milestones (weeks 3, 6, 9, 12)
        for week in [3, 6, 9, 12] {
            guard let targetDate = calendar.date(byAdding: .weekOfYear, value: week, to: goal.createdDate) else { continue }
            
            let milestone = GoalMilestone(
                title: "Week \(week) Milestone",
                description: getDefaultMilestoneDescription(for: week, category: goal.category),
                targetWeek: week,
                targetDate: targetDate,
                progressWeight: 0.25 // Each milestone is worth 25%
            )
            
            milestones.append(milestone)
        }
        
        return milestones
    }
    
    private func getDefaultMilestoneDescription(for week: Int, category: GoalCategory) -> String {
        switch (week, category) {
        case (3, .health):
            return "Establish consistent workout routine"
        case (6, .health):
            return "See measurable improvements in fitness"
        case (9, .health):
            return "Reach halfway point of target metrics"
        case (12, .health):
            return "Achieve final health and fitness goal"
            
        case (3, .career):
            return "Complete initial planning and skill assessment"
        case (6, .career):
            return "Make significant progress on key deliverables"
        case (9, .career):
            return "Demonstrate measurable professional growth"
        case (12, .career):
            return "Achieve career milestone"
            
        case (3, .creativity):
            return "Complete first creative project or draft"
        case (6, .creativity):
            return "Refine and iterate on creative work"
        case (9, .creativity):
            return "Share work and gather feedback"
        case (12, .creativity):
            return "Complete and launch creative project"
            
        default:
            return "Quarter \(week/3) milestone - significant progress toward goal"
        }
    }
    
    // MARK: - Analytics and Insights
    
    func getGoalAnalytics(for goalId: UUID) -> GoalAnalytics? {
        guard let goal = activeGoals.first(where: { $0.id == goalId }) else { return nil }
        
        let progressEntries = dailyProgress.filter { $0.goalId == goalId }
        let recentEntries = progressEntries.suffix(7) // Last 7 days
        
        let averageProgress = recentEntries.isEmpty ? 0.0 : 
            Double(recentEntries.reduce(0) { $0 + $1.progressRating }) / Double(recentEntries.count)
        
        let moodImpactAverage = recentEntries.isEmpty ? 0.0 :
            recentEntries.reduce(0.0) { $0 + $1.moodImpact.value } / Double(recentEntries.count)
        
        let consistencyScore = calculateConsistencyScore(for: goalId)
        
        return GoalAnalytics(
            goal: goal,
            averageWeeklyProgress: averageProgress,
            moodImpactScore: moodImpactAverage,
            consistencyScore: consistencyScore,
            daysTracked: progressEntries.count,
            streakLength: calculateCurrentStreak(for: goalId)
        )
    }
    
    private func calculateConsistencyScore(for goalId: UUID) -> Double {
        let last14Days = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
        let progressInPeriod = dailyProgress.filter { 
            $0.goalId == goalId && (last14Days?.contains($0.date) ?? false)
        }
        
        return Double(progressInPeriod.count) / 14.0 // Percentage of days tracked
    }
    
    private func calculateCurrentStreak(for goalId: UUID) -> Int {
        let sortedProgress = dailyProgress
            .filter { $0.goalId == goalId }
            .sorted { $0.date > $1.date } // Most recent first
        
        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        
        for progress in sortedProgress {
            let progressDate = calendar.startOfDay(for: progress.date)
            if calendar.isDate(progressDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - AI Chat Unlock Logic
    
    func canAccessDailyAI(for goalId: UUID) -> Bool {
        let streak = calculateCurrentStreak(for: goalId)
        return streak >= 3 // Need 3+ day streak
    }
    
    func canAccessWeeklyAI(for goalId: UUID) -> Bool {
        let thisWeekProgress = getDailyProgressThisWeek(for: goalId)
        return thisWeekProgress.count >= 5 // Need 5+ days this week
    }
    
    func canAccessMonthlyAI(for goalId: UUID) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let monthlyProgress = dailyProgress.filter { progress in
            progress.goalId == goalId &&
            calendar.dateInterval(of: .month, for: now)?.contains(progress.date) ?? false
        }
        return monthlyProgress.count >= 20 // Need 20+ days this month
    }
    
    // MARK: - Data Persistence
    
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(activeGoals) {
            userDefaults.set(encoded, forKey: goalsKey)
        }
        if let encodedCompleted = try? JSONEncoder().encode(completedGoals) {
            userDefaults.set(encodedCompleted, forKey: completedGoalsKey)
        }
    }
    
    private func loadGoals() {
        guard let data = userDefaults.data(forKey: goalsKey) else {
            activeGoals = [] // No sample data by default
            completedGoals = []
            return
        }
        do {
            activeGoals = try JSONDecoder().decode([TwelveWeekGoal].self, from: data)
        } catch {
            print("Failed to load goals: \(error)")
            activeGoals = [] // No sample data fallback
            completedGoals = []
        }
    }
    
    private func saveDailyProgress() {
        if let encoded = try? JSONEncoder().encode(dailyProgress) {
            userDefaults.set(encoded, forKey: dailyProgressKey)
        }
    }
    
    private func loadDailyProgress() {
        if let data = userDefaults.data(forKey: dailyProgressKey),
           let decoded = try? JSONDecoder().decode([DailyGoalProgress].self, from: data) {
            dailyProgress = decoded
        }
    }
    
    private func saveDailyBrainDumps() {
        if let encoded = try? JSONEncoder().encode(dailyBrainDumps) {
            userDefaults.set(encoded, forKey: dailyBrainDumpsKey)
        }
    }
    
    private func loadDailyBrainDumps() {
        if let data = userDefaults.data(forKey: dailyBrainDumpsKey),
           let decoded = try? JSONDecoder().decode([DailyBrainDump].self, from: data) {
            dailyBrainDumps = decoded
        }
    }
    
    private func saveChatSessions() {
        if let encoded = try? JSONEncoder().encode(chatSessions) {
            userDefaults.set(encoded, forKey: chatSessionsKey)
        }
    }
    
    private func loadChatSessions() {
        if let data = userDefaults.data(forKey: chatSessionsKey),
           let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) {
            chatSessions = decoded
        }
    }
    
    private func checkFirstTimeUser() {
        isFirstTimeUser = !userDefaults.bool(forKey: firstTimeUserKey)
    }
    
    func markUserAsOnboarded() {
        isFirstTimeUser = false
        userDefaults.set(true, forKey: firstTimeUserKey)
    }
    
    // MARK: - Sample Data
    
    private func createSampleGoals() {
        // Clear existing data
        activeGoals.removeAll()
        chatSessions.removeAll()
        
        // Create sample 12-week goals
        let runningGoal = TwelveWeekGoal(
            title: "Run 5K",
            description: "Complete a 5K run without stopping",
            category: .fitness,
            milestones: [
                GoalMilestone(
                    title: "Run 1K",
                    description: "Complete 1K without stopping",
                    targetWeek: 2,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date(),
                    isCompleted: true,
                    completedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())
                ),
                GoalMilestone(
                    title: "Run 2K",
                    description: "Complete 2K without stopping",
                    targetWeek: 4,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date()) ?? Date()
                ),
                GoalMilestone(
                    title: "Run 3.5K",
                    description: "Complete 3.5K without stopping",
                    targetWeek: 8,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 8, to: Date()) ?? Date()
                ),
                GoalMilestone(
                    title: "Complete 5K",
                    description: "Full 5K completion",
                    targetWeek: 12,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 12, to: Date()) ?? Date()
                )
            ],
            aiContext: GoalAIContext(
                goalPersonality: "Determined runner building endurance",
                motivationFactors: ["Health", "Personal achievement", "Stress relief"],
                preferredCommunicationStyle: .motivational,
                accountabilityLevel: .moderate
            )
        )
        
        let readingGoal = TwelveWeekGoal(
            title: "Read 12 Books",
            description: "Read one book per week for 12 weeks",
            category: .learning,
            milestones: [
                GoalMilestone(
                    title: "3 Books",
                    description: "Read first 3 books",
                    targetWeek: 3,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 3, to: Date()) ?? Date(),
                    isCompleted: true,
                    completedDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())
                ),
                GoalMilestone(
                    title: "6 Books",
                    description: "Read 6 books",
                    targetWeek: 6,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 6, to: Date()) ?? Date()
                ),
                GoalMilestone(
                    title: "9 Books",
                    description: "Read 9 books",
                    targetWeek: 9,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 9, to: Date()) ?? Date()
                ),
                GoalMilestone(
                    title: "12 Books",
                    description: "Complete all 12 books",
                    targetWeek: 12,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 12, to: Date()) ?? Date()
                )
            ],
            aiContext: GoalAIContext(
                goalPersonality: "Curious learner expanding knowledge",
                motivationFactors: ["Knowledge", "Personal growth", "Intellectual stimulation"],
                preferredCommunicationStyle: .encouraging,
                accountabilityLevel: .gentle
            )
        )
        
        let meditationGoal = TwelveWeekGoal(
            title: "Daily Meditation",
            description: "Meditate for 20 minutes every day",
            category: .mindfulness,
            milestones: [
                GoalMilestone(
                    title: "Week 1",
                    description: "7 days of meditation",
                    targetWeek: 1,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date(),
                    isCompleted: true,
                    completedDate: Calendar.current.date(byAdding: .day, value: -14, to: Date())
                ),
                GoalMilestone(
                    title: "Week 4",
                    description: "4 weeks consistent",
                    targetWeek: 4,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date()) ?? Date()
                ),
                GoalMilestone(
                    title: "Week 8",
                    description: "8 weeks consistent",
                    targetWeek: 8,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 8, to: Date()) ?? Date()
                ),
                GoalMilestone(
                    title: "Week 12",
                    description: "Full 12 weeks",
                    targetWeek: 12,
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 12, to: Date()) ?? Date()
                )
            ],
            aiContext: GoalAIContext(
                goalPersonality: "Mindful practitioner seeking peace",
                motivationFactors: ["Mental clarity", "Stress reduction", "Spiritual growth"],
                preferredCommunicationStyle: .gentle,
                accountabilityLevel: .gentle
            )
        )
        
        // Set current progress
        var updatedRunningGoal = runningGoal
        updatedRunningGoal.currentProgress = 0.3
        
        var updatedReadingGoal = readingGoal
        updatedReadingGoal.currentProgress = 0.33
        
        var updatedMeditationGoal = meditationGoal
        updatedMeditationGoal.currentProgress = 0.18
        
        activeGoals = [updatedRunningGoal, updatedReadingGoal, updatedMeditationGoal]
        
        // Create sample chat sessions showing next-day advice
        let yesterdaySession = ChatSession(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            goalContext: [runningGoal.id],
            brainDumpContext: "Had a great run today! Felt strong and managed to run 2.5K without stopping. My breathing was much better than last week.",
            moodContext: "Energetic",
            sessionType: .dailyReflection,
            previousDayContext: nil
        )
        
        let todayAdviceSession = ChatSession(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            goalContext: [runningGoal.id],
            brainDumpContext: "",
            moodContext: "",
            sessionType: .nextDayAdvice,
            previousDayContext: PreviousDayContext(
                previousDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                previousMood: "Energetic",
                previousGoals: [runningGoal.id],
                previousReflection: "Had a great run today! Felt strong and managed to run 2.5K without stopping. My breathing was much better than last week.",
                previousChallenges: [],
                previousWins: ["Ran 2.5K without stopping", "Breathing improvement"],
                moodTrend: .improving
            )
        )
        
        // Add welcome messages to sessions
        var yesterdayWithMessages = yesterdaySession
        yesterdayWithMessages.addMessage(ChatMessage(
            content: "Great job on your run today! 🏃‍♂️ Running 2.5K without stopping is a huge milestone. Your improved breathing shows you're building real endurance. How are you feeling about tomorrow's session?",
            type: .ai,
            messageContext: MessageContext(
                intentType: .encouragement,
                confidence: 0.9,
                goalReferences: [runningGoal.id],
                actionSuggestions: ["Schedule tomorrow's run", "Focus on breathing technique"]
            )
        ))
        
        var todayWithMessages = todayAdviceSession
        todayWithMessages.addMessage(ChatMessage(
            content: "Good morning! 🌅 Based on yesterday's amazing 2.5K run, I can see you're building real momentum. Your breathing improvement is a key indicator of growing endurance. \n\nFor today: Consider a recovery walk or light jog. Your body showed great strength yesterday - let's build on that foundation smartly. Ready to keep this momentum going?",
            type: .ai,
            messageContext: MessageContext(
                intentType: .advice,
                confidence: 0.95,
                goalReferences: [runningGoal.id],
                actionSuggestions: ["Recovery walk", "Light jog", "Focus on building momentum"]
            )
        ))
        
        chatSessions = [yesterdayWithMessages, todayWithMessages]
        
        // Save the sample data
        saveGoals()
        saveChatSessions()
    }
    
    func clearAllData() {
        activeGoals.removeAll()
        completedGoals.removeAll()
        chatSessions.removeAll()
        userDefaults.removeObject(forKey: goalsKey)
        userDefaults.removeObject(forKey: completedGoalsKey)
        userDefaults.removeObject(forKey: chatSessionsKey)
        saveGoals()
        saveChatSessions()
    }
    
    func resetToFreshState() {
        clearAllData()
        isFirstTimeUser = true
        // Don't load sample data - keep it completely clean for new user experience
        
        print("🔄 Reset GoalService to fresh state")
        print("   All data cleared")
        print("   First time user: \(isFirstTimeUser)")
    }
    
    func resetToSampleData() {
        // Reset to sample data
        createSampleGoals()
        
        print("🎯 Reset GoalService to sample data")
        print("   Active goals: \(activeGoals.count)")
        print("   Chat sessions: \(chatSessions.count)")
    }
}

// MARK: - Goal Analytics Model

struct GoalAnalytics {
    let goal: TwelveWeekGoal
    let averageWeeklyProgress: Double
    let moodImpactScore: Double
    let consistencyScore: Double
    let daysTracked: Int
    let streakLength: Int
    
    var consistencyLevel: String {
        switch consistencyScore {
        case 0.8...: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        default: return "Needs Improvement"
        }
    }
    
    var moodImpactLevel: String {
        switch moodImpactScore {
        case 0.5...: return "Very Positive"
        case 0.2..<0.5: return "Positive"
        case -0.2..<0.2: return "Neutral"
        case -0.5..<(-0.2): return "Negative"
        default: return "Very Negative"
        }
    }
} 