import Foundation
import SwiftUI

// MARK: - User Preferences Service

@MainActor
class UserPreferencesService: ObservableObject {
    static let shared = UserPreferencesService()
    
    @Published var selectedWellnessGoals: [WellnessGoal] = []
    @Published var checkInFrequency: CheckInFrequency = .daily
    @Published var notificationsEnabled: Bool = true
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var personalityProfile: PersonalityProfile? {
        didSet {
            if let profile = personalityProfile {
                if let encoded = try? JSONEncoder().encode(profile) {
                    UserDefaults.standard.set(encoded, forKey: "personalityProfile")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "personalityProfile")
            }
        }
    }
    
    private init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // Load personality profile
        if let data = UserDefaults.standard.data(forKey: "personalityProfile"),
           let profile = try? JSONDecoder().decode(PersonalityProfile.self, from: data) {
            personalityProfile = profile
        } else {
            personalityProfile = nil
        }
        
        loadPreferences()
    }
    
    // MARK: - Preference Management
    
    func loadPreferences() {
        // Load onboarding status
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // Load wellness goals
        let goalStrings = UserDefaults.standard.stringArray(forKey: "selectedWellnessGoals") ?? []
        selectedWellnessGoals = goalStrings.compactMap { WellnessGoal(rawValue: $0) }
        
        // Load frequency
        if let frequencyString = UserDefaults.standard.string(forKey: "checkInFrequency") {
            checkInFrequency = CheckInFrequency(rawValue: frequencyString) ?? .daily
        }
        
        // Load notifications
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    func savePreferences() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        
        let goalStrings = selectedWellnessGoals.map { $0.rawValue }
        UserDefaults.standard.set(goalStrings, forKey: "selectedWellnessGoals")
        
        UserDefaults.standard.set(checkInFrequency.rawValue, forKey: "checkInFrequency")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
    }
    
    func resetPreferences() {
        selectedWellnessGoals = []
        checkInFrequency = .daily
        notificationsEnabled = true
        hasCompletedOnboarding = false
        
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "selectedWellnessGoals")
        UserDefaults.standard.removeObject(forKey: "checkInFrequency")
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
    }
    
    // MARK: - Personalization Logic
    
    func getPersonalizedWelcomeMessage() -> String {
        if selectedWellnessGoals.contains(.mindfulness) {
            return "Ready for your mindful check-in today?"
        } else if selectedWellnessGoals.contains(.selfAwareness) {
            return "Time to reflect and understand yourself better"
        } else if selectedWellnessGoals.contains(.emotionalWellbeing) {
            return "How are you feeling today?"
        } else if selectedWellnessGoals.contains(.habitBuilding) {
            return "Building great habits, one day at a time"
        } else if selectedWellnessGoals.contains(.goalTracking) {
            return "Let's track your progress today"
        } else if selectedWellnessGoals.contains(.stressManagement) {
            return "Take a moment to check in with yourself"
        }
        return "Ready to reflect on your day?"
    }
    
    func getPersonalizedAITone() -> String {
        if selectedWellnessGoals.contains(.mindfulness) {
            return "mindful and contemplative"
        } else if selectedWellnessGoals.contains(.selfAwareness) {
            return "insightful and reflective"
        } else if selectedWellnessGoals.contains(.emotionalWellbeing) {
            return "empathetic and supportive"
        } else if selectedWellnessGoals.contains(.habitBuilding) {
            return "encouraging and motivational"
        } else if selectedWellnessGoals.contains(.goalTracking) {
            return "focused and goal-oriented"
        } else if selectedWellnessGoals.contains(.stressManagement) {
            return "calming and reassuring"
        }
        return "supportive and understanding"
    }
    
    func getPersonalizedInsightTypes() -> [String] {
        var types: [String] = []
        
        if selectedWellnessGoals.contains(.mindfulness) {
            types.append("mindfulness_patterns")
        }
        if selectedWellnessGoals.contains(.selfAwareness) {
            types.append("self_discovery")
        }
        if selectedWellnessGoals.contains(.emotionalWellbeing) {
            types.append("emotional_trends")
        }
        if selectedWellnessGoals.contains(.habitBuilding) {
            types.append("habit_formation")
        }
        if selectedWellnessGoals.contains(.goalTracking) {
            types.append("goal_progress")
        }
        if selectedWellnessGoals.contains(.stressManagement) {
            types.append("stress_tracking")
        }
        
        return types.isEmpty ? ["general_wellness"] : types
    }
    
    func getPersonalizedActivitySuggestions() -> [String] {
        var suggestions: [String] = []
        
        if selectedWellnessGoals.contains(.mindfulness) {
            suggestions.append(contentsOf: ["Meditation", "Breathing exercises", "Present moment awareness"])
        }
        if selectedWellnessGoals.contains(.selfAwareness) {
            suggestions.append(contentsOf: ["Self-reflection", "Pattern recognition", "Journaling"])
        }
        if selectedWellnessGoals.contains(.emotionalWellbeing) {
            suggestions.append(contentsOf: ["Emotional check-ins", "Mood tracking", "Gratitude practice"])
        }
        if selectedWellnessGoals.contains(.habitBuilding) {
            suggestions.append(contentsOf: ["Habit stacking", "Routine building", "Progress tracking"])
        }
        if selectedWellnessGoals.contains(.goalTracking) {
            suggestions.append(contentsOf: ["Goal setting", "Progress review", "Milestone celebration"])
        }
        if selectedWellnessGoals.contains(.stressManagement) {
            suggestions.append(contentsOf: ["Stress relief", "Relaxation techniques", "Coping strategies"])
        }
        
        return suggestions.isEmpty ? ["General wellness", "Self-care", "Reflection"] : Array(Set(suggestions))
    }
    
    func shouldShowFrequencyReminder() -> Bool {
        switch checkInFrequency {
        case .daily:
            return true
        case .fewTimesWeek:
            // Show reminder if haven't checked in for 2 days
            return true // Simplified for now
        case .weekly:
            // Show reminder if haven't checked in for 7 days
            return true // Simplified for now
        case .whenNeeded:
            return false
        }
    }
    
    func savePersonalityProfile(_ profile: PersonalityProfile) {
        personalityProfile = profile
    }
    
    func getPersonalizedMessage(for context: PersonalizationContext = .general) -> String {
        guard let profile = personalityProfile else {
            return getDefaultMessage(for: context)
        }
        
        switch context {
        case .checkInCompleted:
            return getCheckInCompletedMessage(for: profile.primaryType)
        case .encouragement:
            return getEncouragementMessage(for: profile.primaryType)
        case .reflection:
            return getReflectionMessage(for: profile.primaryType)
        case .general:
            return profile.personalizedLanguageStyle
        }
    }
    
    private func getCheckInCompletedMessage(for type: PersonalityType) -> String {
        switch type {
        case .encourager:
            return "Amazing! You checked in today - that's worth celebrating! ✨"
        case .achiever:
            return "Check-in complete! Another step toward your goals. 🎯"
        case .explorer:
            return "Fascinating insights captured! Your patterns are revealing themselves. 🔍"
        case .supporter:
            return "Your check-in is done! Your journey inspires others. 🤝"
        case .minimalist:
            return "Check-in recorded. Clean and simple progress made. 🎋"
        case .reflector:
            return "Thoughtful reflection captured. These insights build over time. 🌙"
        }
    }
    
    private func getEncouragementMessage(for type: PersonalityType) -> String {
        switch type {
        case .encourager:
            return "You're doing wonderfully! Every small step is a victory worth celebrating!"
        case .achiever:
            return "Keep pushing forward! You're making solid progress toward your targets."
        case .explorer:
            return "Interesting journey you're on! Each day reveals something new about yourself."
        case .supporter:
            return "Your commitment matters! Others are inspired by your dedication."
        case .minimalist:
            return "Steady progress. Simple, consistent actions compound over time."
        case .reflector:
            return "Take time to appreciate your growth. These quiet moments of progress matter deeply."
        }
    }
    
    private func getReflectionMessage(for type: PersonalityType) -> String {
        switch type {
        case .encourager:
            return "What wins can you celebrate from today? Even the smallest victories count!"
        case .achiever:
            return "How did today move you closer to your goals? What's the next step?"
        case .explorer:
            return "What patterns are you noticing? What new insights emerged today?"
        case .supporter:
            return "How did your actions today align with your values? Who did you impact?"
        case .minimalist:
            return "What was essential about today? What can you learn and let go of?"
        case .reflector:
            return "Take a quiet moment. What deeper truths about yourself are emerging?"
        }
    }
    
    private func getDefaultMessage(for context: PersonalizationContext) -> String {
        switch context {
        case .checkInCompleted:
            return "Great job checking in today!"
        case .encouragement:
            return "You're making progress! Keep going."
        case .reflection:
            return "Take a moment to reflect on your day."
        case .general:
            return "How are you feeling today?"
        }
    }
}

