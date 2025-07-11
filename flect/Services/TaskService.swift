import Foundation
import Combine

class TaskService: ObservableObject {
    static let shared = TaskService()
    
    @Published var allTasks: [AppTask] = []
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "user_tasks"
    
    private init() {
        loadTasks()
    }
    
    // MARK: - Task Management
    
    func extractTasksFromConversation(_ conversation: [ChatMessage]) -> [AppTask] {
        var extractedTasks: [AppTask] = []
        
        for message in conversation {
            if message.type == .ai {
                // Look for task indicators in AI responses
                let taskPatterns = [
                    "task:", "todo:", "action item:", "need to:", "should:", "must:", "have to:",
                    "•", "✓", "☐", "□", "- [ ]", "- [x]", "1.", "2.", "3."
                ]
                
                let lines = message.content.components(separatedBy: .newlines)
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Check if line contains task indicators
                    let isTaskLine = taskPatterns.contains { pattern in
                        trimmedLine.lowercased().contains(pattern.lowercased())
                    }
                    
                    if isTaskLine && trimmedLine.count > 10 {
                        // Extract task title (remove task indicators)
                        var taskTitle = trimmedLine
                        for pattern in taskPatterns {
                            taskTitle = taskTitle.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
                        }
                        taskTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !taskTitle.isEmpty {
                            let task = AppTask(
                                title: taskTitle,
                                description: "Extracted from AI conversation",
                                priority: determinePriority(from: trimmedLine),
                                category: determineCategory(from: trimmedLine),
                                source: .aiConversation
                            )
                            extractedTasks.append(task)
                        }
                    }
                }
            }
        }
        
        return extractedTasks
    }
    
    func addTask(_ task: AppTask) {
        allTasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: AppTask) {
        if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
            allTasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(_ taskId: UUID) {
        allTasks.removeAll { $0.id == taskId }
        saveTasks()
    }
    
    func completeTask(_ taskId: UUID) {
        if let index = allTasks.firstIndex(where: { $0.id == taskId }) {
            allTasks[index].isCompleted = true
            allTasks[index].completedDate = Date()
            saveTasks()
        }
    }
    
    func getTasksByCategory(_ category: TaskCategory) -> [AppTask] {
        return allTasks.filter { $0.category == category }
    }
    
    func getTasksByPriority(_ priority: TaskPriority) -> [AppTask] {
        return allTasks.filter { $0.priority == priority }
    }
    
    func getActiveTasks() -> [AppTask] {
        return allTasks.filter { !$0.isCompleted }
    }
    
    func getCompletedTasks() -> [AppTask] {
        return allTasks.filter { $0.isCompleted }
    }
    
    func getTasksForDate(_ date: Date) -> [AppTask] {
        let calendar = Calendar.current
        return allTasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: date)
            }
            return false
        }
    }
    
    // MARK: - Task Analytics
    
    func getTaskAnalytics() -> TaskAnalytics {
        let activeTasks = getActiveTasks()
        let completedTasks = getCompletedTasks()
        let totalTasks = allTasks.count
        
        let completionRate = totalTasks > 0 ? Double(completedTasks.count) / Double(totalTasks) : 0.0
        
        // Calculate average completion time
        let completedWithDate = completedTasks.filter { $0.completedDate != nil }
        let averageCompletionTime: TimeInterval? = completedWithDate.isEmpty ? nil : {
            let totalTime = completedWithDate.reduce(0) { total, task in
                guard let completedDate = task.completedDate else { return total }
                return total + completedDate.timeIntervalSince(task.createdDate)
            }
            return totalTime / Double(completedWithDate.count)
        }()
        
        // Category breakdown
        let categoryBreakdown = TaskCategory.allCases.map { category in
            let categoryTasks = getTasksByCategory(category)
            let completedInCategory = categoryTasks.filter { $0.isCompleted }.count
            return CategoryBreakdown(
                category: category,
                totalTasks: categoryTasks.count,
                completedTasks: completedInCategory,
                completionRate: categoryTasks.count > 0 ? Double(completedInCategory) / Double(categoryTasks.count) : 0.0
            )
        }
        
        // Priority breakdown
        let priorityBreakdown = TaskPriority.allCases.map { priority in
            let priorityTasks = getTasksByPriority(priority)
            let completedInPriority = priorityTasks.filter { $0.isCompleted }.count
            return PriorityBreakdown(
                priority: priority,
                totalTasks: priorityTasks.count,
                completedTasks: completedInPriority,
                completionRate: priorityTasks.count > 0 ? Double(completedInPriority) / Double(priorityTasks.count) : 0.0
            )
        }
        
        return TaskAnalytics(
            totalTasks: totalTasks,
            activeTasks: activeTasks.count,
            completedTasks: completedTasks.count,
            completionRate: completionRate,
            averageCompletionTime: averageCompletionTime,
            categoryBreakdown: categoryBreakdown,
            priorityBreakdown: priorityBreakdown
        )
    }
    
    // MARK: - Helper Methods
    
    private func determinePriority(from text: String) -> TaskPriority {
        let lowercased = text.lowercased()
        
        if lowercased.contains("urgent") || lowercased.contains("asap") || lowercased.contains("critical") {
            return .high
        } else if lowercased.contains("important") || lowercased.contains("priority") {
            return .medium
        } else {
            return .low
        }
    }
    
    private func determineCategory(from text: String) -> TaskCategory {
        let lowercased = text.lowercased()
        
        if lowercased.contains("work") || lowercased.contains("job") || lowercased.contains("career") {
            return .work
        } else if lowercased.contains("health") || lowercased.contains("exercise") || lowercased.contains("fitness") {
            return .health
        } else if lowercased.contains("learn") || lowercased.contains("study") || lowercased.contains("read") {
            return .learning
        } else if lowercased.contains("relationship") || lowercased.contains("friend") || lowercased.contains("family") {
            return .relationships
        } else if lowercased.contains("finance") || lowercased.contains("money") || lowercased.contains("budget") {
            return .finance
        } else if lowercased.contains("mindfulness") || lowercased.contains("meditation") || lowercased.contains("wellness") {
            return .mindfulness
        } else {
            return .personal
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(allTasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        guard let data = userDefaults.data(forKey: tasksKey),
              let tasks = try? JSONDecoder().decode([AppTask].self, from: data) else {
            return
        }
        
        allTasks = tasks
    }
    
    // MARK: - Mock Data for Testing
    
    func createMockTasks() {
        let mockTasks = [
            AppTask(
                title: "Complete project presentation",
                description: "Finish the quarterly project presentation for the team meeting",
                priority: .high,
                category: .work,
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                source: .manual
            ),
            AppTask(
                title: "Go for a 30-minute walk",
                description: "Daily exercise routine to maintain health",
                priority: .medium,
                category: .health,
                dueDate: Date(),
                source: .manual
            ),
            AppTask(
                title: "Read chapter 5 of SwiftUI book",
                description: "Continue learning iOS development",
                priority: .medium,
                category: .learning,
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                source: .manual
            ),
            AppTask(
                title: "Call mom",
                description: "Weekly check-in with family",
                priority: .low,
                category: .relationships,
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                source: .manual
            )
        ]
        
        allTasks.append(contentsOf: mockTasks)
        saveTasks()
    }
}

// MARK: - Data Models

struct AppTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let priority: TaskPriority
    let category: TaskCategory
    let dueDate: Date?
    let estimatedHours: Double?
    let source: TaskSource
    let createdDate: Date
    var isCompleted: Bool
    var completedDate: Date?
    var notes: String?
    
    init(
        title: String,
        description: String,
        priority: TaskPriority = .medium,
        category: TaskCategory = .personal,
        dueDate: Date? = nil,
        estimatedHours: Double? = nil,
        source: TaskSource = .manual,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.dueDate = dueDate
        self.estimatedHours = estimatedHours
        self.source = source
        self.createdDate = Date()
        self.isCompleted = false
        self.completedDate = nil
        self.notes = notes
    }
}

