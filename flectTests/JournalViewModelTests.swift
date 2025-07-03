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
        let expectedEntry = JournalEntry(
            originalText: brainDump,
            processedContent: "Test reflection",
            title: "Test Entry",
            mood: mood.rawValue,
            tasks: []
        )
        mockAIService.mockJournalEntry = expectedEntry
        
        // When
        await viewModel.createJournalEntry(from: brainDump, mood: mood)
        
        // Then
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.journalEntries.count, 1)
        XCTAssertEqual(viewModel.journalEntries.first?.originalText, brainDump)
        XCTAssertEqual(viewModel.journalEntries.first?.mood, mood.rawValue)
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
        let entry = JournalEntry(
            originalText: "Original",
            processedContent: "Original reflection",
            title: "Original Title",
            mood: "happy",
            tasks: []
        )
        viewModel.journalEntries = [entry]
        
        // When
        var updatedEntry = entry
        updatedEntry.processedContent = "Updated reflection"
        viewModel.updateJournalEntry(updatedEntry)
        
        // Then
        XCTAssertEqual(viewModel.journalEntries.first?.processedContent, "Updated reflection")
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
    
    func testToggleTaskCompletion() async {
        // Given
        let task = TaskModel(title: "Test task")
        viewModel.tasks = [task]
        
        // When
        await viewModel.toggleTaskCompletion(task)
        
        // Then
        XCTAssertTrue(viewModel.tasks.first?.isCompleted ?? false)
    }
    
    func testAddTaskItem() {
        // Given
        let task = TaskModel(title: "New task")
        
        // When
        viewModel.addTaskItem(task)
        
        // Then
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks.first?.title, "New task")
    }
    
    func testDeleteTaskItem() {
        // Given
        let task = TaskModel(title: "Task to delete")
        viewModel.tasks = [task]
        
        // When
        viewModel.deleteTaskItem(task)
        
        // Then
        XCTAssertEqual(viewModel.tasks.count, 0)
    }
    
    // MARK: - Computed Properties Tests
    
    func testPendingTasks() {
        // Given
        let completedTask = TaskModel(title: "Completed", isCompleted: true)
        let pendingTask = TaskModel(title: "Pending", isCompleted: false)
        viewModel.tasks = [completedTask, pendingTask]
        
        // When
        let pending = viewModel.pendingTasks
        
        // Then
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.title, "Pending")
    }
    
    func testCompletedTasks() {
        // Given
        let completedTask = TaskModel(title: "Completed", isCompleted: true)
        let pendingTask = TaskModel(title: "Pending", isCompleted: false)
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
        
        let todaysEntry = JournalEntry(
            date: today,
            originalText: "Today's entry",
            processedContent: "Today's reflection",
            title: "Today",
            mood: "happy",
            tasks: []
        )
        let yesterdaysEntry = JournalEntry(
            date: yesterday,
            originalText: "Yesterday's entry",
            processedContent: "Yesterday's reflection",
            title: "Yesterday",
            mood: "neutral",
            tasks: []
        )
        
        viewModel.journalEntries = [todaysEntry, yesterdaysEntry]
        
        // When
        let todayEntry = viewModel.todaysEntry
        
        // Then
        XCTAssertNotNil(todayEntry)
        XCTAssertEqual(todayEntry?.mood, "happy")
    }
}

// MARK: - Mock Services

class MockAIService: AIServiceProtocol {
    var shouldThrowError = false
    var mockJournalEntry: JournalEntry?
    var mockTasks: [TaskModel] = []
    
    func extractTasks(from brainDump: String) async throws -> [TaskModel] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return mockTasks
    }
    
    func generateJournalEntry(from brainDump: String, mood: Mood) async throws -> JournalEntry {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return mockJournalEntry ?? JournalEntry(
            originalText: brainDump,
            processedContent: "Generated reflection",
            title: "Generated Entry",
            mood: mood.rawValue,
            tasks: []
        )
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
    var savedTasks: [TaskModel] = []
    
    func saveJournalEntries(_ entries: [JournalEntry]) {
        savedJournalEntries = entries
    }
    
    func loadJournalEntries() -> [JournalEntry] {
        return savedJournalEntries
    }
    
    func saveTasks(_ tasks: [TaskModel]) {
        savedTasks = tasks
    }
    
    func loadTasks() -> [TaskModel] {
        return savedTasks
    }
    
    func clearAllData() {
        savedJournalEntries = []
        savedTasks = []
    }
} 