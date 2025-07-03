import Foundation
import SwiftUI

@MainActor
class JournalViewModel: ObservableObject {
    @Published var journalEntries: [JournalEntry] = []
    @Published var tasks: [TaskItem] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var processingStatus = "Ready"
    
    private let aiService = AIService.shared
    private let storageService = StorageService.shared
    
    init() {
        loadData()
    }
    
    // MARK: - Brain Dump Processing (New Primary Method)
    
    func processBrainDump(_ text: String, mood: String? = nil) async {
        print("🔍 DEBUG: Starting processBrainDump with text: \(text.prefix(50))...")
        print("🔍 DEBUG: Mood parameter: \(mood ?? "nil")")
        print("🔍 DEBUG: Current journalEntries count: \(journalEntries.count)")
        
        isProcessing = true
        errorMessage = nil
        processingStatus = "Processing with AI..."
        
        do {
            let entry = try await aiService.processText(text, mood: mood)
            
            print("🔍 DEBUG: AI processing completed, entry title: \(entry.title)")
            print("🔍 DEBUG: Original entry mood: \(entry.mood ?? "nil")")
            
            // Create a new entry with the provided mood if it's not already set
            var finalEntry = entry
            if entry.mood == nil && mood != nil {
                finalEntry = JournalEntry(
                    id: entry.id,
                    date: entry.date,
                    originalText: entry.originalText,
                    processedContent: entry.processedContent,
                    title: entry.title,
                    mood: mood,
                    tasks: entry.tasks
                )
                print("🔍 DEBUG: Updated entry with mood: \(mood!)")
            }
            
            // Insert at the beginning for most recent first
            var entries = storageService.loadJournalEntries()
            entries.insert(finalEntry, at: 0)
            
            print("🔍 DEBUG: Added entry to journalEntries, new count: \(entries.count)")
            
            // Add extracted tasks to the main task list
            for task in finalEntry.tasks {
                let taskItem = TaskItem(
                    title: task.title,
                    isCompleted: task.isCompleted,
                    priority: task.priority
                )
                if !tasks.contains(where: { $0.title == taskItem.title }) {
                    tasks.append(taskItem)
                }
            }
            
            print("🔍 DEBUG: Added \(finalEntry.tasks.count) tasks, total tasks: \(tasks.count)")
            
            // Save to storage
            storageService.saveJournalEntries(entries)
            storageService.saveTasks(tasks)
            
            print("🔍 DEBUG: Saved to storage")
            
            // Update the published property
            journalEntries = entries
            
            print("🔍 DEBUG: Updated journalEntries property")
            
            processingStatus = "Processing complete!"
            
        } catch {
            print("🔍 DEBUG: Error occurred: \(error)")
            errorMessage = "Failed to process brain dump: \(error.localizedDescription)"
            processingStatus = "Processing failed"
        }
        
        isProcessing = false
        
        // Reset status after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.processingStatus = "Ready"
        }
    }
    
    // MARK: - Journal Entry Management (Legacy)
    
    func createJournalEntry(from brainDump: String, mood: Mood) async {
        print("🔍 DEBUG: createJournalEntry called with mood: \(mood.rawValue)")
        // Pass the mood to the processing method
        await processBrainDump(brainDump, mood: mood.rawValue)
    }
    
    func updateJournalEntry(_ entry: JournalEntry) {
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = entry
        }
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) {
        journalEntries.removeAll { $0.id == entry.id }
    }
    
    // MARK: - Task Management
    
    func toggleTaskCompletion(_ task: TaskItem) async {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            // Update in local storage
            storageService.saveTasks(tasks)
        }
    }
    
    func addTask(_ task: TaskItem) {
        tasks.append(task)
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        // Use local storage for now
        let entries = storageService.loadJournalEntries()
        print("[DEBUG] loadData() called, loaded \(entries.count) entries")
        self.journalEntries = entries
        
        // Extract all tasks from journal entries (handle both old and new structures)
        var allTasks: [TaskItem] = []
        for entry in entries {
            // Handle both old (extractedTasks) and new (tasks) structures
            if !entry.tasks.isEmpty {
                // New structure - convert TaskModel to TaskItem
                for task in entry.tasks {
                    let taskItem = TaskItem(
                        title: task.title,
                        isCompleted: task.isCompleted,
                        priority: task.priority
                    )
                    allTasks.append(taskItem)
                }
            } else if !entry.extractedTasks.isEmpty {
                // Old structure - already TaskItem
                allTasks.append(contentsOf: entry.extractedTasks)
            }
        }
        self.tasks = allTasks
    }
    
    func refreshData() {
        loadData()
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