import UIKit
import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Light impact for subtle interactions (button taps, selections)
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium impact for moderate interactions (swipe actions, priority changes)
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy impact for significant interactions (task completion, deletion)
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success feedback for positive actions (task completed, saved successfully)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning feedback for cautionary actions (due date approaching, validation warnings)
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error feedback for negative actions (deletion, errors, failures)
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback for picker changes, list navigation
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Contextual Feedback Methods
    
    /// Feedback for task-related actions
    func taskCompleted() {
        success()
    }
    
    func taskDeleted() {
        error()
    }
    
    func taskCreated() {
        lightImpact()
    }
    
    func taskEdited() {
        lightImpact()
    }
    
    func priorityChanged() {
        mediumImpact()
    }
    
    /// Feedback for UI interactions
    func buttonTap() {
        lightImpact()
    }
    
    func swipeAction() {
        mediumImpact()
    }
    
    func longPress() {
        mediumImpact()
    }
    
    /// Feedback for system actions
    func saveCompleted() {
        success()
    }
    
    func saveFailed() {
        error()
    }
    
    func processingStarted() {
        lightImpact()
    }
    
    func processingCompleted() {
        success()
    }
    
    /// Feedback for voice recording
    func recordingStarted() {
        mediumImpact()
    }
    
    func recordingStopped() {
        lightImpact()
    }
    
    func transcriptionCompleted() {
        success()
    }
    
    /// Feedback for navigation
    func pageChanged() {
        selection()
    }
    
    func modalPresented() {
        lightImpact()
    }
    
    func modalDismissed() {
        lightImpact()
    }
}

// MARK: - SwiftUI View Extension for Easy Access

extension View {
    func hapticFeedback(_ type: HapticFeedbackType) -> some View {
        self.onTapGesture {
            switch type {
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            case .success:
                HapticManager.shared.success()
            case .warning:
                HapticManager.shared.warning()
            case .error:
                HapticManager.shared.error()
            case .selection:
                HapticManager.shared.selection()
            }
        }
    }
    
    func onHapticTap(_ hapticType: HapticFeedbackType, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            switch hapticType {
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            case .success:
                HapticManager.shared.success()
            case .warning:
                HapticManager.shared.warning()
            case .error:
                HapticManager.shared.error()
            case .selection:
                HapticManager.shared.selection()
            }
            action()
        }
    }
}

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
} 