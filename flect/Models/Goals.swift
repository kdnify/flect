import Foundation

// MARK: - 12-Week Goal Models

struct TwelveWeekGoal: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: GoalCategory
    let targetDate: Date
    let createdDate: Date
    var currentProgress: Double // 0.0 - 1.0
    var milestones: [GoalMilestone]
    var weeklyCheckIns: [WeeklyGoalCheckIn]
    var isActive: Bool
    var isCompleted: Bool
    let aiContext: GoalAIContext
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: GoalCategory,
        targetDate: Date = Calendar.current.date(byAdding: .weekOfYear, value: 12, to: Date()) ?? Date(),
        currentProgress: Double = 0.0,
        milestones: [GoalMilestone] = [],
        weeklyCheckIns: [WeeklyGoalCheckIn] = [],
        isActive: Bool = true,
        isCompleted: Bool = false,
        aiContext: GoalAIContext
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.targetDate = targetDate
        self.createdDate = Date()
        self.currentProgress = currentProgress
        self.milestones = milestones
        self.weeklyCheckIns = weeklyCheckIns
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.aiContext = aiContext
    }
    
    // Computed properties
    var weeksRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        return calendar.dateComponents([.weekOfYear], from: now, to: targetDate).weekOfYear ?? 0
    }
    
    var weeksElapsed: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.weekOfYear], from: createdDate, to: Date()).weekOfYear ?? 0
    }
    
    var progressPercentage: Int {
        return Int(currentProgress * 100)
    }
    
    var nextMilestone: GoalMilestone? {
        return milestones.first { !$0.isCompleted }
    }
    
    var completedMilestones: [GoalMilestone] {
        return milestones.filter { $0.isCompleted }
    }
    
    var isOnTrack: Bool {
        let expectedProgress = Double(weeksElapsed) / 12.0
        return currentProgress >= (expectedProgress * 0.8) // 80% of expected progress
    }
}

// MARK: - Frequency-Based Goal Tracking

/// Complements TwelveWeekGoal with smart frequency-based tracking
struct FrequencyGoal: Identifiable, Codable {
    let id: UUID
    let parentGoalId: UUID // Links to TwelveWeekGoal
    let title: String
    let frequency: GoalFrequency
    let flexibilityLevel: FlexibilityLevel
    let startDate: Date
    let endDate: Date
    var completedSessions: [GoalSession] // Individual completions
    var weeklyTargets: [WeeklyTarget] // Weekly targets and completion
    var smartSuggestions: [SmartSuggestion] // AI-generated suggestions
    let createdDate: Date
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        parentGoalId: UUID,
        title: String,
        frequency: GoalFrequency,
        flexibilityLevel: FlexibilityLevel = .balanced,
        startDate: Date = Date(),
        endDate: Date
    ) {
        self.id = id
        self.parentGoalId = parentGoalId
        self.title = title
        self.frequency = frequency
        self.flexibilityLevel = flexibilityLevel
        self.startDate = startDate
        self.endDate = endDate
        self.completedSessions = []
        self.weeklyTargets = []
        self.smartSuggestions = []
        self.createdDate = Date()
        self.lastUpdated = Date()
    }
    
    // MARK: - Computed Properties
    
    var currentWeekTarget: WeeklyTarget? {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return weeklyTargets.first { calendar.isDate($0.weekStart, inSameDayAs: weekStart) }
    }
    
    var currentWeekProgress: Double {
        guard let target = currentWeekTarget else { return 0.0 }
        return Double(target.completedSessions) / Double(target.targetSessions)
    }
    
    var overallProgress: Double {
        let totalWeeks = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 1
        let completedWeeks = weeklyTargets.filter { $0.isCompleted }.count
        return Double(completedWeeks) / Double(totalWeeks)
    }
    
    var streakCount: Int {
        // Calculate current streak based on frequency
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while currentDate >= startDate {
            if hasCompletedSession(on: currentDate) {
                streak += 1
            } else if shouldHaveCompletedSession(on: currentDate) {
                break // Streak is broken
            }
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    var isOnTrack: Bool {
        guard let target = currentWeekTarget else { return true }
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        let expectedProgress = Double(dayOfWeek) / 7.0
        let actualProgress = currentWeekProgress
        
        return actualProgress >= (expectedProgress * 0.8) // 80% threshold
    }
    
    var nextSuggestion: SmartSuggestion? {
        return smartSuggestions.first { !$0.isCompleted }
    }
    
    // MARK: - Helper Methods
    
    func hasCompletedSession(on date: Date) -> Bool {
        let calendar = Calendar.current
        return completedSessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }
    }
    
    func shouldHaveCompletedSession(on date: Date) -> Bool {
        // Logic to determine if a session should have been completed on this date
        // based on frequency and flexibility level
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        
        switch frequency {
        case .daily:
            return true
        case .twiceWeekly:
            return dayOfWeek == 2 || dayOfWeek == 5 // Monday & Thursday
        case .thriceWeekly:
            return dayOfWeek == 2 || dayOfWeek == 4 || dayOfWeek == 6 // Mon, Wed, Fri
        case .weekly:
            return dayOfWeek == 2 // Monday
        case .custom(let times):
            // For custom frequencies, distribute evenly across the week
            let targetDays = Array(2...(times + 1)) // Start from Monday
            return targetDays.contains(dayOfWeek)
        }
    }
    
    mutating func addSession(_ session: GoalSession) {
        completedSessions.append(session)
        updateWeeklyTarget(for: session.date)
        lastUpdated = Date()
    }
    
    mutating func updateWeeklyTarget(for date: Date) {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        
        if let targetIndex = weeklyTargets.firstIndex(where: { calendar.isDate($0.weekStart, inSameDayAs: weekStart) }) {
            weeklyTargets[targetIndex].completedSessions += 1
            weeklyTargets[targetIndex].lastUpdated = Date()
        } else {
            let newTarget = WeeklyTarget(
                weekStart: weekStart,
                targetSessions: frequency.timesPerWeek,
                completedSessions: 1
            )
            weeklyTargets.append(newTarget)
        }
    }
}

