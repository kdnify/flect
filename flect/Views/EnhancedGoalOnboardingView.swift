import SwiftUI

struct EnhancedGoalOnboardingView: View {
    @StateObject private var goalService = GoalService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var goalTitle = ""
    @State private var goalDescription = ""
    @State private var selectedCategory: GoalCategory = .health
    @State private var selectedFrequency: GoalFrequency = .daily
    @State private var selectedFlexibility: FlexibilityLevel = .balanced
    @State private var showingFrequencyHelp = false
    @State private var showingFlexibilityHelp = false
    @State private var isProcessing = false
    @State private var smartSuggestions: [SmartSuggestion] = []
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with progress
                headerSection
                
                // Main content
                ScrollView {
                    VStack(spacing: 32) {
                        // Step content
                        stepContent
                        
                        // Navigation buttons
                        navigationButtons
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFrequencyHelp) {
            FrequencyHelpView()
        }
        .sheet(isPresented: $showingFlexibilityHelp) {
            FlexibilityHelpView()
        }
        .onAppear {
            generateSmartSuggestions()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.mediumGreyHex)
                
                Spacer()
                
                Text("Goal Setup")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                // Step indicator
                Text("\(currentStep + 1)/\(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.mediumGreyHex.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentHex)
                        .frame(width: geometry.size.width * (Double(currentStep + 1) / Double(totalSteps)), height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
        }
        .background(Color.cardBackgroundHex)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            goalBasicsStep
        case 1:
            categorySelectionStep
        case 2:
            frequencySelectionStep
        case 3:
            flexibilitySelectionStep
        case 4:
            reviewAndConfirmStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Step 1: Goal Basics
    
    private var goalBasicsStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your goal?")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.textMainHex)
                
                Text("Be specific about what you want to achieve")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal Title")
                        .font(.headline)
                        .foregroundColor(.textMainHex)
                    
                    TextField("e.g., Run a 5K", text: $goalTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.headline)
                        .foregroundColor(.textMainHex)
                    
                    TextField("Why is this important to you?", text: $goalDescription, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .lineLimit(3...6)
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Step 2: Category Selection
    
    private var categorySelectionStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose a category")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.textMainHex)
                
                Text("This helps us give you better suggestions")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(GoalCategory.allCases, id: \.self) { category in
                    EnhancedCategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        onSelect: { selectedCategory = category }
                    )
                }
            }
        }
    }
    
    // MARK: - Step 3: Frequency Selection
    
    private var frequencySelectionStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("How often?")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                    
                    Button(action: { showingFrequencyHelp = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.accentHex)
                    }
                }
                
                Text("Choose what works best for your schedule")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
            }
            
            // Suggested frequencies based on category
            if !selectedCategory.suggestedFrequencies.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommended for \(selectedCategory.displayName)")
                        .font(.caption)
                        .foregroundColor(.accentHex)
                        .textCase(.uppercase)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(selectedCategory.suggestedFrequencies, id: \.displayName) { frequency in
                            EnhancedFrequencyCard(
                                frequency: frequency,
                                isSelected: selectedFrequency.displayName == frequency.displayName,
                                isRecommended: true,
                                onSelect: { selectedFrequency = frequency }
                            )
                        }
                    }
                }
            }
            
            // All frequency options
            VStack(alignment: .leading, spacing: 12) {
                Text("All Options")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
                    .textCase(.uppercase)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach([GoalFrequency.daily, .thriceWeekly, .twiceWeekly, .weekly], id: \.displayName) { frequency in
                        EnhancedFrequencyCard(
                            frequency: frequency,
                            isSelected: selectedFrequency.displayName == frequency.displayName,
                            isRecommended: selectedCategory.suggestedFrequencies.contains { $0.displayName == frequency.displayName },
                            onSelect: { selectedFrequency = frequency }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: Flexibility Selection
    
    private var flexibilitySelectionStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("How flexible?")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                    
                    Button(action: { showingFlexibilityHelp = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.accentHex)
                    }
                }
                
                Text("Choose your accountability style")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
            }
            
            VStack(spacing: 16) {
                ForEach(FlexibilityLevel.allCases, id: \.self) { level in
                    EnhancedFlexibilityCard(
                        level: level,
                        isSelected: selectedFlexibility == level,
                        onSelect: { selectedFlexibility = level }
                    )
                }
            }
        }
    }
    
    // MARK: - Step 5: Review and Confirm
    
    private var reviewAndConfirmStep: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Review your goal")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.textMainHex)
                
                Text("Make sure everything looks good")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
            }
            
            VStack(spacing: 16) {
                // Goal preview card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(selectedCategory.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goalTitle)
                                .font(.headline)
                                .foregroundColor(.textMainHex)
                            
                            Text(selectedCategory.displayName)
                                .font(.caption)
                                .foregroundColor(.mediumGreyHex)
                        }
                        
                        Spacer()
                    }
                    
                    if !goalDescription.isEmpty {
                        Text(goalDescription)
                            .font(.body)
                            .foregroundColor(.mediumGreyHex)
                    }
                    
                    // Frequency and flexibility info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Frequency:")
                                .font(.caption)
                                .foregroundColor(.mediumGreyHex)
                            
                            Text(selectedFrequency.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                        }
                        
                        HStack {
                            Text("Style:")
                                .font(.caption)
                                .foregroundColor(.mediumGreyHex)
                            
                            Text(selectedFlexibility.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                        }
                    }
                }
                .padding(20)
                .background(Color.cardBackgroundHex)
                .cornerRadius(16)
                
                // Smart suggestions
                if !smartSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Smart Suggestions")
                            .font(.caption)
                            .foregroundColor(.accentHex)
                            .textCase(.uppercase)
                        
                        ForEach(smartSuggestions.prefix(3), id: \.id) { suggestion in
                            HStack {
                                Image(systemName: suggestion.type.icon)
                                    .foregroundColor(.accentHex)
                                
                                Text(suggestion.title)
                                    .font(.caption)
                                    .foregroundColor(.textMainHex)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(16)
                    .background(Color.accentHex.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if currentStep > 0 {
                Button(action: { currentStep -= 1 }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.mediumGreyHex)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color.cardBackgroundHex)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            // Next/Create button
            Button(action: {
                if currentStep < totalSteps - 1 {
                    currentStep += 1
                } else {
                    createGoal()
                }
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text(currentStep == totalSteps - 1 ? "Create Goal" : "Next")
                        
                        if currentStep < totalSteps - 1 {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(isNextButtonEnabled ? Color.accentHex : Color.mediumGreyHex)
                .cornerRadius(12)
            }
            .disabled(!isNextButtonEnabled || isProcessing)
        }
    }
    
    // MARK: - Helper Properties
    
    private var isNextButtonEnabled: Bool {
        switch currentStep {
        case 0: return !goalTitle.isEmpty
        case 1: return true // Category always selected
        case 2: return true // Frequency always selected
        case 3: return true // Flexibility always selected
        case 4: return true // Review step
        default: return false
        }
    }
    
    // MARK: - Actions
    
    private func createGoal() {
        isProcessing = true
        
        // Create the 12-week goal
        let twelveWeekGoal = TwelveWeekGoal(
            title: goalTitle,
            description: goalDescription,
            category: selectedCategory,
            aiContext: GoalAIContext(
                preferredCommunicationStyle: .encouraging,
                accountabilityLevel: selectedFlexibility == .strict ? .intense : 
                                   selectedFlexibility == .balanced ? .moderate : .gentle
            )
        )
        
        // Create the frequency goal
        let frequencyGoal = FrequencyGoal(
            parentGoalId: twelveWeekGoal.id,
            title: goalTitle,
            frequency: selectedFrequency,
            flexibilityLevel: selectedFlexibility,
            endDate: twelveWeekGoal.targetDate
        )
        
        // Add to goal service
        goalService.activeGoals.append(twelveWeekGoal)
        // goalService.saveGoals() // This is private, saving is handled internally
        
        // Show success feedback
        HapticManager.shared.success()
        
        // Dismiss after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
    
    private func generateSmartSuggestions() {
        // Generate smart suggestions based on selected options
        smartSuggestions = [
            SmartSuggestion(
                type: .scheduling,
                title: "Set up reminders for \(selectedFrequency.suggestedDays.joined(separator: ", "))",
                description: "Schedule notifications to help you stay on track",
                priority: .medium
            ),
            SmartSuggestion(
                type: .motivation,
                title: "Start with 10-minute sessions",
                description: "Build the habit first, then increase duration",
                priority: .high
            ),
            SmartSuggestion(
                type: .efficiency,
                title: "Track your mood before and after",
                description: "See how your goal affects your wellbeing",
                priority: .low
            )
        ]
    }
}

// MARK: - Supporting Views

struct EnhancedCategoryCard: View {
    let category: GoalCategory
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Text(category.emoji)
                    .font(.title2)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textMainHex)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentHex.opacity(0.1) : Color.cardBackgroundHex)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentHex : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedFrequencyCard: View {
    let frequency: GoalFrequency
    let isSelected: Bool
    let isRecommended: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(frequency.shortName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                    
                    if isRecommended {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Text(frequency.description)
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(isSelected ? Color.accentHex.opacity(0.1) : Color.cardBackgroundHex)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentHex : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedFlexibilityCard: View {
    let level: FlexibilityLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                Text(level.displayName)
                    .font(.headline)
                    .foregroundColor(.textMainHex)
                
                Text(level.description)
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                
                Text(level.motivationStyle)
                    .font(.caption)
                    .foregroundColor(.accentHex)
                    .italic()
            }
            .padding(16)
            .background(isSelected ? Color.accentHex.opacity(0.1) : Color.cardBackgroundHex)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentHex : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FrequencyHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Choosing Your Frequency")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textMainHex)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        helpSection(
                            title: "Daily",
                            description: "Best for building habits and momentum",
                            examples: ["Morning meditation", "Reading", "Exercise"]
                        )
                        
                        helpSection(
                            title: "3x per week",
                            description: "Ideal for fitness and skill development",
                            examples: ["Strength training", "Language practice", "Creative work"]
                        )
                        
                        helpSection(
                            title: "2x per week",
                            description: "Great for steady progress without pressure",
                            examples: ["Meal prep", "Networking", "Learning new skills"]
                        )
                        
                        helpSection(
                            title: "Weekly",
                            description: "Perfect for bigger projects and planning",
                            examples: ["Financial review", "Deep work sessions", "Relationship check-ins"]
                        )
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func helpSection(title: String, description: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textMainHex)
            
            Text(description)
                .font(.body)
                .foregroundColor(.mediumGreyHex)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(examples, id: \.self) { example in
                    Text("• \(example)")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
    }
}

struct FlexibilityHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Flexibility Levels")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textMainHex)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(FlexibilityLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(level.displayName)
                                    .font(.headline)
                                    .foregroundColor(.textMainHex)
                                
                                Text(level.description)
                                    .font(.body)
                                    .foregroundColor(.mediumGreyHex)
                                
                                Text(level.reminderStyle)
                                    .font(.caption)
                                    .foregroundColor(.accentHex)
                                    .italic()
                            }
                            .padding(16)
                            .background(Color.cardBackgroundHex)
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

struct EnhancedGoalOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedGoalOnboardingView()
    }
} 