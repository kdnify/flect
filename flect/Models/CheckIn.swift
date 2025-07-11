import Foundation

// MARK: - Daily Check-in Models

struct DailyCheckIn: Identifiable, Codable {
    let id: UUID
    let date: Date
    let happyThing: String
    let improveThing: String
    let moodEmoji: String
    let completionState: CheckInState
    let aiResponse: String?
    let aiQuestionAsked: String?
    var followUpCompleted: Bool
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        happyThing: String,
        improveThing: String,
        moodEmoji: String = "😌",
        completionState: CheckInState = .completed,
        aiResponse: String? = nil,
        aiQuestionAsked: String? = nil,
        followUpCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.happyThing = happyThing
        self.improveThing = improveThing
        self.moodEmoji = moodEmoji
        self.completionState = completionState
        self.aiResponse = aiResponse
        self.aiQuestionAsked = aiQuestionAsked
        self.followUpCompleted = followUpCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Helper properties
    var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    var hasAIResponse: Bool {
        aiResponse != nil && !aiResponse!.isEmpty
    }
}

enum CheckInState: String, CaseIterable, Codable {
    case pending = "pending"
    case completed = "completed"
    case followUpPending = "follow_up_pending"
    case followUpCompleted = "follow_up_completed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .followUpPending: return "Follow-up Pending"
        case .followUpCompleted: return "Follow-up Completed"
        }
    }
}

// MARK: - User Insights Models

struct UserInsight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double // 0.0 - 1.0
    let dataPoints: Int
    let createdAt: Date
    let validUntil: Date?
    var isActive: Bool
    let metadata: InsightMetadata?
    
    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        description: String,
        confidence: Double,
        dataPoints: Int,
        validUntil: Date? = nil,
        isActive: Bool = true,
        metadata: InsightMetadata? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.dataPoints = dataPoints
        self.createdAt = Date()
        self.validUntil = validUntil
        self.isActive = isActive
        self.metadata = metadata
    }
    
    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.8...1.0: return .high
        case 0.6..<0.8: return .medium
        default: return .low
        }
    }
    
    var isExpired: Bool {
        guard let validUntil = validUntil else { return false }
        return Date() > validUntil
    }
}

enum InsightType: String, CaseIterable, Codable {
    case pattern = "pattern"
    case correlation = "correlation" 
    case prediction = "prediction"
    case suggestion = "suggestion"
    case milestone = "milestone"
    case streak = "streak"
    
    var displayName: String {
        switch self {
        case .pattern: return "Pattern"
        case .correlation: return "Connection"
        case .prediction: return "Prediction"
        case .suggestion: return "Suggestion"
        case .milestone: return "Milestone"
        case .streak: return "Streak"
        }
    }
    
    var icon: String {
        switch self {
        case .pattern: return "chart.line.uptrend.xyaxis"
        case .correlation: return "link"
        case .prediction: return "crystal.ball"
        case .suggestion: return "lightbulb"
        case .milestone: return "flag"
        case .streak: return "flame"
        }
    }
}

enum ConfidenceLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Emerging Pattern"
        case .medium: return "Likely Pattern"
        case .high: return "Strong Pattern"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#FFC107"
        case .medium: return "#FF9800" 
        case .high: return "#4CAF50"
        }
    }
    
    var value: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
}

struct InsightMetadata: Codable {
    let relatedCheckInIds: [UUID]?
    let keywords: [String]?
    let frequencyData: [String: Int]?
    let timePatterns: [String: String]?  // Changed from Any to String for Codable compatibility
    
    init(
        relatedCheckInIds: [UUID]? = nil,
        keywords: [String]? = nil,
        frequencyData: [String: Int]? = nil,
        timePatterns: [String: String]? = nil
    ) {
        self.relatedCheckInIds = relatedCheckInIds
        self.keywords = keywords
        self.frequencyData = frequencyData
        self.timePatterns = timePatterns
    }
}

// MARK: - Progressive Engagement Models

struct UserEngagementLevel: Codable {
    let daysSinceInstall: Int
    let totalCheckIns: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageCheckInsPerWeek: Double
    
    var level: EngagementTier {
        switch (daysSinceInstall, totalCheckIns) {
        case (0...7, _):
            return .newcomer
        case (8...30, 5...):
            return .exploring
        case (31...90, 20...):
            return .engaged
        case (91..., 50...):
            return .committed
        default:
            return .newcomer
        }
    }
    
    var shouldGetSmartQuestions: Bool {
        return level.rawValue >= EngagementTier.exploring.rawValue && totalCheckIns >= 5
    }
    
    var shouldGetDeepInsights: Bool {
        return level.rawValue >= EngagementTier.engaged.rawValue && totalCheckIns >= 20
    }
}

enum EngagementTier: Int, CaseIterable, Codable {
    case newcomer = 0
    case exploring = 1
    case engaged = 2
    case committed = 3
    
    var displayName: String {
        switch self {
        case .newcomer: return "Getting Started"
        case .exploring: return "Exploring Patterns"
        case .engaged: return "Building Habits"
        case .committed: return "Self-Aware"
        }
    }
    
    var description: String {
        switch self {
        case .newcomer: return "Welcome! Just focus on daily check-ins."
        case .exploring: return "I'm starting to notice patterns in your responses."
        case .engaged: return "Let's dive deeper into your behavioral insights."
        case .committed: return "You've unlocked advanced personal intelligence."
        }
    }
} 