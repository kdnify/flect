import Foundation

protocol StorageServiceProtocol {
    func saveJournalEntries(_ entries: [JournalEntry])
    func loadJournalEntries() -> [JournalEntry]
    func saveTasks(_ tasks: [TaskItem])
    func loadTasks() -> [TaskItem]
    func clearAllData()
}

class StorageService: StorageServiceProtocol {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    private let journalEntriesKey = "flect_journal_entries"
    private let tasksKey = "flect_tasks"
    
    private init() {}
    
    // MARK: - Journal Entries
    
    func saveJournalEntries(_ entries: [JournalEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            userDefaults.set(data, forKey: journalEntriesKey)
        } catch {
            print("Failed to save journal entries: \(error)")
        }
    }
    
    func loadJournalEntries() -> [JournalEntry] {
        guard let data = userDefaults.data(forKey: journalEntriesKey) else {
            return createSampleData()
        }
        
        do {
            return try JSONDecoder().decode([JournalEntry].self, from: data)
        } catch {
            print("Failed to load journal entries: \(error)")
            return createSampleData()
        }
    }
    
    // MARK: - Tasks
    
    func saveTasks(_ tasks: [TaskItem]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            userDefaults.set(data, forKey: tasksKey)
        } catch {
            print("Failed to save tasks: \(error)")
        }
    }
    
    func loadTasks() -> [TaskItem] {
        guard let data = userDefaults.data(forKey: tasksKey) else {
            return createSampleTasks()
        }
        
        do {
            return try JSONDecoder().decode([TaskItem].self, from: data)
        } catch {
            print("Failed to load tasks: \(error)")
            return createSampleTasks()
        }
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        userDefaults.removeObject(forKey: journalEntriesKey)
        userDefaults.removeObject(forKey: tasksKey)
    }
    
    // MARK: - Sample Data for Testing
    
    private func createSampleData() -> [JournalEntry] {
        let sampleTasks = [
            TaskItem(title: "Review quarterly goals", priority: .high),
            TaskItem(title: "Call mom", priority: .medium)
        ]
        
        let sampleEntry = JournalEntry(
            date: Date().addingTimeInterval(-86400), // Yesterday
            mood: .focused,
            reflection: "Yesterday was productive. I managed to organize my thoughts and tackle some important tasks. The brain dump approach really helps me see the big picture.",
            progressNotes: "Identified key priorities and made good progress on planning. Feeling more organized and clear about next steps.",
            extractedTasks: sampleTasks,
            originalBrainDump: "Need to review quarterly goals and make sure I'm on track. Also should call mom, haven't talked to her in a while. Feeling pretty focused today and want to make progress on key projects."
        )
        
        return [sampleEntry]
    }
    
    private func createSampleTasks() -> [TaskItem] {
        return [
            TaskItem(title: "Review quarterly goals", priority: .high),
            TaskItem(title: "Call mom", priority: .medium),
            TaskItem(title: "Plan weekend activities", isCompleted: true, priority: .low)
        ]
    }
} 