enum GoalFrequency: Codable {
    case daily
    case twiceWeekly
    case thriceWeekly
    case weekly
    case custom(Int) // Times per week
    
    var displayName: String {
        switch self {
        case .daily: return "Every day"
        case .twiceWeekly: return "Twice a week"
        case .thriceWeekly: return "3 times a week"
        case .weekly: return "Once a week"
        case .custom(let times): return "\(times) times a week"
        }
    }
    
    var shortName: String {
        switch self {
        case .daily: return "Daily"
        case .twiceWeekly: return "2x/week"
        case .thriceWeekly: return "3x/week"
        case .weekly: return "Weekly"
        case .custom(let times): return "\(times)x/week"
        }
    }
    
    var timesPerWeek: Int {
        switch self {
        case .daily: return 7
        case .twiceWeekly: return 2
        case .thriceWeekly: return 3
        case .weekly: return 1
        case .custom(let times): return times
        }
    }
    
    var recommendedFor: [GoalCategory] {
        switch self {
        case .daily: return [.health, .personal, .learning]
        case .twiceWeekly: return [.creativity, .career, .business]
        case .thriceWeekly: return [.health, .finance]
        case .weekly: return [.relationships, .personal]
        case .custom: return GoalCategory.allCases
        }
    }
    
    var description: String {
        switch self {
        case .daily: return "Build consistent daily habits"
        case .twiceWeekly: return "Steady progress without overwhelm"
        case .thriceWeekly: return "Regular practice with rest days"
        case .weekly: return "Focused weekly sessions"
        case .custom(let times): return "Custom \(times) times per week"
        }
    }
    
    var suggestedDays: [String] {
        switch self {
        case .daily: return ["Every day"]
        case .twiceWeekly: return ["Monday", "Thursday"]
        case .thriceWeekly: return ["Monday", "Wednesday", "Friday"]
        case .weekly: return ["Monday"]
        case .custom(let times):
            let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            return Array(days.prefix(times))
        }
    }
}

enum FlexibilityLevel: String, Codable, CaseIterable {
    case strict = "strict"
    case balanced = "balanced"
    case flexible = "flexible"
    
    var displayName: String {
        switch self {
        case .strict: return "Strict Schedule"
        case .balanced: return "Balanced"
        case .flexible: return "Flexible"
        }
    }
    
