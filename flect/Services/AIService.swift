import Foundation

// Import the system Task type to avoid conflicts with our TaskModel
// typealias SystemTask = Task  // Remove this duplicate

protocol AIServiceProtocol {
    func extractTasks(from brainDump: String) async throws -> [TaskItem]
    func generateJournalEntry(from brainDump: String, mood: Mood) async throws -> JournalEntry
    func improveReflection(_ reflection: String, style: WritingStyle) async throws -> String
}

class AIService: AIServiceProtocol, ObservableObject {
    static let shared = AIService()
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    @Published var isProcessing = false
    @Published var processingStatus = "Ready"
    
    func processText(_ text: String, mood: String? = nil) async throws -> JournalEntry {
        await MainActor.run {
            isProcessing = true
            processingStatus = "Processing with AI..."
        }
        
        do {
            let processedEntry = try await supabaseService.processBrainDump(text, mood: mood)
            
            await MainActor.run {
                isProcessing = false
                processingStatus = "Processing complete!"
            }
            
            // Reset status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.processingStatus = "Ready"
            }
            
            return processedEntry
            
        } catch {
            await MainActor.run {
                isProcessing = false
                processingStatus = "Processing failed"
            }
            
            // Reset status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.processingStatus = "Ready"
            }
            
            throw error
        }
    }
    
    // Legacy method for backward compatibility
    func analyzeMood(from text: String) -> Mood {
        // This is now handled by the backend, but kept for compatibility
        let lowerText = text.lowercased()
        
        if lowerText.contains("excited") || lowerText.contains("amazing") || lowerText.contains("fantastic") {
            return .excited
        } else if lowerText.contains("happy") || lowerText.contains("great") || lowerText.contains("good") {
            return .happy
        } else if lowerText.contains("stressed") || lowerText.contains("anxious") || lowerText.contains("worried") {
            return .stressed
        } else if lowerText.contains("tired") || lowerText.contains("exhausted") || lowerText.contains("sleepy") {
            return .tired
        } else if lowerText.contains("focused") || lowerText.contains("determined") || lowerText.contains("productive") {
            return .focused
        } else if lowerText.contains("grateful") || lowerText.contains("thankful") || lowerText.contains("blessed") {
            return .grateful
        }
        
        return .neutral
    }
    
    // Legacy method for backward compatibility
    func extractTasks(from text: String) -> [TaskItem] {
        // This is now handled by the backend, but kept for compatibility
        return []
    }
    
    // MARK: - Placeholder implementations for MVP
    // TODO: Replace with actual OpenAI/Claude API calls
    
    func extractTasks(from brainDump: String) async throws -> [TaskItem] {
        // Simulate AI processing time
        try await _Concurrency.Task.sleep(nanoseconds: 1_500_000_000)
        
        // Simple task extraction for MVP - split by lines and filter for action words
        let lines = brainDump.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var extractedTasks: [TaskItem] = []
        
        for line in lines {
            if containsActionWords(line) {
                let priority = determinePriority(from: line)
                let task = TaskItem(title: line, priority: priority)
                extractedTasks.append(task)
            }
        }
        
        return extractedTasks
    }
    
    func generateJournalEntry(from brainDump: String, mood: Mood) async throws -> JournalEntry {
        // Simulate API delay
        try await _Concurrency.Task.sleep(nanoseconds: 1_500_000_000)
        
        // Extract tasks first
        let tasks = try await extractTasks(from: brainDump)
        
        // Generate structured reflection (placeholder logic)
        let reflection = generatePlaceholderReflection(from: brainDump, mood: mood)
        let progressNotes = generatePlaceholderProgress(from: tasks)
        
        return JournalEntry(
            mood: mood,
            reflection: reflection,
            progressNotes: progressNotes,
            extractedTasks: tasks,
            originalBrainDump: brainDump
        )
    }
    
    func improveReflection(_ reflection: String, style: WritingStyle) async throws -> String {
        // Simulate API delay
        try await _Concurrency.Task.sleep(nanoseconds: 800_000_000)
        
        // Placeholder: return improved version based on style
        switch style {
        case .concise:
            return "✨ " + reflection.prefix(100) + (reflection.count > 100 ? "..." : "")
        case .detailed:
            return "Today's reflection: " + reflection + "\n\nKey insights: This moment of self-reflection reveals important patterns in my thinking and approach."
        case .creative:
            return "🌟 " + reflection + " 🌟\n\nLike a river flowing toward the sea, these thoughts carry the essence of this moment..."
        }
    }
}

// MARK: - Helper Types and Methods

enum WritingStyle: String, CaseIterable {
    case concise = "concise"
    case detailed = "detailed" 
    case creative = "creative"
    
    var displayName: String {
        switch self {
        case .concise: return "Concise"
        case .detailed: return "Detailed"
        case .creative: return "Creative"
        }
    }
}

private extension AIService {
    func containsActionWords(_ text: String) -> Bool {
        let actionWords = ["need to", "should", "must", "have to", "want to", "call", "email", "buy", "finish", "start", "complete", "remember", "don't forget"]
        let lowercased = text.lowercased()
        return actionWords.contains { lowercased.contains($0) }
    }
    
    func determinePriority(from text: String) -> TaskPriority {
        let urgentWords = ["urgent", "asap", "important", "critical", "deadline"]
        let lowPriorityWords = ["maybe", "eventually", "sometime", "when i have time"]
        
        let lowercased = text.lowercased()
        
        if urgentWords.contains(where: { lowercased.contains($0) }) {
            return .high
        } else if lowPriorityWords.contains(where: { lowercased.contains($0) }) {
            return .low
        }
        
        return .medium
    }
    
    func generatePlaceholderReflection(from brainDump: String, mood: Mood) -> String {
        let wordCount = brainDump.components(separatedBy: .whitespacesAndNewlines).count
        
        let baseReflection: String
        switch mood {
        case .excited:
            baseReflection = "Today feels full of energy and possibility. "
        case .happy:
            baseReflection = "There's a positive flow to today's thoughts. "
        case .focused:
            baseReflection = "My mind feels clear and purposeful today. "
        case .stressed:
            baseReflection = "Today brings some challenges, but I'm working through them. "
        case .tired:
            baseReflection = "Taking things one step at a time today. "
        case .grateful:
            baseReflection = "Reflecting on what I'm thankful for today. "
        default:
            baseReflection = "Taking a moment to process today's thoughts. "
        }
        
        if wordCount > 50 {
            return baseReflection + "There's a lot on my mind, and getting it all down helps me see the bigger picture. The act of brain dumping reveals patterns and priorities I might otherwise miss."
        } else {
            return baseReflection + "Sometimes a few words capture exactly what needs to be said."
        }
    }
    
    func generatePlaceholderProgress(from tasks: [TaskItem]) -> String {
        if tasks.isEmpty {
            return "Today was more about reflection and processing thoughts rather than specific action items."
        } else if tasks.count == 1 {
            return "Identified one key action item to focus on moving forward."
        } else {
            return "Broke down my thoughts into \(tasks.count) actionable items. Having a clear list helps me move from thinking to doing."
        }
    }
} 