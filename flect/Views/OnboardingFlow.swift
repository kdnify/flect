import SwiftUI

struct OnboardingFlow: View {
    @State private var currentStep = 0
    @State private var notificationsEnabled = true
    @State private var showingGoalOnboarding = false
    @State private var showingPersonalityQuiz = false
    @Environment(\.dismiss) private var dismiss
    
    let totalSteps = 2  // Reduced to 2: Notifications → Personality Quiz
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
                        notificationView
                            .tag(0)
                            .opacity(animateStep ? 1 : 0)
                            .offset(y: animateStep ? 0 : 40)
                            .animation(.easeOut(duration: 0.5), value: animateStep)
                        
                        personalityIntroView
                            .tag(1)
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
        .fullScreenCover(isPresented: $showingGoalOnboarding) {
            GoalOnboardingView {
                // Goal created successfully, complete onboarding
                completeOnboarding()
            }
        }
        .fullScreenCover(isPresented: $showingPersonalityQuiz) {
            PersonalityQuizView { profile in
                showingPersonalityQuiz = false
                // After personality quiz, show goal onboarding
                showingGoalOnboarding = true
            }
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
    
    // MARK: - Goal Selection View (Removed)
    // Goals will now be set in EnhancedGoalOnboardingView after personality quiz
    
    // MARK: - Frequency Selection Removed
    // Frequency selection moved to personality quiz question 5
    
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
    
    // MARK: - Personality Intro View
    
    private var personalityIntroView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // Personality icon
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [
                            Color.purple.opacity(0.8),
                            Color.blue.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "brain.filled.head.profile")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 12, x: 0, y: 6)
                
                VStack(spacing: 16) {
                    Text("Let's get to know you")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.textMainHex)
                        .multilineTextAlignment(.center)
                        .tracking(0.5)
                    
                    Text("Answer a few quick questions so we can personalize your flect experience")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mediumGreyHex)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.purple.opacity(0.8))
                    
                    Text("Personalized language and insights")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                    
                    Text("Tailored motivation and encouragement")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green.opacity(0.8))
                    
                    Text("Smarter pattern recognition")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
            
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
                    // Show personality quiz
                    showingPersonalityQuiz = true
                }
                HapticManager.shared.lightImpact()
            }) {
                HStack(spacing: 12) {
                    Text(currentStep < totalSteps - 1 ? "Continue" : "Take Personality Quiz")
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
        }
    }
    
    // MARK: - Functions
    
    private func completeOnboarding() {
        // Save preferences
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Save notification preference
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        
        // Post notification to complete onboarding (ContentView will handle this)
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
        
        // Note: Goals will be set in GoalOnboardingView
        // First check-in will be available from the main app after goal setup
        
        // Dismiss the onboarding flow to return to main app
        dismiss()
    }
}

// MARK: - Supporting Types
// Enums are now defined in UserPreferencesService.swift

// MARK: - Goal Selection Card (Removed)
// Goals are now handled in EnhancedGoalOnboardingView

// MARK: - Frequency Selection Card (Removed)
// Frequency selection moved to personality quiz

#Preview {
    OnboardingFlow()
} 