    var description: String {
        switch self {
        case .strict: return "Same time, same days every week"
        case .balanced: return "Consistent frequency, flexible timing"
        case .flexible: return "Hit weekly targets, any schedule"
        }
    }
    
    var allowedMissedDays: Int {
        switch self {
        case .strict: return 0
        case .balanced: return 1
        case .flexible: return 2
        }
    }
    
    var motivationStyle: String {
        switch self {
        case .strict: return "Discipline builds character"
        case .balanced: return "Progress over perfection"
        case .flexible: return "Adapt to your life"
        }
    }
    
    var reminderStyle: String {
        switch self {
        case .strict: return "Daily reminders at set times"
        case .balanced: return "Gentle nudges when behind"
        case .flexible: return "Weekly check-ins only"
        }
    }
}

struct GoalSession: Identifiable, Codable {
    let id: UUID
    let goalId: UUID
    let date: Date
    let duration: TimeInterval? // Optional: how long the session lasted
    let quality: SessionQuality // How good the session was
    let notes: String
    let moodBefore: String?
    let moodAfter: String?
    let createdDate: Date
    
    init(
        id: UUID = UUID(),
        goalId: UUID,
        date: Date = Date(),
        duration: TimeInterval? = nil,
        quality: SessionQuality = .good,
        notes: String = "",
        moodBefore: String? = nil,
        moodAfter: String? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.date = date
        self.duration = duration
        self.quality = quality
        self.notes = notes
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.createdDate = Date()
    }
}

enum SessionQuality: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case okay = "okay"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .okay: return "Okay"
        case .poor: return "Poor"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "🌟"
        case .good: return "👍"
        case .okay: return "👌"
        case .poor: return "👎"
        }
    }
    
    var value: Double {
        switch self {
        case .excellent: return 1.0
        case .good: return 0.8
        case .okay: return 0.6
        case .poor: return 0.4
        }
    }
}

struct WeeklyTarget: Identifiable, Codable {
    let id: UUID
    let weekStart: Date
    let targetSessions: Int
    var completedSessions: Int
    let createdDate: Date
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        weekStart: Date,
        targetSessions: Int,
        completedSessions: Int = 0
    ) {
        self.id = id
        self.weekStart = weekStart
        self.targetSessions = targetSessions
        self.completedSessions = completedSessions
        self.createdDate = Date()
        self.lastUpdated = Date()
    }
    
    var isCompleted: Bool {
        return completedSessions >= targetSessions
    }
    
    var progress: Double {
        return Double(completedSessions) / Double(targetSessions)
    }
    
    var weekEnd: Date {
        return Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }
}

struct SmartSuggestion: Identifiable, Codable {
    let id: UUID
    let type: SuggestionType
    let title: String
    let description: String
    let actionSteps: [String]
    let priority: SuggestionPriority
    let createdDate: Date
    var isCompleted: Bool
    var completedDate: Date?
    
    init(
        id: UUID = UUID(),
        type: SuggestionType,
        title: String,
        description: String,
        actionSteps: [String] = [],
        priority: SuggestionPriority = .medium,
        isCompleted: Bool = false,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.actionSteps = actionSteps
        self.priority = priority
        self.createdDate = Date()
        self.isCompleted = isCompleted
        self.completedDate = completedDate
    }
}

enum SuggestionType: String, Codable, CaseIterable {
    case scheduling = "scheduling"
    case motivation = "motivation"
    case efficiency = "efficiency"
    case adjustment = "adjustment"
    
    var displayName: String {
        switch self {
        case .scheduling: return "Scheduling"
        case .motivation: return "Motivation"
        case .efficiency: return "Efficiency"
        case .adjustment: return "Goal Adjustment"
        }
    }
    
    var icon: String {
        switch self {
        case .scheduling: return "calendar"
        case .motivation: return "flame"
        case .efficiency: return "speedometer"
        case .adjustment: return "slider.horizontal.3"
        }
    }
}

enum SuggestionPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#95A5A6"     // Gray
        case .medium: return "#3498DB"  // Blue
        case .high: return "#F39C12"    // Orange
        case .urgent: return "#E74C3C"  // Red
        }
    }
}

// MARK: - Goal Categories