enum TaskCategory: String, CaseIterable, Codable {
    case work = "work"
    case health = "health"
    case learning = "learning"
    case relationships = "relationships"
    case finance = "finance"
    case mindfulness = "mindfulness"
    case personal = "personal"
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .health: return "Health"
        case .learning: return "Learning"
        case .relationships: return "Relationships"
        case .finance: return "Finance"
        case .mindfulness: return "Mindfulness"
        case .personal: return "Personal"
        }
    }
    
    var emoji: String {
        switch self {
        case .work: return "💼"
        case .health: return "🏃‍♂️"
        case .learning: return "📚"
        case .relationships: return "❤️"
        case .finance: return "💰"
        case .mindfulness: return "🧘‍♀️"
        case .personal: return "👤"
        }
    }
    
    var color: String {
        switch self {
        case .work: return "#4A90E2"
        case .health: return "#7ED321"
        case .learning: return "#F5A623"
        case .relationships: return "#D0021B"
        case .finance: return "#50E3C2"
        case .mindfulness: return "#9013FE"
        case .personal: return "#8B572A"
        }
    }
}

enum TaskSource: String, CaseIterable, Codable {
    case manual = "manual"
    case aiConversation = "ai_conversation"
    case sprintPlanning = "sprint_planning"
    case goalBreakdown = "goal_breakdown"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .aiConversation: return "AI Conversation"
        case .sprintPlanning: return "Sprint Planning"
        case .goalBreakdown: return "Goal Breakdown"
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable {
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
        case .high: return "#FF6B6B"
        case .medium: return "#4ECDC4"
        case .low: return "#95A5A6"
        }
    }
    
    var emoji: String {
        switch self {
        case .high: return "🔴"
        case .medium: return "🟡"
        case .low: return "🟢"
        }
    }
}



struct TaskAnalytics {
    let totalTasks: Int
    let activeTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let averageCompletionTime: TimeInterval?
    let categoryBreakdown: [CategoryBreakdown]
    let priorityBreakdown: [PriorityBreakdown]
}

struct CategoryBreakdown {
    let category: TaskCategory
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
}

struct PriorityBreakdown {
    let priority: TaskPriority
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
} 