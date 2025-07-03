import XCTest
@testable import flect

final class ModelsTests: XCTestCase {
    
    // MARK: - JournalEntry Tests
    
    func testJournalEntryInitialization() {
        // Given
        let originalText = "Test brain dump"
        let processedContent = "Test reflection"
        let title = "Test Entry"
        let mood = "happy"
        let tasks = [TaskModel(title: "Test task")]
        
        // When
        let entry = JournalEntry(
            originalText: originalText,
            processedContent: processedContent,
            title: title,
            mood: mood,
            tasks: tasks
        )
        
        // Then
        XCTAssertEqual(entry.originalText, originalText)
        XCTAssertEqual(entry.processedContent, processedContent)
        XCTAssertEqual(entry.title, title)
        XCTAssertEqual(entry.mood, mood)
        XCTAssertEqual(entry.tasks.count, 1)
    }
    
    func testJournalEntryDefaultInitialization() {
        // When
        let entry = JournalEntry()
        
        // Then
        XCTAssertEqual(entry.mood, "neutral")
        XCTAssertEqual(entry.processedContent, "")
        XCTAssertEqual(entry.title, "")
        XCTAssertEqual(entry.tasks.count, 0)
        XCTAssertEqual(entry.originalText, "")
    }
    
    func testJournalEntryCodable() {
        // Given
        let entry = JournalEntry(
            originalText: "Test brain dump",
            processedContent: "Test reflection",
            title: "Test Entry",
            mood: "excited",
            tasks: []
        )
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Then
        XCTAssertNoThrow {
            let data = try encoder.encode(entry)
            let decodedEntry = try decoder.decode(JournalEntry.self, from: data)
            
            XCTAssertEqual(decodedEntry.mood, entry.mood)
            XCTAssertEqual(decodedEntry.processedContent, entry.processedContent)
            XCTAssertEqual(decodedEntry.originalText, entry.originalText)
        }
    }
    
    // MARK: - Task Tests
    
    func testTaskInitialization() {
        // Given
        let title = "Test task"
        let priority = TaskPriority.high
        let dueDate = Date()
        
        // When
        let task = TaskModel(
            title: title,
            isCompleted: true,
            priority: priority,
            dueDate: dueDate
        )
        
        // Then
        XCTAssertEqual(task.title, title)
        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(task.priority, priority)
        XCTAssertEqual(task.dueDate, dueDate)
    }
    
    func testTaskDefaultInitialization() {
        // When
        let task = TaskModel(title: "Default task")
        
        // Then
        XCTAssertEqual(task.title, "Default task")
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.priority, .medium)
        XCTAssertNil(task.dueDate)
    }
    
    func testTaskCodable() {
        // Given
        let task = TaskModel(title: "Codable task", priority: .high)
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Then
        XCTAssertNoThrow {
            let data = try encoder.encode(task)
            let decodedTask = try decoder.decode(TaskModel.self, from: data)
            
            XCTAssertEqual(decodedTask.title, task.title)
            XCTAssertEqual(decodedTask.priority, task.priority)
            XCTAssertEqual(decodedTask.isCompleted, task.isCompleted)
        }
    }
    
    // MARK: - Mood Tests
    
    func testMoodDisplayNames() {
        XCTAssertEqual(Mood.excited.displayName, "Excited")
        XCTAssertEqual(Mood.happy.displayName, "Happy")
        XCTAssertEqual(Mood.neutral.displayName, "Neutral")
        XCTAssertEqual(Mood.focused.displayName, "Focused")
        XCTAssertEqual(Mood.stressed.displayName, "Stressed")
        XCTAssertEqual(Mood.tired.displayName, "Tired")
        XCTAssertEqual(Mood.grateful.displayName, "Grateful")
    }
    
    func testMoodEmojis() {
        XCTAssertEqual(Mood.excited.rawValue, "🚀")
        XCTAssertEqual(Mood.happy.rawValue, "😊")
        XCTAssertEqual(Mood.neutral.rawValue, "😐")
        XCTAssertEqual(Mood.focused.rawValue, "🎯")
        XCTAssertEqual(Mood.stressed.rawValue, "😰")
        XCTAssertEqual(Mood.tired.rawValue, "😴")
        XCTAssertEqual(Mood.grateful.rawValue, "🙏")
    }
    
    func testMoodCaseIterable() {
        // When
        let allMoods = Mood.allCases
        
        // Then
        XCTAssertEqual(allMoods.count, 7)
        XCTAssertTrue(allMoods.contains(.excited))
        XCTAssertTrue(allMoods.contains(.happy))
        XCTAssertTrue(allMoods.contains(.neutral))
        XCTAssertTrue(allMoods.contains(.focused))
        XCTAssertTrue(allMoods.contains(.stressed))
        XCTAssertTrue(allMoods.contains(.tired))
        XCTAssertTrue(allMoods.contains(.grateful))
    }
    
    // MARK: - TaskPriority Tests
    
    func testTaskPriorityDisplayNames() {
        XCTAssertEqual(TaskPriority.low.displayName, "Low")
        XCTAssertEqual(TaskPriority.medium.displayName, "Medium")
        XCTAssertEqual(TaskPriority.high.displayName, "High")
    }
    
    func testTaskPriorityColors() {
        XCTAssertEqual(TaskPriority.low.color, "mediumGrey")
        XCTAssertEqual(TaskPriority.medium.color, "accent")
        XCTAssertEqual(TaskPriority.high.color, "error")
    }
    
    func testTaskPriorityCaseIterable() {
        // When
        let allPriorities = TaskPriority.allCases
        
        // Then
        XCTAssertEqual(allPriorities.count, 3)
        XCTAssertTrue(allPriorities.contains(.low))
        XCTAssertTrue(allPriorities.contains(.medium))
        XCTAssertTrue(allPriorities.contains(.high))
    }
} 