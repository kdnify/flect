import Foundation

// MARK: - Personality Types

enum PersonalityType: String, CaseIterable, Codable {
    case encourager = "encourager"     // Needs positive reinforcement & celebrating wins
    case achiever = "achiever"         // Goal-oriented, likes metrics & progress
    case explorer = "explorer"         // Curious, likes variety & new experiences
    case supporter = "supporter"       // Values community & sharing journey
    case minimalist = "minimalist"     // Prefers simple, clean interactions
    case reflector = "reflector"       // Deep thinker, values introspection
    
    var title: String {
        switch self {
        case .encourager: return "The Encourager"
        case .achiever: return "The Achiever"
        case .explorer: return "The Explorer"
        case .supporter: return "The Supporter"
        case .minimalist: return "The Minimalist"
        case .reflector: return "The Reflector"
        }
    }
    
    var description: String {
        switch self {
        case .encourager:
            return "You thrive on positive energy and celebrating every step forward, no matter how small."
        case .achiever:
            return "You're motivated by clear goals, progress tracking, and hitting those meaningful targets."
        case .explorer:
            return "You love discovering new insights about yourself and trying different approaches to growth."
        case .supporter:
            return "You value community and find motivation in sharing your journey with others."
        case .minimalist:
            return "You prefer clean, simple experiences that get straight to the point without clutter."
        case .reflector:
            return "You value deep thinking and self-reflection, preferring quality over quantity in your insights."
        }
    }
    
    var emoji: String {
        switch self {
        case .encourager: return "✨"
        case .achiever: return "🎯"
        case .explorer: return "🔍"
        case .supporter: return "🤝"
        case .minimalist: return "🎋"
        case .reflector: return "🌙"
        }
    }
    
    var communicationStyle: String {
        switch self {
        case .encourager: return "Positive, uplifting, celebrating wins"
        case .achiever: return "Goal-focused, metrics-driven, direct"
        case .explorer: return "Curious, variety-seeking, insightful"
        case .supporter: return "Community-minded, encouraging, connected"
        case .minimalist: return "Clean, simple, essential"
        case .reflector: return "Thoughtful, deep, contemplative"
        }
    }
}

// MARK: - Quiz Questions

struct PersonalityQuestion {
    let id: Int
    let question: String
    let answers: [PersonalityAnswer]
}

struct PersonalityAnswer {
    let text: String
    let types: [PersonalityType: Int] // Weight for each personality type
}

// MARK: - Personality Profile

struct PersonalityProfile: Codable {
    let primaryType: PersonalityType
    let secondaryType: PersonalityType?
    let scores: [PersonalityType: Int]
    let completedAt: Date
    
    init(scores: [PersonalityType: Int]) {
        self.scores = scores
        self.completedAt = Date()
        
        // Sort by score to find primary and secondary
        let sortedTypes = scores.sorted { $0.value > $1.value }
        self.primaryType = sortedTypes.first?.key ?? .encourager
        self.secondaryType = sortedTypes.count > 1 ? sortedTypes[1].key : nil
    }
    
    var personalizedLanguageStyle: String {
        switch primaryType {
        case .encourager:
            return "You're doing amazing! Every step counts and you should celebrate this progress."
        case .achiever:
            return "Great work hitting your targets! Let's keep that momentum going strong."
        case .explorer:
            return "Interesting patterns emerging here! Let's dive deeper into what this tells us."
        case .supporter:
            return "Your journey matters and others can learn from your experience."
        case .minimalist:
            return "Clean progress. Simple and effective approach working well."
        case .reflector:
            return "Take a moment to consider what this reveals about your inner patterns."
        }
    }
}

// MARK: - Quiz Data

