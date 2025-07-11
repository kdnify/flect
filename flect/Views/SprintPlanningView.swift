import SwiftUI

struct SprintPlanningView: View {
    @StateObject private var goalService = GoalService.shared
    @StateObject private var userPreferences = UserPreferencesService.shared
    @State private var selectedGoal: TwelveWeekGoal?
    @State private var showingGoalSelection = false
    @State private var showingSprintCreation = false
    @State private var isLoading = false
    @State private var aiSuggestions: [SprintSuggestion] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                if let selectedGoal = selectedGoal {
                    // Sprint planning content
                    sprintPlanningContent(for: selectedGoal)
                } else {
                    // Goal selection
                    goalSelectionSection
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingGoalSelection) {
            GoalSelectionView(selectedGoal: $selectedGoal)
        }
        .sheet(isPresented: $showingSprintCreation) {
            if let goal = selectedGoal {
                SprintCreationView(goal: goal, aiSuggestions: aiSuggestions)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.mediumGreyHex)
                .font(.subheadline)
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Sprint Planning")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text("Break down your goals into 4-week sprints")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                Button("Help") {
                    // TODO: Show help
                }
                .foregroundColor(.accentHex)
                .font(.subheadline)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if selectedGoal != nil {
                Divider()
                    .padding(.horizontal, 20)
            }
        }
        .background(Color.cardBackgroundHex)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Goal Selection Section
    
    private var goalSelectionSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.accentHex)
                
                Text("Choose a Goal to Plan")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Text("Select a 12-week goal to break it down into manageable 4-week sprints. Our AI will help you create a realistic plan.")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if goalService.activeGoals.isEmpty {
                VStack(spacing: 12) {
                    Text("No active goals found")
                        .font(.headline)
                        .foregroundColor(.mediumGreyHex)
                    
                    Text("Create a goal first to start sprint planning")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                .padding(.vertical, 20)
            } else {
                Button(action: { showingGoalSelection = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        
                        Text("Select Goal")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Sprint Planning Content
    
    private func sprintPlanningContent(for goal: TwelveWeekGoal) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Goal overview
                goalOverviewSection(goal)
                
                // AI suggestions
                if isLoading {
                    loadingSection
                } else if !aiSuggestions.isEmpty {
                    aiSuggestionsSection
                } else {
                    generateSuggestionsSection
                }
                
                // Action buttons
                actionButtonsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private func goalOverviewSection(_ goal: TwelveWeekGoal) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(goal.category.emoji)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text(goal.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(goal.progressPercentage)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentHex)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
            }
            
            Text(goal.description)
                .font(.body)
                .foregroundColor(.mediumGreyHex)
                .lineLimit(3)
            
            // Progress bar
            ProgressView(value: goal.currentProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentHex))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentHex))
            
            Text("AI is planning your sprints...")
                .font(.headline)
                .foregroundColor(.textMainHex)
            
            Text("Analyzing your goal and creating personalized sprint suggestions")
                .font(.subheadline)
                .foregroundColor(.mediumGreyHex)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var generateSuggestionsSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.accentHex)
            
            Text("Get AI Sprint Suggestions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            Text("Our AI will analyze your goal and personality to suggest optimal 4-week sprint breakdowns with milestones and tasks.")
                .font(.subheadline)
                .foregroundColor(.mediumGreyHex)
                .multilineTextAlignment(.center)
            
            Button(action: generateAISuggestions) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "sparkles")
                            .font(.subheadline)
                    }
                    
                    Text(isLoading ? "Planning..." : "Generate Suggestions")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
            .disabled(isLoading)
        }
        .padding(24)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Sprint Suggestions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            ForEach(Array(aiSuggestions.enumerated()), id: \.offset) { index, suggestion in
                SprintSuggestionCard(suggestion: suggestion, weekNumber: index + 1)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if !aiSuggestions.isEmpty {
                Button(action: { showingSprintCreation = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                        
                        Text("Create Sprints")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            
            Button(action: { selectedGoal = nil }) {
                Text("Choose Different Goal")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Actions
    
    private func generateAISuggestions() {
        guard let goal = selectedGoal else { return }
        
        isLoading = true
        
        // TODO: Call AI to generate sprint suggestions
        // For now, create mock suggestions
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            aiSuggestions = createMockSuggestions(for: goal)
            isLoading = false
        }
    }
    
    private func createMockSuggestions(for goal: TwelveWeekGoal) -> [SprintSuggestion] {
        let personalityType = userPreferences.personalityProfile?.primaryType ?? PersonalityType.supporter
        
        switch personalityType {
        case PersonalityType.achiever:
            return [
                SprintSuggestion(
                    weekNumber: 1,
                    title: "Foundation & Planning",
                    description: "Establish clear objectives and create detailed action plans",
                    suggestedMilestones: ["Complete goal breakdown", "Set up tracking systems", "Create timeline"],
                    estimatedTasks: ["Research best practices", "Create project plan", "Set up progress tracking"],
                    focusAreas: ["Planning", "Organization", "Goal Setting"]
                ),
                SprintSuggestion(
                    weekNumber: 2,
                    title: "Execution & Progress",
                    description: "Focus on high-impact actions and measurable progress",
                    suggestedMilestones: ["Complete 25% of major tasks", "Establish daily routines", "Track key metrics"],
                    estimatedTasks: ["Execute core activities", "Monitor progress daily", "Adjust plans as needed"],
                    focusAreas: ["Execution", "Consistency", "Measurement"]
                ),
                SprintSuggestion(
                    weekNumber: 3,
                    title: "Optimization & Scaling",
                    description: "Refine processes and scale successful approaches",
                    suggestedMilestones: ["Optimize workflows", "Scale successful methods", "Prepare for final push"],
                    estimatedTasks: ["Analyze what's working", "Optimize processes", "Scale successful activities"],
                    focusAreas: ["Optimization", "Scaling", "Efficiency"]
                ),
                SprintSuggestion(
                    weekNumber: 4,
                    title: "Completion & Celebration",
                    description: "Finalize remaining tasks and celebrate achievements",
                    suggestedMilestones: ["Complete all major tasks", "Review and document learnings", "Celebrate success"],
                    estimatedTasks: ["Finish remaining work", "Document achievements", "Plan next steps"],
                    focusAreas: ["Completion", "Reflection", "Celebration"]
                )
            ]
        default:
            return [
                SprintSuggestion(
                    weekNumber: 1,
                    title: "Getting Started",
                    description: "Begin your journey with small, manageable steps",
                    suggestedMilestones: ["Set up your workspace", "Create initial plan", "Start first activities"],
                    estimatedTasks: ["Prepare your environment", "Break down your goal", "Begin first steps"],
                    focusAreas: ["Preparation", "Planning", "Getting Started"]
                ),
                SprintSuggestion(
                    weekNumber: 2,
                    title: "Building Momentum",
                    description: "Establish consistent habits and build on early progress",
                    suggestedMilestones: ["Establish daily routines", "Complete first milestone", "Build confidence"],
                    estimatedTasks: ["Create daily habits", "Work on core activities", "Track your progress"],
                    focusAreas: ["Consistency", "Habits", "Progress"]
                ),
                SprintSuggestion(
                    weekNumber: 3,
                    title: "Deepening Commitment",
                    description: "Dive deeper into your goal and overcome challenges",
                    suggestedMilestones: ["Overcome obstacles", "Deepen your practice", "See real progress"],
                    estimatedTasks: ["Address challenges", "Intensify your efforts", "Celebrate progress"],
                    focusAreas: ["Persistence", "Growth", "Overcoming Challenges"]
                ),
                SprintSuggestion(
                    weekNumber: 4,
                    title: "Finishing Strong",
                    description: "Complete your sprint and prepare for what's next",
                    suggestedMilestones: ["Complete sprint goals", "Review your journey", "Plan next steps"],
                    estimatedTasks: ["Finish remaining work", "Reflect on progress", "Plan future sprints"],
                    focusAreas: ["Completion", "Reflection", "Future Planning"]
                )
            ]
        }
    }
}

// MARK: - Sprint Suggestion Card

struct SprintSuggestionCard: View {
    let suggestion: SprintSuggestion
    let weekNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(weekNumber)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentHex)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentHex.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text(suggestion.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                }
                
                Spacer()
            }
            
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundColor(.mediumGreyHex)
                .lineLimit(2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Milestones")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textMainHex)
                
                ForEach(suggestion.suggestedMilestones.prefix(2), id: \.self) { milestone in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(milestone)
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus Areas")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textMainHex)
                
                HStack(spacing: 6) {
                    ForEach(suggestion.focusAreas, id: \.self) { area in
                        Text(area)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Goal Selection View

struct GoalSelectionView: View {
    @Binding var selectedGoal: TwelveWeekGoal?
    @StateObject private var goalService = GoalService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.mediumGreyHex)
                    
                    Spacer()
                    
                    Text("Select Goal")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentHex)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                Divider()
                
                // Goal list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(goalService.activeGoals) { goal in
                            GoalSelectionCard(
                                goal: goal,
                                isSelected: selectedGoal?.id == goal.id
                            ) {
                                selectedGoal = goal
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
    }
}

struct GoalSelectionCard: View {
    let goal: TwelveWeekGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(goal.category.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text(goal.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(goal.progressPercentage)%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentHex)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(16)
            .background(Color.cardBackgroundHex)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct SprintPlanningView_Previews: PreviewProvider {
    static var previews: some View {
        SprintPlanningView()
    }
} 