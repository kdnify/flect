import Foundation

struct Sprint: Identifiable, Codable {
    let id: UUID
    let goalId: UUID
    let title: String
    var description: String
    let startDate: Date
    let endDate: Date
    let weekNumber: Int // 1-4 for the 4-week sprint
    var targetMilestones: [SprintMilestone]
    var currentProgress: Double // 0.0 to 1.0
    var isCompleted: Bool
    var completedDate: Date?
    var tasks: [SprintTask]
    
    init(
        goalId: UUID,
        title: String,
        description: String,
        startDate: Date,
        weekNumber: Int,
        targetMilestones: [SprintMilestone] = []
    ) {
        self.id = UUID()
        self.goalId = goalId
        self.title = title
        self.description = description
        self.startDate = startDate
        self.weekNumber = weekNumber
        
        // Calculate end date (4 weeks from start)
        let calendar = Calendar.current
        self.endDate = calendar.date(byAdding: .weekOfYear, value: 4, to: startDate) ?? startDate
        
        self.targetMilestones = targetMilestones
        self.currentProgress = 0.0
        self.isCompleted = false
        self.completedDate = nil
        self.tasks = []
    }
    
    var progressPercentage: Int {
        return Int(currentProgress * 100)
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        let remaining = calendar.dateComponents([.day], from: today, to: endDate)
        return max(0, remaining.day ?? 0)
    }
    
    var isActive: Bool {
        let today = Date()
        return today >= startDate && today <= endDate && !isCompleted
    }
    
    var isOverdue: Bool {
        let today = Date()
        return today > endDate && !isCompleted
    }
}

struct SprintMilestone: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    let targetDate: Date
    var isCompleted: Bool
    var completedDate: Date?
    
    init(title: String, description: String, targetDate: Date) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.isCompleted = false
        self.completedDate = nil
    }
}

struct SprintTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let priority: TaskPriority
    let dueDate: Date?
    var isCompleted: Bool
    var completedDate: Date?
    let estimatedHours: Double?
    
    init(
        title: String,
        description: String,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        estimatedHours: Double? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = false
        self.completedDate = nil
        self.estimatedHours = estimatedHours
    }
}



// MARK: - AI Sprint Suggestions

struct SprintSuggestion {
    let weekNumber: Int
    let title: String
    let description: String
    let suggestedMilestones: [String]
    let estimatedTasks: [String]
    let focusAreas: [String]
}

// MARK: - Sprint Analytics

struct SprintAnalytics {
    let sprint: Sprint
    let tasksCompleted: Int
    let totalTasks: Int
    let averageTaskCompletionTime: TimeInterval?
    let mostProductiveDay: String?
    let completionRate: Double
    let daysAheadOfSchedule: Int?
    let daysBehindSchedule: Int?
    
    var taskCompletionPercentage: Int {
        guard totalTasks > 0 else { return 0 }
        return Int((Double(tasksCompleted) / Double(totalTasks)) * 100)
    }
} 