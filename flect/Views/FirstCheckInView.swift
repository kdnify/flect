import SwiftUI

struct FirstCheckInView: View {
    @State private var selectedMood = 2 // Start with neutral mood
    @State private var selectedActivities: Set<String> = []
    @State private var happyThing = ""
    @State private var showingCelebration = false
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss
    
    // Pre-defined activity suggestions for first time
    private let suggestedActivities = [
        "Work", "Exercise", "Social", "Family", "Reading", "Music",
        "Nature", "Cooking", "Learning", "Relaxation", "Travel", "Creativity"
    ]
    
    // Sophisticated mood system
    private let moodLevels = [
        ReflectionMoodLevel(name: "Rough", color: Color.red.opacity(0.6), description: "Challenging day"),
        ReflectionMoodLevel(name: "Okay", color: Color.orange.opacity(0.6), description: "Getting through"),
        ReflectionMoodLevel(name: "Neutral", color: Color.gray.opacity(0.6), description: "Balanced state"),
        ReflectionMoodLevel(name: "Good", color: Color.blue.opacity(0.6), description: "Positive energy"),
        ReflectionMoodLevel(name: "Great", color: Color.green.opacity(0.6), description: "Thriving today")
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.backgroundHex
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Main content
                ScrollView {
                    VStack(spacing: 48) {
                        // Mood selection
                        moodSelectionSection
                        
                        // Activities section
                        activitiesSection
                        
                        // Happy thing section
                        happyThingSection
                        
                        // Complete button
                        completeButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            
            // Celebration overlay
            celebrationOverlay
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your First Reflection")
                        .font(.system(size: 32, weight: .ultraLight, design: .default))
                        .foregroundColor(.textMainHex)
                        .tracking(0.5)
                    
                    Text("Take a moment to reflect on your day")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Divider()
                .background(Color.mediumGreyHex.opacity(0.2))
        }
    }
    
    // MARK: - Mood Selection Section
    
    private var moodSelectionSection: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("How are you feeling right now?")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.textMainHex)
                    .tracking(0.3)
                
                Text("Tap the feeling that best describes you today")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
            }
            
            // Sophisticated mood selection
            VStack(spacing: 20) {
                ForEach(Array(moodLevels.enumerated()), id: \.offset) { index, mood in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMood = index
                        }
                        HapticManager.shared.lightImpact()
                    }) {
                        HStack(spacing: 20) {
                            // Mood indicator circle
                            ZStack {
                                Circle()
                                    .fill(mood.color)
                                    .frame(width: selectedMood == index ? 50 : 40, height: selectedMood == index ? 50 : 40)
                                    .overlay(
                                        Circle()
                                            .stroke(mood.color.opacity(0.3), lineWidth: selectedMood == index ? 3 : 1)
                                            .frame(width: selectedMood == index ? 60 : 48, height: selectedMood == index ? 60 : 48)
                                    )
                                    .shadow(color: mood.color.opacity(0.3), radius: selectedMood == index ? 12 : 6, x: 0, y: selectedMood == index ? 6 : 3)
                                
                                if selectedMood == index {
                                    Circle()
                                        .fill(mood.color.opacity(0.2))
                                        .frame(width: 70, height: 70)
                                        .blur(radius: 8)
                                }
                            }
                            
                            // Mood text
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mood.name)
                                    .font(.system(size: 18, weight: selectedMood == index ? .semibold : .medium))
                                    .foregroundColor(.textMainHex)
                                
                                Text(mood.description)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.mediumGreyHex)
                            }
                            
                            Spacer()
                            
                            // Selection indicator
                            if selectedMood == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(mood.color)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedMood == index ? mood.color.opacity(0.08) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedMood == index ? mood.color.opacity(0.3) : Color.mediumGreyHex.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Activities Section
    
    private var activitiesSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What did you do today?")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.textMainHex)
                
                Text("Select activities that were part of your day")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(suggestedActivities, id: \.self) { activity in
                    Button(action: {
                        if selectedActivities.contains(activity) {
                            selectedActivities.remove(activity)
                        } else {
                            selectedActivities.insert(activity)
                        }
                        HapticManager.shared.lightImpact()
                    }) {
                        Text(activity)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedActivities.contains(activity) ? .white : .textMainHex)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedActivities.contains(activity) ? 
                                          LinearGradient(colors: [moodLevels[selectedMood].color, moodLevels[selectedMood].color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) : 
                                          LinearGradient(colors: [Color.backgroundHex, Color.backgroundHex], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedActivities.contains(activity) ? Color.clear : Color.mediumGreyHex.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Happy Thing Section
    
    private var happyThingSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("What made you happy today?")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.textMainHex)
                
                Text("Even small things count - a good coffee, a text from a friend...")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .trailing, spacing: 8) {
                TextField("", text: $happyThing, prompt: Text("I felt good about today...").foregroundColor(.mediumGreyHex.opacity(0.7)))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.textMainHex)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.backgroundHex)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.mediumGreyHex.opacity(0.2), lineWidth: 1)
                            )
                    )
                
                Text("Optional")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.mediumGreyHex.opacity(0.7))
            }
        }
    }
    
    // MARK: - Complete Button
    
    private var completeButton: some View {
        Button(action: {
            submitFirstCheckIn()
        }) {
            HStack(spacing: 12) {
                Text("Complete Your First Reflection")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [
                        moodLevels[selectedMood].color.opacity(0.9),
                        moodLevels[selectedMood].color.opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: moodLevels[selectedMood].color.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Celebration Overlay
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        if showingCelebration {
            ZStack {
                // Background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                // Celebration card
                VStack(spacing: 32) {
                    // Celebration icon
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                colors: [
                                    moodLevels[selectedMood].color.opacity(0.8),
                                    moodLevels[selectedMood].color.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: moodLevels[selectedMood].color.opacity(0.3), radius: 16, x: 0, y: 8)
                        
                        Circle()
                            .fill(moodLevels[selectedMood].color.opacity(0.2))
                            .frame(width: 24, height: 24)
                    }
                    
                    // Celebration text
                    VStack(spacing: 16) {
                        Text("Congratulations!")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(.textMainHex)
                            .tracking(0.5)
                        
                        Text("You've completed your first reflection. This is the beginning of your mindful journey with flect.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.mediumGreyHex)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    
                    // Continue button
                    Button(action: {
                        showingCelebration = false
                        
                        // Mark onboarding as completed
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        
                        // Post notification that onboarding is complete
                        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
                        
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Text("Continue to flect")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [
                                    moodLevels[selectedMood].color.opacity(0.9),
                                    moodLevels[selectedMood].color.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: moodLevels[selectedMood].color.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.backgroundHex)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 32)
            }
        }
    }
    
    // MARK: - Functions
    
    private func submitFirstCheckIn() {
        // Create first check-in
        let checkIn = DailyCheckIn(
            id: UUID(),
            date: Date(),
            happyThing: happyThing.isEmpty ? "Starting my flect journey!" : happyThing,
            improveThing: "", // Empty for first check-in
            moodEmoji: moodLevels[selectedMood].name
        )
        
        // Save to CheckInService
        CheckInService.shared.saveCheckIn(checkIn)
        
        // Show celebration
        withAnimation(.easeInOut(duration: 0.3)) {
            showingCelebration = true
        }
        
        HapticManager.shared.success()
    }
}

// MARK: - Supporting Models

struct ReflectionMoodLevel {
    let name: String
    let color: Color
    let description: String
}

#Preview {
    FirstCheckInView()
} 