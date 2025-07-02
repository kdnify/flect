import XCTest
@testable import flect

@MainActor
final class JournalViewModelTests: XCTestCase {
    
    var viewModel: JournalViewModel!
    var mockAIService: MockAIService!
    var mockStorageService: MockStorageService!
    
    override func setUp() {
        super.setUp()
        mockAIService = MockAIService()
        mockStorageService = MockStorageService()
        viewModel = JournalViewModel(aiService: mockAIService, storageService: mockStorageService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAIService = nil
        mockStorageService = nil
        super.tearDown()
    }
    
    // MARK: - Journal Entry Tests
    
    func testCreateJournalEntry_Success() async {
        // Given
        let brainDump = "Test brain dump content"
        let mood = Mood.focused
        let expectedEntry = JournalEntry(mood: mood, reflection: "Test reflection", originalBrainDump: brainDump)
        mockAIService.mockJournalEntry = expectedEntry
        
        // When
        await viewModel.createJournalEntry(from: brainDump, mood: mood)
        
        // Then
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.journalEntries.count, 1)
        XCTAssertEqual(viewModel.journalEntries.first?.originalBrainDump, brainDump)
        XCTAssertEqual(viewModel.journalEntries.first?.mood, mood)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testCreateJournalEntry_Failure() async {
        // Given
        mockAIService.shouldThrowError = true
        
        // When
        await viewModel.createJournalEntry(from: "Test", mood: .neutral)
        
        // Then
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.journalEntries.count, 0)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testUpdateJournalEntry() {
        // Given
        let entry = JournalEntry(mood: .happy, reflection: "Original")
        viewModel.journalEntries = [entry]
        
        // When
        var updatedEntry = entry
        updatedEntry.reflection = "Updated reflection"
        viewModel.updateJournalEntry(updatedEntry)
        
        // Then
        XCTAssertEqual(viewModel.journalEntries.first?.reflection, "Updated reflection")
    }
    
    func testDeleteJournalEntry() {
        // Given
        let entry = JournalEntry()
        viewModel.journalEntries = [entry]
        
        // When
        viewModel.deleteJournalEntry(entry)
        
        // Then
        XCTAssertEqual(viewModel.journalEntries.count, 0)
    }
    
    // MARK: - Task Management Tests
    
    func testToggleTaskCompletion() {
        // Given
        let task = TaskItem(title: "Test task")
        viewModel.tasks = [task]
        
        // When
        viewModel.toggleTaskCompletion(task)
        
        // Then
        XCTAssertTrue(viewModel.tasks.first?.isCompleted ?? false)
    }
    
    func testAddTaskItem() {
        // Given
        let task = TaskItem(title: "New task")
        
        // When
        viewModel.addTaskItem(task)
        
        // Then
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks.first?.title, "New task")
    }
    
    func testDeleteTaskItem() {
        // Given
        let task = TaskItem(title: "Task to delete")
        viewModel.tasks = [task]
        
        // When
        viewModel.deleteTaskItem(task)
        
        // Then
        XCTAssertEqual(viewModel.tasks.count, 0)
    }
    
    // MARK: - Computed Properties Tests
    
    func testPendingTasks() {
        // Given
        let completedTask = TaskItem(title: "Completed", isCompleted: true)
        let pendingTask = TaskItem(title: "Pending", isCompleted: false)
        viewModel.tasks = [completedTask, pendingTask]
        
        // When
        let pending = viewModel.pendingTasks
        
        // Then
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.title, "Pending")
    }
    
    func testCompletedTasks() {
        // Given
        let completedTask = TaskItem(title: "Completed", isCompleted: true)
        let pendingTask = TaskItem(title: "Pending", isCompleted: false)
        viewModel.tasks = [completedTask, pendingTask]
        
        // When
        let completed = viewModel.completedTasks
        
        // Then
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.title, "Completed")
    }
    
    func testTodaysEntry() {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let todaysEntry = JournalEntry(date: today, mood: .happy)
        let yesterdaysEntry = JournalEntry(date: yesterday, mood: .neutral)
        
        viewModel.journalEntries = [todaysEntry, yesterdaysEntry]
        
        // When
        let todayEntry = viewModel.todaysEntry
        
        // Then
        XCTAssertNotNil(todayEntry)
        XCTAssertEqual(todayEntry?.mood, .happy)
    }
}

// MARK: - Mock Services

class MockAIService: AIServiceProtocol {
    var shouldThrowError = false
    var mockJournalEntry: JournalEntry?
    var mockTasks: [TaskItem] = []
    
    func extractTasks(from brainDump: String) async throws -> [TaskItem] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return mockTasks
    }
    
    func generateJournalEntry(from brainDump: String, mood: Mood) async throws -> JournalEntry {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return mockJournalEntry ?? JournalEntry(mood: mood, originalBrainDump: brainDump)
    }
    
    func improveReflection(_ reflection: String, style: WritingStyle) async throws -> String {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return "Improved: \(reflection)"
    }
}

class MockStorageService: StorageServiceProtocol {
    var savedJournalEntries: [JournalEntry] = []
    var savedTasks: [TaskItem] = []
    
    func saveJournalEntries(_ entries: [JournalEntry]) {
        savedJournalEntries = entries
    }
    
    func loadJournalEntries() -> [JournalEntry] {
        return savedJournalEntries
    }
    
    func saveTasks(_ tasks: [TaskItem]) {
        savedTasks = tasks
    }
    
    func loadTasks() -> [TaskItem] {
        return savedTasks
    }
    
    func clearAllData() {
        savedJournalEntries = []
        savedTasks = []
    }
} 