enum GoalCategory: String, CaseIterable, Codable {
    case health = "health"
    case career = "career"
    case creativity = "creativity"
    case relationships = "relationships"
    case finance = "finance"
    case learning = "learning"
    case personal = "personal"
    case business = "business"
    case habit = "habit"      // New: for daily habits
    case fitness = "fitness"  // New: for fitness goals
    case skill = "skill"      // New: for skill development
    case mindfulness = "mindfulness" // New: for meditation, etc.
    
    var displayName: String {
        switch self {
        case .health: return "Health & Wellness"
        case .career: return "Career"
        case .creativity: return "Creative Projects"
        case .relationships: return "Relationships"
        case .finance: return "Financial"
        case .learning: return "Learning & Skills"
        case .personal: return "Personal Growth"
        case .business: return "Business & Entrepreneurship"
        case .habit: return "Daily Habits"
        case .fitness: return "Fitness & Training"
        case .skill: return "Skill Development"
        case .mindfulness: return "Mindfulness & Meditation"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .career: return "briefcase.fill"
        case .creativity: return "paintbrush.fill"
        case .relationships: return "person.2.fill"
        case .finance: return "dollarsign.circle.fill"
        case .learning: return "book.fill"
        case .personal: return "person.fill"
        case .business: return "building.2.fill"
        case .habit: return "repeat.circle.fill"
        case .fitness: return "figure.run"
        case .skill: return "graduationcap.fill"
        case .mindfulness: return "leaf.fill"
        }
    }
    
    var color: String {
        switch self {
        case .health: return "#FF6B6B"      // Red
        case .career: return "#4ECDC4"      // Teal
        case .creativity: return "#45B7D1"  // Blue
        case .relationships: return "#96CEB4" // Green
        case .finance: return "#FFEAA7"     // Yellow
        case .learning: return "#DDA0DD"    // Plum
        case .personal: return "#98D8C8"    // Mint
        case .business: return "#F7DC6F"    // Gold
        case .habit: return "#A8E6CF"       // Light green
        case .fitness: return "#FF8A80"     // Light red
        case .skill: return "#B39DDB"       // Light purple
        case .mindfulness: return "#81C784" // Green
        }
    }
    
    var emoji: String {
        switch self {
        case .health: return "🏥"
        case .career: return "💼"
        case .creativity: return "🎨"
        case .relationships: return "👥"
        case .finance: return "💰"
        case .learning: return "📚"
        case .personal: return "🌱"
        case .business: return "🚀"
        case .habit: return "🔄"
        case .fitness: return "🏋️‍♂️"
        case .skill: return "🎯"
        case .mindfulness: return "🧘‍♀️"
        }
    }
    
    var suggestedFrequencies: [GoalFrequency] {
        switch self {
        case .health, .habit, .mindfulness:
            return [.daily, .custom(6)]
        case .fitness:
            return [.thriceWeekly, .twiceWeekly, .daily]
        case .creativity, .skill, .learning:
            return [.thriceWeekly, .twiceWeekly, .weekly]
        case .career, .business, .finance:
            return [.weekly, .twiceWeekly, .daily]
        case .relationships, .personal:
            return [.weekly, .twiceWeekly, .daily]
        }
    }
}

// MARK: - Goal Milestones

struct GoalMilestone: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let targetWeek: Int // Week 1-12
    let targetDate: Date
    var isCompleted: Bool
    var completedDate: Date?
    let progressWeight: Double // 0.0 - 1.0 (how much this milestone contributes to overall progress)
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        targetWeek: Int,
        targetDate: Date,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        progressWeight: Double = 0.1
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetWeek = targetWeek
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.progressWeight = progressWeight
    }
    
    var isOverdue: Bool {
        return !isCompleted && Date() > targetDate
    }
    
    var daysUntilDue: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }
}

// MARK: - Weekly Goal Check-ins

struct WeeklyGoalCheckIn: Identifiable, Codable {
    let id: UUID
    let goalId: UUID
    let weekNumber: Int
    let startDate: Date
    let endDate: Date
    var progressRating: Int // 1-5 scale
    var progressDescription: String
    var challengesDescription: String
    var winsDescription: String
    var nextWeekFocus: String
    var moodAlignment: Double // How well mood supported goal progress this week
    let createdDate: Date
    var aiAnalysis: String?
    
