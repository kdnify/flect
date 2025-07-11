import SwiftUI

struct PersonalityQuizView: View {
    @State private var currentQuestionIndex = 0
    @State private var answers: [Int: Int] = [:]
    @State private var showingResult = false
    @State private var showingPaywall = false
    @State private var personalityProfile: PersonalityProfile?
    @State private var animateProgress = false
    @State private var animateQuestionChange = false
    
    @StateObject private var userPreferences = UserPreferencesService.shared
    @Environment(\.dismiss) private var dismiss
    
    let onCompleted: (PersonalityProfile) -> Void
    
    private var currentQuestion: PersonalityQuestion {
        PersonalityQuiz.questions[currentQuestionIndex]
    }
    
    private var progress: Double {
        Double(currentQuestionIndex) / Double(PersonalityQuiz.questions.count)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with progress
                headerView
                    .padding(.top, geometry.safeAreaInsets.top + 16)
                    .padding(.horizontal, 32)
                
                if showingResult, let profile = personalityProfile {
                    // Results view
                    personalityResultView(profile: profile)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    // Quiz question
                    questionView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                
                Spacer()
            }
            .background(
                LinearGradient(
                    colors: [Color.backgroundHex, Color.blue.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .ignoresSafeArea(.all, edges: .top)
        .onAppear {
            animateProgress = true
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            TrialPaywallView(
                onStartTrial: {
                    userPreferences.startTrial()
                    showingPaywall = false
                    completeQuizFlow()
                },
                onSkip: {
                    showingPaywall = false
                    completeQuizFlow()
                }
            )
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.textMainHex)
                }
                
                Spacer()
                
                if !showingResult {
                    Text("\(currentQuestionIndex + 1) of \(PersonalityQuiz.questions.count)")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
            }
            
            if !showingResult {
                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(CustomProgressViewStyle())
                    .scaleEffect(x: animateProgress ? 1 : 0, y: 1, anchor: .leading)
                    .animation(.easeOut(duration: 0.8), value: animateProgress)
            }
        }
    }
    
    // MARK: - Question View
    
    private var questionView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 24) {
                // Question number indicator
                Text("Question \(currentQuestionIndex + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentHex)
                    .tracking(1)
                
                // Question text
                Text(currentQuestion.question)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.textMainHex)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateQuestionChange ? 1 : 0)
                    .offset(y: animateQuestionChange ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: animateQuestionChange)
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)
            
            // Answer options
            VStack(spacing: 16) {
                ForEach(0..<currentQuestion.answers.count, id: \.self) { answerIndex in
                    PersonalityAnswerCard(
                        answer: currentQuestion.answers[answerIndex],
                        isSelected: answers[currentQuestionIndex] == answerIndex,
                        index: answerIndex
                    ) {
                        selectAnswer(answerIndex)
                    }
                    .opacity(animateQuestionChange ? 1 : 0)
                    .offset(y: animateQuestionChange ? 0 : 30)
                    .animation(
                        .easeOut(duration: 0.5)
                        .delay(0.3 + Double(answerIndex) * 0.1),
                        value: animateQuestionChange
                    )
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            animateQuestionChange = true
        }
        .onChange(of: currentQuestionIndex) { _ in
            animateQuestionChange = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateQuestionChange = true
            }
        }
    }
    
    // MARK: - Personality Result View
    
    private func personalityResultView(profile: PersonalityProfile) -> some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                // Personality type icon
                Text(profile.primaryType.emoji)
                    .font(.system(size: 64))
                    .scaleEffect(animateQuestionChange ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateQuestionChange)
                
                VStack(spacing: 12) {
                    Text("You're")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mediumGreyHex)
                    
                    Text(profile.primaryType.title)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.textMainHex)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateQuestionChange ? 1 : 0)
                .offset(y: animateQuestionChange ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateQuestionChange)
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)
            
            // Description
            VStack(spacing: 20) {
                Text(profile.primaryType.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.textMainHex)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateQuestionChange ? 1 : 0)
                    .offset(y: animateQuestionChange ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateQuestionChange)
                
                Text("Communication style: \(profile.primaryType.communicationStyle)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                    .opacity(animateQuestionChange ? 1 : 0)
                    .offset(y: animateQuestionChange ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: animateQuestionChange)
            }
            .padding(.horizontal, 32)
            
            // Continue button
            Button(action: completeQuiz) {
                Text("Unlock Your Personalized Experience")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)
            .scaleEffect(animateQuestionChange ? 1 : 0.9)
            .opacity(animateQuestionChange ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateQuestionChange)
        }
        .onAppear {
            animateQuestionChange = true
        }
    }
    
    // MARK: - Actions
    
    private func selectAnswer(_ answerIndex: Int) {
        answers[currentQuestionIndex] = answerIndex
        HapticManager.shared.lightImpact()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            nextQuestion()
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < PersonalityQuiz.questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentQuestionIndex += 1
                animateProgress = true
            }
        } else {
            // Calculate personality and show result
            let profile = PersonalityQuiz.calculatePersonality(from: answers)
            personalityProfile = profile
            
            withAnimation(.easeInOut(duration: 0.5)) {
                showingResult = true
            }
        }
    }
    
    private func completeQuiz() {
        guard let profile = personalityProfile else { return }
        
        // Save personality profile first
        userPreferences.savePersonalityProfile(profile)
        HapticManager.shared.success()
        
        // Show paywall unless they already have premium access or used trial
        if !userPreferences.hasAccessToPremiumFeatures && !userPreferences.hasUsedTrial {
            showingPaywall = true
        } else {
            // Skip paywall if they already have access or used trial
            completeQuizFlow()
        }
    }
    
    private func completeQuizFlow() {
        guard let profile = personalityProfile else { return }
        onCompleted(profile)
    }
}

// MARK: - Answer Card

struct PersonalityAnswerCard: View {
    let answer: PersonalityAnswer
    let isSelected: Bool
    let index: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection indicator
                Circle()
                    .stroke(isSelected ? Color.accentHex : Color.mediumGreyHex, lineWidth: 2)
                    .fill(isSelected ? Color.accentHex : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                // Answer text
                Text(answer.text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .textMainHex : .mediumGreyHex)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentHex.opacity(0.08) : Color.cardBackgroundHex)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentHex.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Progress View Style

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.mediumGreyHex.opacity(0.3))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                        height: 4
                    )
                    .animation(.easeOut(duration: 0.3), value: configuration.fractionCompleted)
            }
        }
        .frame(height: 4)
    }
} 