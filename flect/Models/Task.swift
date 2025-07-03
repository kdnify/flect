import Foundation

struct TaskModel: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: TaskPriority
    let createdAt: Date
    var updatedAt: Date
    var dueDate: Date?
    
    init(id: UUID = UUID(), title: String, description: String = "", isCompleted: Bool = false, priority: TaskPriority = .medium, dueDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = Date()
        self.updatedAt = Date()
        self.dueDate = dueDate
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#4CAF50"
        case .medium: return "#FF9800"
        case .high: return "#F44336"
        }
    }
}

// MARK: - Legacy Support
typealias Task = TaskModel
typealias TaskItem = TaskModel 