    init(
        id: UUID = UUID(),
        goalId: UUID,
        weekNumber: Int,
        startDate: Date,
        endDate: Date,
        progressRating: Int = 3,
        progressDescription: String = "",
        challengesDescription: String = "",
        winsDescription: String = "",
        nextWeekFocus: String = "",
        moodAlignment: Double = 0.5,
        aiAnalysis: String? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.endDate = endDate
        self.progressRating = progressRating
        self.progressDescription = progressDescription
        self.challengesDescription = challengesDescription
        self.winsDescription = winsDescription
        self.nextWeekFocus = nextWeekFocus
        self.moodAlignment = moodAlignment
        self.createdDate = Date()
        self.aiAnalysis = aiAnalysis
    }
}

// MARK: - AI Context for Goals

struct GoalAIContext: Codable {
    let goalPersonality: String // How user talks about this goal
    let motivationFactors: [String] // What drives them toward this goal
    let commonObstacles: [String] // Patterns AI has identified
    let successPatterns: [String] // What works for this user
    let preferredCommunicationStyle: CommunicationStyle
    let accountabilityLevel: AccountabilityLevel
    var conversationHistory: [String] // Key insights from past AI conversations
    
    init(
        goalPersonality: String = "",
        motivationFactors: [String] = [],
        commonObstacles: [String] = [],
        successPatterns: [String] = [],
        preferredCommunicationStyle: CommunicationStyle = .encouraging,
        accountabilityLevel: AccountabilityLevel = .gentle,
        conversationHistory: [String] = []
    ) {
        self.goalPersonality = goalPersonality
        self.motivationFactors = motivationFactors
        self.commonObstacles = commonObstacles
        self.successPatterns = successPatterns
        self.preferredCommunicationStyle = preferredCommunicationStyle
        self.accountabilityLevel = accountabilityLevel
        self.conversationHistory = conversationHistory
    }
}

enum CommunicationStyle: String, CaseIterable, Codable {
    case encouraging = "encouraging"
    case direct = "direct"
    case analytical = "analytical"
    case motivational = "motivational"
    case gentle = "gentle"
    
    var description: String {
        switch self {
        case .encouraging: return "Supportive and positive"
        case .direct: return "Straight to the point"
        case .analytical: return "Data-driven insights"
        case .motivational: return "High energy and inspiring"
        case .gentle: return "Calm and understanding"
        }
    }
}

enum AccountabilityLevel: String, CaseIterable, Codable {
    case gentle = "gentle"
    case moderate = "moderate"
    case intense = "intense"
    
    var description: String {
        switch self {
        case .gentle: return "Light check-ins and encouragement"
        case .moderate: return "Regular accountability with helpful nudges"
        case .intense: return "Strong accountability with direct challenges"
        }
    }
}

// MARK: - Daily Goal Progress

struct DailyGoalProgress: Identifiable, Codable {
    let id: UUID
    let goalId: UUID
    let date: Date
    var progressRating: Int // 1-5 how much you worked toward goal today
    var progressNote: String
    var moodImpact: MoodImpact // How your mood affected goal progress
    var activitiesAligned: [String] // Which activities supported the goal
    let createdDate: Date
    
    init(
        id: UUID = UUID(),
        goalId: UUID,
        date: Date = Date(),
        progressRating: Int = 3,
        progressNote: String = "",
        moodImpact: MoodImpact = .neutral,
        activitiesAligned: [String] = []
    ) {
        self.id = id
        self.goalId = goalId
        self.date = date
        self.progressRating = progressRating
        self.progressNote = progressNote
        self.moodImpact = moodImpact
        self.activitiesAligned = activitiesAligned
        self.createdDate = Date()
    }
}

enum MoodImpact: String, CaseIterable, Codable {
    case veryNegative = "very_negative"
    case negative = "negative"
    case neutral = "neutral"
    case positive = "positive"
    case veryPositive = "very_positive"
    
    var displayName: String {
        switch self {
        case .veryNegative: return "Mood blocked progress"
        case .negative: return "Mood hindered progress"
        case .neutral: return "Mood had no impact"
        case .positive: return "Mood helped progress"
        case .veryPositive: return "Mood supercharged progress"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryNegative: return "🚫"
        case .negative: return "⬇️"
        case .neutral: return "➡️"
        case .positive: return "⬆️"
        case .veryPositive: return "🚀"
        }
    }
    
