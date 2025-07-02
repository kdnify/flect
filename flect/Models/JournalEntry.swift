import Foundation

struct JournalEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var mood: Mood
    var reflection: String
    var progressNotes: String
    var extractedTasks: [TaskItem]
    var originalBrainDump: String
    
    init(date: Date = Date(), mood: Mood = .neutral, reflection: String = "", progressNotes: String = "", extractedTasks: [TaskItem] = [], originalBrainDump: String = "") {
        self.date = date
        self.mood = mood
        self.reflection = reflection
        self.progressNotes = progressNotes
        self.extractedTasks = extractedTasks
        self.originalBrainDump = originalBrainDump
    }
}

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
} 