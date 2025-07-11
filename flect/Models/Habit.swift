import Foundation

struct Habit: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: TaskCategory
    let frequency: HabitFrequency
    let timeOfDay: HabitTimeOfDay
    let source: HabitSource
    let goalId: UUID?
    let createdAt: Date
    var updatedAt: Date
    var lastCompletedAt: Date?
    var currentStreak: Int
    var longestStreak: Int
    var completionHistory: [HabitCompletion]
    var isArchived: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: TaskCategory,
        frequency: HabitFrequency,
        timeOfDay: HabitTimeOfDay,
        source: HabitSource,
        goalId: UUID? = nil,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.frequency = frequency
        self.timeOfDay = timeOfDay
        self.source = source
        self.goalId = goalId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastCompletedAt = nil
        self.currentStreak = 0
        self.longestStreak = 0
        self.completionHistory = []
        self.isArchived = isArchived
    }
    
    // MARK: - Computed Properties
    
    var completionRate: Double {
        guard !completionHistory.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = Date()
        let startDate = createdAt
        let totalDays = calendar.dateComponents([.day], from: startDate, to: today).day! + 1
        let completedDays = completionHistory.count
        return Double(completedDays) / Double(totalDays)
    }
    
    var isCompletedToday: Bool {
        guard let lastCompletion = lastCompletedAt else { return false }
        return Calendar.current.isDate(lastCompletion, inSameDayAs: Date())
    }
    
    var nextDueDate: Date? {
        guard let lastCompletion = lastCompletedAt else { return Date() }
        let calendar = Calendar.current
        
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: lastCompletion)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: lastCompletion)
        case .weekdays:
            var nextDate = calendar.date(byAdding: .day, value: 1, to: lastCompletion)!
            while calendar.component(.weekday, from: nextDate) == 1 ||
                  calendar.component(.weekday, from: nextDate) == 7 {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
            }
            return nextDate
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: lastCompletion)
        }
    }
    
    var isOverdue: Bool {
        guard let dueDate = nextDueDate else { return false }
        return dueDate < Date()
    }
    
    // MARK: - Mutating Methods
    
    mutating func completeHabit() {
        let now = Date()
        let completion = HabitCompletion(date: now)
        
        lastCompletedAt = now
        completionHistory.append(completion)
        updatedAt = now
        
        updateStreak()
    }
    
    private mutating func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        // Sort completions by date
        let sortedCompletions = completionHistory.sorted { $0.date > $1.date }
        
        // Calculate current streak
        var streak = 0
        var lastDate = today
        
        for completion in sortedCompletions {
            let dayDifference = calendar.dateComponents([.day], from: completion.date, to: lastDate).day ?? 0
            
            // Check if the completion maintains the streak based on frequency
            let maintainsStreak: Bool
            switch frequency {
            case .daily:
                maintainsStreak = dayDifference <= 1
            case .weekly:
                maintainsStreak = dayDifference <= 7
            case .weekdays:
                let weekday = calendar.component(.weekday, from: completion.date)
                let isWeekend = weekday == 1 || weekday == 7
                maintainsStreak = isWeekend ? dayDifference <= 3 : dayDifference <= 1
            case .monthly:
                maintainsStreak = dayDifference <= 31
            }
            
            if maintainsStreak {
                streak += 1
                lastDate = completion.date
            } else {
                break
            }
        }
        
        currentStreak = streak
        longestStreak = max(longestStreak, currentStreak)
    }
}

// MARK: - Supporting Types

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case weekdays = "weekdays"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .weekdays: return "Weekdays"
        case .monthly: return "Monthly"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "calendar.day.timeline.left"
        case .weekly: return "calendar.badge.clock"
        case .weekdays: return "calendar.badge.exclamationmark"
        case .monthly: return "calendar.circle"
        }
    }
}

enum HabitTimeOfDay: String, Codable, CaseIterable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case anytime = "anytime"
    
    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .anytime: return "Anytime"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise"
        case .afternoon: return "sun.max"
        case .evening: return "moon.stars"
        case .anytime: return "clock"
        }
    }
    
    var hour: Int {
        switch self {
        case .morning: return 9
        case .afternoon: return 14
        case .evening: return 19
        case .anytime: return 12
        }
    }
}

enum HabitSource: String, Codable, CaseIterable {
    case manual = "manual"
    case aiSuggested = "ai_suggested"
    case goalDerived = "goal_derived"
    case patternBased = "pattern_based"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .aiSuggested: return "AI Suggested"
        case .goalDerived: return "Goal Derived"
        case .patternBased: return "Pattern Based"
        }
    }
    
    var icon: String {
        switch self {
        case .manual: return "person.fill"
        case .aiSuggested: return "brain.head.profile"
        case .goalDerived: return "target"
        case .patternBased: return "chart.line.uptrend.xyaxis"
        }
    }
}

struct HabitCompletion: Codable {
    let date: Date
    let note: String?
    
    init(date: Date = Date(), note: String? = nil) {
        self.date = date
        self.note = note
    }
} 