    var value: Double {
        switch self {
        case .veryNegative: return -1.0
        case .negative: return -0.5
        case .neutral: return 0.0
        case .positive: return 0.5
        case .veryPositive: return 1.0
        }
    }
}

// MARK: - Daily Brain Dump

struct DailyBrainDump: Identifiable, Codable {
    let id: UUID
    let date: Date
    var goalsWorkedOn: Set<UUID> // Goal IDs that were worked on today
    var brainDumpContent: String // Text or transcribed voice content
    var isVoiceNote: Bool // Whether this was originally a voice note
    var voiceNotePath: String? // Path to voice recording if applicable
    var wordCount: Int // For progress tracking
    var sentenceCount: Int // For progress tracking
    var isAIChatUnlocked: Bool // Whether they've written enough to unlock AI chat
    let createdDate: Date
    var lastModified: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        goalsWorkedOn: Set<UUID> = [],
        brainDumpContent: String = "",
        isVoiceNote: Bool = false,
        voiceNotePath: String? = nil
    ) {
        self.id = id
        self.date = date
        self.goalsWorkedOn = goalsWorkedOn
        self.brainDumpContent = brainDumpContent
        self.isVoiceNote = isVoiceNote
        self.voiceNotePath = voiceNotePath
        self.wordCount = Self.countWords(in: brainDumpContent)
        self.sentenceCount = Self.countSentences(in: brainDumpContent)
        self.isAIChatUnlocked = Self.checkAIUnlockThreshold(wordCount: self.wordCount, sentenceCount: self.sentenceCount)
        self.createdDate = Date()
        self.lastModified = Date()
    }
    
    // Update content and recalculate metrics
    mutating func updateContent(_ newContent: String, isVoice: Bool = false) {
        self.brainDumpContent = newContent
        self.isVoiceNote = isVoice
        self.wordCount = Self.countWords(in: newContent)
        self.sentenceCount = Self.countSentences(in: newContent)
        self.isAIChatUnlocked = Self.checkAIUnlockThreshold(wordCount: self.wordCount, sentenceCount: self.sentenceCount)
        self.lastModified = Date()
    }
    
    // Progress completion (0.0 to 1.0)
    var progressCompletion: Double {
        let targetSentences = 3.0
        let targetWords = 50.0
        
        let sentenceProgress = min(Double(sentenceCount) / targetSentences, 1.0)
        let wordProgress = min(Double(wordCount) / targetWords, 1.0)
        
        // Weight sentences more heavily than words
        return (sentenceProgress * 0.7) + (wordProgress * 0.3)
    }
    
    // Helper methods
    private static func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    private static func countSentences(in text: String) -> Int {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private static func checkAIUnlockThreshold(wordCount: Int, sentenceCount: Int) -> Bool {
        // Need at least 2 sentences AND 30 words to unlock AI chat
        return sentenceCount >= 2 && wordCount >= 30
    }
}

// MARK: - AI Chat Models

struct ChatSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let goalContext: [UUID] // Goal IDs that were worked on
    let brainDumpContext: String // User's reflection content
    let moodContext: String // User's mood for the day
    var messages: [ChatMessage]
    var sessionType: SessionType // New: tracks what kind of session this is
    var previousDayContext: PreviousDayContext? // New: context from yesterday
    let createdDate: Date
    var lastInteraction: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        goalContext: [UUID] = [],
        brainDumpContext: String = "",
        moodContext: String = "",
        messages: [ChatMessage] = [],
        sessionType: SessionType = .dailyReflection,
        previousDayContext: PreviousDayContext? = nil
    ) {
        self.id = id
        self.date = date
        self.goalContext = goalContext
        self.brainDumpContext = brainDumpContext
        self.moodContext = moodContext
        self.messages = messages
        self.sessionType = sessionType
        self.previousDayContext = previousDayContext
        self.createdDate = Date()
        self.lastInteraction = Date()
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        lastInteraction = Date()
    }
    
    // Get context summary for AI
    func getContextSummary(goals: [TwelveWeekGoal]) -> String {
        let relevantGoals = goals.filter { goalContext.contains($0.id) }
        let goalSummary = relevantGoals.map { "\($0.category.emoji) \($0.title)" }.joined(separator: ", ")
        
        return """
        Context for today's coaching session:
        
        📅 Date: \(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
        😊 Mood: \(moodContext)
        🎯 Goals worked on: \(goalSummary.isEmpty ? "None selected" : goalSummary)
        
        User's reflection:
        "\(brainDumpContext)"
        """
    }
}