// MARK: - Enums (moved from OnboardingFlow for reusability)

enum WellnessGoal: String, CaseIterable {
    case mindfulness = "Mindfulness"
    case selfAwareness = "Self-Awareness"
    case emotionalWellbeing = "Emotional Wellbeing"
    case habitBuilding = "Habit Building"
    case goalTracking = "Goal Tracking"
    case stressManagement = "Stress Management"
    
    var icon: String {
        switch self {
        case .mindfulness: return "brain.head.profile"
        case .selfAwareness: return "eye.fill"
        case .emotionalWellbeing: return "heart.fill"
        case .habitBuilding: return "repeat.circle.fill"
        case .goalTracking: return "target"
        case .stressManagement: return "leaf.fill"
        }
    }
    
    var description: String {
        switch self {
        case .mindfulness: return "Practice daily mindfulness"
        case .selfAwareness: return "Understand your patterns"
        case .emotionalWellbeing: return "Improve emotional health"
        case .habitBuilding: return "Build positive habits"
        case .goalTracking: return "Track meaningful goals"
        case .stressManagement: return "Manage stress better"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .mindfulness: return [.blue.opacity(0.8), .purple.opacity(0.6)]
        case .selfAwareness: return [.green.opacity(0.8), .blue.opacity(0.6)]
        case .emotionalWellbeing: return [.pink.opacity(0.8), .red.opacity(0.6)]
        case .habitBuilding: return [.orange.opacity(0.8), .yellow.opacity(0.6)]
        case .goalTracking: return [.purple.opacity(0.8), .pink.opacity(0.6)]
        case .stressManagement: return [.green.opacity(0.8), .teal.opacity(0.6)]
        }
    }
}

enum CheckInFrequency: String, CaseIterable {
    case daily = "Daily"
    case fewTimesWeek = "Few times a week"
    case weekly = "Weekly"
    case whenNeeded = "When I need it"
    
    var description: String {
        switch self {
        case .daily: return "Build a consistent daily habit"
        case .fewTimesWeek: return "Check in 3-4 times per week"
        case .weekly: return "Weekly reflection sessions"
        case .whenNeeded: return "Flexible, when you feel like it"
        }
    }
}

enum PersonalizationContext {
    case checkInCompleted
    case encouragement
    case reflection
    case general
} 