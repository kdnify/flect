import Foundation

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var priority: TaskPriority
    let dateCreated: Date
    var dueDate: Date?
    
    init(title: String, isCompleted: Bool = false, priority: TaskPriority = .medium, dateCreated: Date = Date(), dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
        self.dateCreated = dateCreated
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
        case .low: return "mediumGrey"
        case .medium: return "accent"
        case .high: return "error"
        }
    }
} 