enum SessionType: String, Codable {
    case dailyReflection = "daily_reflection"
    case nextDayAdvice = "next_day_advice"
    case goalCoaching = "goal_coaching"
    case checkIn = "check_in"
    
    var displayName: String {
        switch self {
        case .dailyReflection: return "Daily Reflection"
        case .nextDayAdvice: return "Morning Insights"
        case .goalCoaching: return "Goal Coaching"
        case .checkIn: return "Check-in Chat"
        }
    }
}

struct PreviousDayContext: Codable {
    let previousDate: Date
    let previousMood: String
    let previousGoals: [UUID]
    let previousReflection: String
    let previousChallenges: [String] // Extracted challenges from reflection
    let previousWins: [String] // Extracted wins from reflection
    let moodTrend: MoodTrend // How mood is trending
    
    init(
        previousDate: Date,
        previousMood: String,
        previousGoals: [UUID],
        previousReflection: String,
        previousChallenges: [String] = [],
        previousWins: [String] = [],
        moodTrend: MoodTrend = .stable
    ) {
        self.previousDate = previousDate
        self.previousMood = previousMood
        self.previousGoals = previousGoals
        self.previousReflection = previousReflection
        self.previousChallenges = previousChallenges
        self.previousWins = previousWins
        self.moodTrend = moodTrend
    }
}

enum MoodTrend: String, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    case volatile = "volatile"
    
    var description: String {
        switch self {
        case .improving: return "Your mood has been improving"
        case .declining: return "Your mood has been declining"
        case .stable: return "Your mood has been stable"
        case .volatile: return "Your mood has been variable"
        }
    }
    
    var advice: String {
        switch self {
        case .improving: return "Keep up the momentum!"
        case .declining: return "Let's focus on small wins today"
        case .stable: return "Consistency is great - let's build on it"
        case .volatile: return "Let's find some stability in your routine"
        }
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let type: MessageType
    let timestamp: Date
    var isTyping: Bool // For AI typing animation
    var messageContext: MessageContext? // New: additional context for AI responses
    
    init(
        id: UUID = UUID(),
        content: String,
        type: MessageType,
        timestamp: Date = Date(),
        isTyping: Bool = false,
        messageContext: MessageContext? = nil
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.isTyping = isTyping
        self.messageContext = messageContext
    }
}

struct MessageContext: Codable {
    let intentType: IntentType // What the AI is trying to do
    let confidence: Double // How confident the AI is (0.0-1.0)
    let goalReferences: [UUID] // Which goals this message references
    let actionSuggestions: [String] // Specific actions suggested
    
    init(
        intentType: IntentType = .general,
        confidence: Double = 0.8,
        goalReferences: [UUID] = [],
        actionSuggestions: [String] = []
    ) {
        self.intentType = intentType
        self.confidence = confidence
        self.goalReferences = goalReferences
        self.actionSuggestions = actionSuggestions
    }
}

enum IntentType: String, Codable {
    case general = "general"
    case encouragement = "encouragement"
    case accountability = "accountability"
    case advice = "advice"
    case celebration = "celebration"
    case problem_solving = "problem_solving"
    case goal_adjustment = "goal_adjustment"
    
    var description: String {
        switch self {
        case .general: return "General conversation"
        case .encouragement: return "Providing encouragement"
        case .accountability: return "Holding accountable"
        case .advice: return "Giving advice"
        case .celebration: return "Celebrating wins"
        case .problem_solving: return "Problem solving"
        case .goal_adjustment: return "Adjusting goals"
        }
    }
}

enum MessageType: String, Codable {
    case user = "user"
    case ai = "ai"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .user: return "You"
        case .ai: return "AI Coach"
        case .system: return "System"
        }
    }
    
    var backgroundColor: String {
        switch self {
        case .user: return "#007AFF"    // Blue
        case .ai: return "#34C759"      // Green
        case .system: return "#8E8E93"  // Gray
        }
    }
}