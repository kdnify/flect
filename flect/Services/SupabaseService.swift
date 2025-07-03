import Foundation
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        let url = URL(string: "https://rinjdpgdcdmtmadabqdf.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpbmpkcGdkY2RtdG1hZGFicWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0OTQ5MjcsImV4cCI6MjA2NzA3MDkyN30.vtWSWgvZgU1vIFG-wrAjBOi_jmIElwsttAkUvi1kVBg"
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }
    
    // MARK: - Journal Entries
    
    func fetchJournalEntries() async throws -> [JournalEntry] {
        let response: [SupabaseJournalEntry] = try await client
            .from("journal_entries")
            .select("*, tasks(*)")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.map { $0.toJournalEntry() }
    }
    
    func processBrainDump(_ text: String, mood: String? = nil) async throws -> JournalEntry {
        // TEMPORARY MOCK IMPLEMENTATION
        // TODO: Fix the Supabase function invocation API
        
        print("🔍 DEBUG: SupabaseService.processBrainDump called with mood: \(mood ?? "nil")")
        
        // Simulate network delay
        try await _Concurrency.Task.sleep(nanoseconds: 1_500_000_000)
        
        // Create a mock processed entry
        let id = UUID()
        let now = Date()
        
        // Simple AI-like processing simulation
        let title = "Brain Dump Entry"
        let moodToUse = mood ?? determineMood(from: text)
        let aiReflection = generateAIReflection(from: text, mood: moodToUse)
        let processedContent = aiReflection.isEmpty ? text : aiReflection
        let extractedTasks = extractSimpleTasks(from: text)
        
        print("🔍 DEBUG: Final mood being set: \(moodToUse)")
        
        return JournalEntry(
            id: id,
            date: now,
            originalText: text,
            processedContent: processedContent,
            title: title,
            mood: moodToUse,
            tasks: extractedTasks
        )
    }
    
    private func determineMood(from text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("stress") || lowercased.contains("anxious") || lowercased.contains("worried") {
            return "stressed"
        } else if lowercased.contains("happy") || lowercased.contains("excited") || lowercased.contains("great") {
            return "happy"
        } else if lowercased.contains("tired") || lowercased.contains("exhausted") {
            return "tired"
        } else if lowercased.contains("motivated") || lowercased.contains("productive") {
            return "motivated"
        }
        return "neutral"
    }
    
    private func extractSimpleTasks(from text: String) -> [TaskModel] {
        var tasks: [TaskModel] = []
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 10 && (trimmed.lowercased().contains("need to") || 
                                     trimmed.lowercased().contains("should") || 
                                     trimmed.lowercased().contains("must") ||
                                     trimmed.lowercased().contains("remember to")) {
                let task = TaskModel(
                    title: trimmed,
                    priority: .medium
                )
                tasks.append(task)
            }
        }
        
        // If no tasks found, create a generic one
        if tasks.isEmpty {
            tasks.append(TaskModel(
                title: "Follow up on brain dump",
                priority: .low
            ))
        }
        
        return tasks
    }
    
    // Simulate an AI-generated reflection. If the text is too short or gibberish, return empty string.
    private func generateAIReflection(from text: String, mood: String) -> String {
        let wordCount = text.split(separator: " ").count
        if wordCount < 5 { return "" }
        // Simple mood-based reflection
        switch mood.lowercased() {
        case "excited": return "Today feels full of energy and possibility. " + text
        case "happy": return "There's a positive flow to today's thoughts. " + text
        case "focused": return "My mind feels clear and purposeful today. " + text
        case "stressed": return "Today brings some challenges, but I'm working through them. " + text
        case "tired": return "Taking things one step at a time today. " + text
        case "grateful": return "Reflecting on what I'm thankful for today. " + text
        default: return text
        }
    }
    
    // MARK: - Tasks
    
    func updateTaskStatus(_ taskId: String, isCompleted: Bool) async throws {
        try await client
            .from("tasks")
            .update(["is_completed": isCompleted])
            .eq("id", value: taskId)
            .execute()
    }
}

// MARK: - Supabase Models

struct SupabaseJournalEntry: Codable {
    let id: String
    let createdAt: String
    let updatedAt: String
    let originalText: String
    let processedContent: String
    let title: String
    let mood: String?
    let processingStatus: String
    
    private enum CodingKeys: String, CodingKey {
        case id, title, mood
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case originalText = "original_text"
        case processedContent = "processed_content"
        case processingStatus = "processing_status"
    }
    
    func toJournalEntry() -> JournalEntry {
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: createdAt) ?? Date()
        
        return JournalEntry(
            id: UUID(uuidString: id) ?? UUID(),
            date: date,
            originalText: originalText,
            processedContent: processedContent,
            title: title,
            mood: mood,
            tasks: [] // Tasks will be loaded separately
        )
    }
}

struct SupabaseTaskModel: Codable {
    let id: String
    let journalEntryId: String
    let title: String
    let description: String?
    let isCompleted: Bool
    let priority: String
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description, priority
        case journalEntryId = "journal_entry_id"
        case isCompleted = "is_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toTaskModel() -> TaskModel {
        let priority = TaskPriority(rawValue: priority) ?? .medium
        return TaskModel(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            description: description ?? "",
            isCompleted: isCompleted,
            priority: priority
        )
    }
}

enum SupabaseError: Error {
    case processingFailed
    case networkError
    case decodingError
    
    var localizedDescription: String {
        switch self {
        case .processingFailed:
            return "Failed to process brain dump"
        case .networkError:
            return "Network connection error"
        case .decodingError:
            return "Failed to decode response"
        }
    }
} 