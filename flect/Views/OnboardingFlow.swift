import SwiftUI

struct OnboardingFlow: View {
    @State private var currentStep = 0
    @State private var selectedGoals: Set<WellnessGoal> = []
    @State private var selectedFrequency: CheckInFrequency = .daily
    @State private var notificationsEnabled = true
    @State private var showingFirstCheckIn = false
    @Environment(\.dismiss) private var dismiss
    
    let totalSteps = 3
    // Animation states
    @State private var animateStep = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top safe area padding
                Rectangle()
                    .fill(Color.backgroundHex)
                    .frame(height: geometry.safeAreaInsets.top)
                    .ignoresSafeArea(.all, edges: .top)
                
                // Main content
                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                        .padding(.top, 24)
                        .padding(.horizontal, 32)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        goalSelectionView
                            .tag(0)
                            .opacity(animateStep ? 1 : 0)
                            .offset(y: animateStep ? 0 : 40)
                            .animation(.easeOut(duration: 0.5), value: animateStep)
                        
                        frequencySelectionView
                            .tag(1)
                            .opacity(animateStep ? 1 : 0)
                            .offset(y: animateStep ? 0 : 40)
                            .animation(.easeOut(duration: 0.5), value: animateStep)
                        
                        notificationView
                            .tag(2)
                            .opacity(animateStep ? 1 : 0)
                            .offset(y: animateStep ? 0 : 40)
                            .animation(.easeOut(duration: 0.5), value: animateStep)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                    
                    // Bottom actions
                    bottomActions
                        .padding(.horizontal, 32)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.backgroundHex, Color.purple.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(.all, edges: .top)
            .onAppear { animateStep = true }
            .onChange(of: currentStep) { _ in
                animateStep = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { animateStep = true }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingFirstCheckIn) {
            FirstCheckInView()
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 12) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        index <= currentStep ?
                        LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Goal Selection View
    
    private var goalSelectionView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("What brings you to flect?")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.textMainHex)
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                
                Text("Select what you'd like to focus on")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(WellnessGoal.allCases, id: \.self) { goal in
                    GoalSelectionCard(
                        goal: goal,
                        isSelected: selectedGoals.contains(goal)
                    ) {
                        if selectedGoals.contains(goal) {
                            selectedGoals.remove(goal)
                        } else {
                            selectedGoals.insert(goal)
                        }
                        HapticManager.shared.lightImpact()
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Frequency Selection View
    
    private var frequencySelectionView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("How often do you want to check in?")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.textMainHex)
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                
                Text("You can always change this later")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(CheckInFrequency.allCases, id: \.self) { frequency in
                    FrequencySelectionCard(
                        frequency: frequency,
                        isSelected: selectedFrequency == frequency
                    ) {
                        selectedFrequency = frequency
                        HapticManager.shared.lightImpact()
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Notification View
    
    private var notificationView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // Notification icon
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [
                            Color.orange.opacity(0.8),
                            Color.pink.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "bell.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)
                
                VStack(spacing: 16) {
                    Text("Stay on track with gentle reminders")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.textMainHex)
                        .multilineTextAlignment(.center)
                        .tracking(0.5)
                    
                    Text("We'll send you a mindful notification at the perfect time")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mediumGreyHex)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    notificationsEnabled = true
                    HapticManager.shared.lightImpact()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: notificationsEnabled ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(notificationsEnabled ? .blue : .gray)
                        
                        Text("Yes, send me gentle reminders")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textMainHex)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(notificationsEnabled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                            .stroke(
                                notificationsEnabled ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    notificationsEnabled = false
                    HapticManager.shared.lightImpact()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: !notificationsEnabled ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(!notificationsEnabled ? .blue : .gray)
                        
                        Text("No thanks, I'll remember on my own")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textMainHex)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(!notificationsEnabled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                            .stroke(
                                !notificationsEnabled ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.mediumGreyHex)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            Button(action: {
                if currentStep < totalSteps - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    // Complete onboarding
                    completeOnboarding()
                }
                HapticManager.shared.lightImpact()
            }) {
                HStack(spacing: 12) {
                    Text(currentStep < totalSteps - 1 ? "Continue" : "Start Your Journey")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.9),
                            Color.purple.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(currentStep == 0 && selectedGoals.isEmpty)
        }
    }
    
    // MARK: - Functions
    
    private func completeOnboarding() {
        // Save preferences
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Save selected goals
        let goalStrings = selectedGoals.map { $0.rawValue }
        UserDefaults.standard.set(goalStrings, forKey: "selectedWellnessGoals")
        
        // Save frequency
        UserDefaults.standard.set(selectedFrequency.rawValue, forKey: "checkInFrequency")
        
        // Save notification preference
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        
        // Show first check-in
        showingFirstCheckIn = true
    }
}

// MARK: - Supporting Types
// Enums are now defined in UserPreferencesService.swift

// MARK: - Goal Selection Card

struct GoalSelectionCard: View {
    let goal: WellnessGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: goal.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: goal.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textMainHex)
                    
                    Text(goal.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color.cardBackgroundHex)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.08) : .clear, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Frequency Selection Card

struct FrequencySelectionCard: View {
    let frequency: CheckInFrequency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(frequency.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textMainHex)
                    
                    Text(frequency.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color.cardBackgroundHex)
                    .stroke(
                        isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingFlow()
} 