import SwiftUI

struct GoalOnboardingView: View {
    @StateObject private var goalService = GoalService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var selectedCategory: GoalCategory = .health
    @State private var goalTitle = ""
    @State private var goalDescription = ""
    @State private var communicationStyle: CommunicationStyle = .encouraging
    @State private var accountabilityLevel: AccountabilityLevel = .moderate
    @State private var showingSuccess = false
    
    private let totalSteps = 4
    // Animation state for logo
    @State private var logoPulse = false
    
    // Completion handler for onboarding flow
    var onGoalCreated: (() -> Void)?

    var body: some View {
        ZStack {
            // Brand background gradient
            LinearGradient(
                colors: [Color.backgroundHex, Color.purple.opacity(0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                progressBar
                
                // Main content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    categoryStep.tag(1)
                    goalDetailsStep.tag(2)
                    aiPersonalizationStep.tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
                
                // Navigation buttons
                navigationButtons
            }
        }
        .sheet(isPresented: $showingSuccess) {
            GoalSuccessView {
                goalService.markUserAsOnboarded()
                // Complete the onboarding flow
                onGoalCreated?()
                dismiss()
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : LinearGradient(
                            colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 12, height: 12)
                        .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? LinearGradient(
                                colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) : LinearGradient(
                                colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.08)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 2)
                            .animation(.easeInOut, value: currentStep)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Step 1: Welcome
    
    private var welcomeStep: some View {
        let greeting: String = {
            // Example: personalize based on selectedCategory or user preferences
            if selectedCategory == .mindfulness {
                return "Let’s gently set an intention for your next 12 weeks."
            } else if selectedCategory == .career || selectedCategory == .fitness {
                return "Let’s set a bold goal and track your progress together."
            } else {
                return "Let’s plan your first goal for the next 12 weeks."
            }
        }()
        return ScrollView {
            VStack(spacing: 30) {
                Spacer().frame(height: 40)
                // Animated logo (matches WelcomeView)
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [
                            Color.orange.opacity(logoPulse ? 0.9 : 0.8),
                            Color.purple.opacity(logoPulse ? 0.8 : 0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: logoPulse ? 90 : 80, height: logoPulse ? 90 : 80)
                    .shadow(color: .orange.opacity(0.3), radius: 16, x: 0, y: 8)
                    .scaleEffect(logoPulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: logoPulse)
                    .onAppear { logoPulse = true }
                VStack(spacing: 16) {
                    Text(greeting)
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.textMainHex)
                        .multilineTextAlignment(.center)
                    Text("Your AI accountability coach")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.mediumGreyHex)
                        .multilineTextAlignment(.center)
                }
                VStack(spacing: 20) {
                    FeatureRow(
                        icon: "calendar",
                        title: "12-Week Goals",
                        description: "Set meaningful goals with a proven timeframe"
                    )
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "AI Coaching",
                        description: "Unlock personalized conversations as you progress"
                    )
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Smart Insights",
                        description: "See how your mood impacts your goal progress"
                    )
                }
                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 30)
        }
    }
    
    // MARK: - Step 2: Category Selection
    
    private var categoryStep: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("What's your focus?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Choose the area where you want to make progress over the next 12 weeks")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(GoalCategory.allCases, id: \.self) { category in
                        CategoryCard(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                            withAnimation(.spring()) {
                                // Auto-advance after selection
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if currentStep < totalSteps - 1 {
                                        currentStep += 1
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 60)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Step 3: Goal Details
    
    private var goalDetailsStep: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("What's your goal?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Be specific about what you want to achieve in 12 weeks")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Title")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("e.g. Run my first 5K", text: $goalTitle)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Describe your goal in detail...", text: $goalDescription, axis: .vertical)
                            .textFieldStyle(CustomTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Category preview
                    HStack {
                        Image(systemName: selectedCategory.icon)
                            .foregroundColor(Color(hex: selectedCategory.color))
                        Text(selectedCategory.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: selectedCategory.color).opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 60)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Step 4: AI Personalization
    
    private var aiPersonalizationStep: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Text("Personalize your AI coach")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("How would you like your AI coach to communicate with you?")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 24) {
                    // Communication Style
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Communication Style")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(CommunicationStyle.allCases, id: \.self) { style in
                            StyleSelectionRow(
                                title: style.rawValue.capitalized,
                                description: style.description,
                                isSelected: communicationStyle == style
                            ) {
                                communicationStyle = style
                            }
                        }
                    }
                    
                    // Accountability Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accountability Level")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(AccountabilityLevel.allCases, id: \.self) { level in
                            StyleSelectionRow(
                                title: level.rawValue.capitalized,
                                description: level.description,
                                isSelected: accountabilityLevel == level
                            ) {
                                accountabilityLevel = level
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 60)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.easeInOut) {
                        currentStep -= 1
                    }
                }
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            }
            
            Button(currentStep == totalSteps - 1 ? "Create Goal" : "Next") {
                if currentStep == totalSteps - 1 {
                    createGoal()
                } else {
                    withAnimation(.easeInOut) {
                        currentStep += 1
                    }
                }
            }
            .disabled(currentStep == 2 && (goalTitle.isEmpty || goalDescription.isEmpty))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Group {
                    if currentStep == 2 && (goalTitle.isEmpty || goalDescription.isEmpty) {
                        Color.gray.opacity(0.5)
                    } else {
                        LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(25)
            .shadow(color: .blue.opacity(0.15), radius: 8, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    
    private func createGoal() {
        let _ = goalService.createGoal(
            title: goalTitle,
            description: goalDescription,
            category: selectedCategory,
            communicationStyle: communicationStyle,
            accountabilityLevel: accountabilityLevel
        )
        
        showingSuccess = true
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: "#4ECDC4"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct CategoryCard: View {
    let category: GoalCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        // Compute label color for readability
        let labelColor: Color = {
            if category == .finance {
                return Color(hex: "#7A5C00")
            } else if category == .career {
                return Color(hex: "#28564C")
            } else {
                return Color.textMainHex
            }
        }()
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title)
                    .foregroundColor(Color(hex: category.color).opacity(0.8))
                // Always show label below icon
                Text(category.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(labelColor)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: category.color).opacity(isSelected ? 0.25 : 0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.08) : .clear, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StyleSelectionRow: View {
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? Color(hex: "#4ECDC4") : Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#4ECDC4"), lineWidth: isSelected ? 0 : 2)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Success View

struct GoalSuccessView: View {
    var onContinue: () -> Void
    @State private var animate = false
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                // Animated gradient ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.25), Color.purple.opacity(0.18), Color.orange.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 10
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animate ? 1.08 : 1.0)
                    .opacity(animate ? 1 : 0.8)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
                // Animated checkmark
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color.green)
                    .scaleEffect(animate ? 1.08 : 1.0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.6).repeatForever(autoreverses: true), value: animate)
            }
            .onAppear { animate = true }
            VStack(spacing: 12) {
                Text("Goal Created! 🎯")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.textMainHex)
                Text("Your 12-week journey starts now. Track daily progress to unlock AI coaching conversations.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.heart.fill")
                        .foregroundColor(.accentHex)
                    Text("3+ day streak = Daily AI Chat")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textMainHex)
                }
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundColor(.accentHex)
                    Text("5+ days/week = Weekly Coaching")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textMainHex)
                }
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.accentHex)
                    Text("20+ days/month = Strategic Planning")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textMainHex)
                }
            }
            .padding(.top, 8)
            Spacer()
            Button(action: onContinue) {
                Text("Start Tracking")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.15), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 32)
            Spacer(minLength: 24)
        }
        .background(Color.backgroundHex)
        .ignoresSafeArea()
    }
}

struct SuccessFeature: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

#Preview {
    GoalOnboardingView()
} 