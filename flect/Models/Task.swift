import Foundation

struct Task: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String?
    let priority: TaskPriority
    var dueDate: Date?
    var isCompleted: Bool
    let goalId: UUID?
    let sprintId: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        goalId: UUID? = nil,
        sprintId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.goalId = goalId
        self.sprintId = sprintId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: String {
        switch self {
        case .high: return "#FF4B4B"
        case .medium: return "#FFA500"
        case .low: return "#4CAF50"
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "flag.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Task Sorting & Filtering

extension Task {
    static func sortByPriority(_ tasks: [Task]) -> [Task] {
        tasks.sorted { task1, task2 in
            let priorityOrder: [TaskPriority] = [.high, .medium, .low]
            let index1 = priorityOrder.firstIndex(of: task1.priority) ?? 0
            let index2 = priorityOrder.firstIndex(of: task2.priority) ?? 0
            return index1 < index2
        }
    }
    
    static func sortByDueDate(_ tasks: [Task]) -> [Task] {
        tasks.sorted { task1, task2 in
            guard let date1 = task1.dueDate else { return false }
            guard let date2 = task2.dueDate else { return true }
            return date1 < date2
        }
    }
    
    static func filterByGoal(_ tasks: [Task], goalId: UUID?) -> [Task] {
        tasks.filter { $0.goalId == goalId }
    }
    
    static func filterBySprint(_ tasks: [Task], sprintId: UUID?) -> [Task] {
        tasks.filter { $0.sprintId == sprintId }
    }
    
    static func filterByCompletion(_ tasks: [Task], isCompleted: Bool) -> [Task] {
        tasks.filter { $0.isCompleted == isCompleted }
    }
} 