import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var originalText: String
    var processedContent: String
    var title: String
    var mood: String?
    var tasks: [TaskModel]
    
    // Legacy fields for backward compatibility
    var reflection: String { processedContent }
    var progressNotes: String { "" }
    var extractedTasks: [TaskItem] { 
        tasks.map { task in
            TaskItem(
                title: task.title,
                isCompleted: task.isCompleted,
                priority: task.priority
            )
        }
    }
    var originalBrainDump: String { originalText }
    
    init(id: UUID = UUID(), date: Date = Date(), originalText: String = "", processedContent: String = "", title: String = "", mood: String? = nil, tasks: [TaskModel] = []) {
        self.id = id
        self.date = date
        self.originalText = originalText
        self.processedContent = processedContent
        self.title = title
        self.mood = mood
        self.tasks = tasks
    }
    
    // Legacy initializer for backward compatibility
    init(date: Date = Date(), mood: Mood = .neutral, reflection: String = "", progressNotes: String = "", extractedTasks: [TaskItem] = [], originalBrainDump: String = "") {
        self.id = UUID()
        self.date = date
        self.originalText = originalBrainDump
        self.processedContent = reflection
        self.title = "Journal Entry"
        self.mood = mood.rawValue
        self.tasks = extractedTasks.map { taskItem in
            TaskModel(
                id: taskItem.id,
                title: taskItem.title,
                description: "",
                isCompleted: taskItem.isCompleted,
                priority: taskItem.priority
            )
        }
    }
    
    var moodEmoji: String {
        guard let moodString = mood else { 
            print("🔍 DEBUG: moodEmoji - mood is nil, returning 😐")
            return "😐" 
        }
        
        print("🔍 DEBUG: moodEmoji - received mood string: '\(moodString)'")
        
        switch moodString.lowercased() {
        case "excited": return "🚀"
        case "happy": return "😊"
        case "neutral": return "😐"
        case "focused": return "🎯"
        case "stressed": return "😰"
        case "tired": return "😴"
        case "grateful": return "🙏"
        case "motivated": return "💪"
        case "anxious": return "😰"
        case "sad": return "😢"
        default: 
            print("🔍 DEBUG: moodEmoji - no match for '\(moodString)', returning 😐")
            return "😐"
        }
    }
    
    var moodDisplayName: String {
        guard let moodString = mood else { return "Neutral" }
        return moodString.capitalized
    }
}

// Keep original Mood enum for backward compatibility
enum Mood: String, CaseIterable, Codable {
    case excited = "🚀"
    case happy = "😊" 
    case neutral = "😐"
    case focused = "🎯"
    case stressed = "😰"
    case tired = "😴"
    case grateful = "🙏"
    
    var displayName: String {
        switch self {
        case .excited: return "Excited"
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .focused: return "Focused"
        case .stressed: return "Stressed"
        case .tired: return "Tired"
        case .grateful: return "Grateful"
        }
    }
    
    var name: String {
        switch self {
        case .excited: return "excited"
        case .happy: return "happy"
        case .neutral: return "neutral"
        case .focused: return "focused"
        case .stressed: return "stressed"
        case .tired: return "tired"
        case .grateful: return "grateful"
        }
    }
} 