class PersonalityQuiz {
    static let questions: [PersonalityQuestion] = [
        PersonalityQuestion(
            id: 1,
            question: "When you achieve something, what feels most rewarding?",
            answers: [
                PersonalityAnswer(
                    text: "The joy and celebration of the moment",
                    types: [.encourager: 3, .supporter: 1]
                ),
                PersonalityAnswer(
                    text: "Checking it off my list and hitting my goal",
                    types: [.achiever: 3, .minimalist: 1]
                ),
                PersonalityAnswer(
                    text: "Understanding what worked and why",
                    types: [.reflector: 3, .explorer: 1]
                ),
                PersonalityAnswer(
                    text: "Sharing the win with people who matter",
                    types: [.supporter: 3, .encourager: 1]
                )
            ]
        ),
        
        PersonalityQuestion(
            id: 2,
            question: "How do you prefer to track your progress?",
            answers: [
                PersonalityAnswer(
                    text: "Colorful charts and visual celebrations",
                    types: [.encourager: 3, .explorer: 1]
                ),
                PersonalityAnswer(
                    text: "Clean numbers and clear metrics",
                    types: [.achiever: 3, .minimalist: 2]
                ),
                PersonalityAnswer(
                    text: "Written reflections and deep insights",
                    types: [.reflector: 3, .minimalist: 1]
                ),
                PersonalityAnswer(
                    text: "Sharing updates with friends or groups",
                    types: [.supporter: 3]
                )
            ]
        ),
        
        PersonalityQuestion(
            id: 3,
            question: "When you're struggling, what helps most?",
            answers: [
                PersonalityAnswer(
                    text: "Encouragement and reminders of past wins",
                    types: [.encourager: 3, .supporter: 1]
                ),
                PersonalityAnswer(
                    text: "Breaking it down into smaller, achievable steps",
                    types: [.achiever: 3, .minimalist: 1]
                ),
                PersonalityAnswer(
                    text: "Trying a completely different approach",
                    types: [.explorer: 3, .reflector: 1]
                ),
                PersonalityAnswer(
                    text: "Talking it through with someone who cares",
                    types: [.supporter: 3, .encourager: 1]
                )
            ]
        ),
        
        PersonalityQuestion(
            id: 4,
            question: "What kind of app experience do you prefer?",
            answers: [
                PersonalityAnswer(
                    text: "Bright, colorful, and fun to use",
                    types: [.encourager: 3, .explorer: 1]
                ),
                PersonalityAnswer(
                    text: "Clean, minimal, and efficient",
                    types: [.minimalist: 3, .achiever: 2]
                ),
                PersonalityAnswer(
                    text: "Rich with insights and things to discover",
                    types: [.explorer: 3, .reflector: 2]
                ),
                PersonalityAnswer(
                    text: "Connected to others and community features",
                    types: [.supporter: 3]
                )
            ]
        ),
        
        PersonalityQuestion(
            id: 5,
            question: "How often do you like to check in with yourself?",
            answers: [
                PersonalityAnswer(
                    text: "Frequently! I love regular positive touchpoints",
                    types: [.encourager: 3, .achiever: 1]
                ),
                PersonalityAnswer(
                    text: "Daily, as part of my routine and goal tracking",
                    types: [.achiever: 3, .minimalist: 1]
                ),
                PersonalityAnswer(
                    text: "When I feel like diving deep into my thoughts",
                    types: [.reflector: 3, .explorer: 1]
                ),
                PersonalityAnswer(
                    text: "Whenever I have something worth sharing",
                    types: [.supporter: 3, .minimalist: 1]
                )
            ]
        )
    ]
    
    static func calculatePersonality(from answers: [Int: Int]) -> PersonalityProfile {
        var scores: [PersonalityType: Int] = [:]
        
        // Initialize all personality types with 0
        for type in PersonalityType.allCases {
            scores[type] = 0
        }
        
        // Calculate scores based on answers
        for (questionIndex, answerIndex) in answers {
            if questionIndex < questions.count && answerIndex < questions[questionIndex].answers.count {
                let answer = questions[questionIndex].answers[answerIndex]
                for (type, weight) in answer.types {
                    scores[type, default: 0] += weight
                }
            }
        }
        
        return PersonalityProfile(scores: scores)
    }
} 