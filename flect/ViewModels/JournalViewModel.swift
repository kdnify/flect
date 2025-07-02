import Foundation
import SwiftUI

@MainActor
class JournalViewModel: ObservableObject {
    @Published var journalEntries: [JournalEntry] = []
    @Published var tasks: [TaskItem] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let aiService: AIServiceProtocol
    private let storageService: StorageServiceProtocol
    
    init(aiService: AIServiceProtocol = AIService.shared, storageService: StorageServiceProtocol = StorageService.shared) {
        self.aiService = aiService
        self.storageService = storageService
        loadData()
    }
    
    // MARK: - Journal Entry Management
    
    func createJournalEntry(from brainDump: String, mood: Mood) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            let entry = try await aiService.generateJournalEntry(from: brainDump, mood: mood)
            journalEntries.insert(entry, at: 0)
            
            // Add extracted tasks to the main task list
            for task in entry.extractedTasks {
                if !tasks.contains(where: { $0.title == task.title }) {
                    tasks.append(task)
                }
            }
            
            saveData()
        } catch {
            errorMessage = "Failed to create journal entry: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    func updateJournalEntry(_ entry: JournalEntry) {
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = entry
            saveData()
        }
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) {
        journalEntries.removeAll { $0.id == entry.id }
        saveData()
    }
    
    // MARK: - Task Management
    
    func toggleTaskCompletion(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveData()
        }
    }
    
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveData()
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveData()
    }
    
    func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveData()
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        journalEntries = storageService.loadJournalEntries()
        tasks = storageService.loadTasks()
    }
    
    private func saveData() {
        storageService.saveJournalEntries(journalEntries)
        storageService.saveTasks(tasks)
    }
    
    // MARK: - Computed Properties
    
    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }
    
    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
    }
    
    var recentEntries: [JournalEntry] {
        Array(journalEntries.prefix(5))
    }
    
    var todaysEntry: JournalEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return journalEntries.first { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: today)
        }
    }
} 