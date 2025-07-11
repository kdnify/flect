import SwiftUI

struct SprintCreationView: View {
    let goal: TwelveWeekGoal
    let aiSuggestions: [SprintSuggestion]
    
    @StateObject private var goalService = GoalService.shared
    @StateObject private var sprintService = SprintService.shared
    @State private var createdSprints: [Sprint] = []
    @State private var currentStep = 0
    @State private var showingSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if currentStep == 0 {
                    sprintReviewSection
                } else if currentStep == 1 {
                    sprintCustomizationSection
                } else {
                    successSection
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
        .onAppear {
            createSprintsFromSuggestions()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        currentStep -= 1
                    }
                    .foregroundColor(.mediumGreyHex)
                    .font(.subheadline)
                } else {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.mediumGreyHex)
                    .font(.subheadline)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Create Sprints")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text("Step \(currentStep + 1) of 3")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                if currentStep == 0 {
                    Button("Next") {
                        currentStep += 1
                    }
                    .foregroundColor(.accentHex)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                } else if currentStep == 1 {
                    Button("Create") {
                        saveSprints()
                        currentStep += 1
                    }
                    .foregroundColor(.accentHex)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                } else {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentHex)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 20)
        }
        .background(Color.cardBackgroundHex)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Sprint Review Section
    
    private var sprintReviewSection: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Goal summary
                goalSummarySection
                
                // Sprint overview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your 4-Week Sprint Plan")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text("Based on your goal and personality, here's how we suggest breaking down your 12-week goal into manageable 4-week sprints:")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                    
                    ForEach(Array(createdSprints.enumerated()), id: \.offset) { index, sprint in
                        SprintPreviewCard(sprint: sprint, weekNumber: index + 1)
                    }
                }
                
                // Next step info
                VStack(spacing: 12) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.accentHex)
                    
                    Text("Customize Your Sprints")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text("In the next step, you can customize each sprint's milestones and tasks to better fit your preferences.")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(Color.cardBackgroundHex)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Sprint Customization Section
    
    private var sprintCustomizationSection: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Customize Your Sprints")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Review and customize each sprint. You can edit titles, descriptions, and milestones to better fit your needs.")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(Array(createdSprints.enumerated()), id: \.offset) { index, sprint in
                    SprintCustomizationCard(
                        sprint: $createdSprints[index],
                        weekNumber: index + 1
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Success Section
    
    private var successSection: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // Success animation
                LottieView(name: "success_animation")
                    .frame(width: 120, height: 120)
                
                VStack(spacing: 16) {
                    Text("Sprints Created! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textMainHex)
                    
                    Text("Your 4-week sprint plan is ready. You can now track your progress week by week and stay focused on your goals.")
                        .font(.body)
                        .foregroundColor(.mediumGreyHex)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Sprint summary
                VStack(spacing: 12) {
                    Text("Sprint Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("\(createdSprints.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.accentHex)
                            Text("Sprints")
                                .font(.caption)
                                .foregroundColor(.mediumGreyHex)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(createdSprints.reduce(0) { $0 + $1.targetMilestones.count })")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.accentHex)
                            Text("Milestones")
                                .font(.caption)
                                .foregroundColor(.mediumGreyHex)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(createdSprints.reduce(0) { $0 + $1.tasks.count })")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.accentHex)
                            Text("Tasks")
                                .font(.caption)
                                .foregroundColor(.mediumGreyHex)
                        }
                    }
                }
                .padding(20)
                .background(Color.cardBackgroundHex)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Start Your First Sprint")
                        .font(.headline)
                        .fontWeight(.semibold)
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
                
                Button(action: { dismiss() }) {
                    Text("View All Sprints")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helper Views
    
    private var goalSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.category.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text(goal.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                Text("\(goal.progressPercentage)%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentHex)
            }
            
            ProgressView(value: goal.currentProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentHex))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .padding(16)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Actions
    
    private func createSprintsFromSuggestions() {
        createdSprints = sprintService.createSprints(for: goal, suggestions: aiSuggestions)
    }
    
    private func saveSprints() {
        // Sprints are already saved in SprintService.createSprints()
        showingSuccess = true
    }
}

// MARK: - Sprint Preview Card

struct SprintPreviewCard: View {
    let sprint: Sprint
    let weekNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    
                    Text(sprint.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                }
                
                Spacer()
                
                Text("\(sprint.targetMilestones.count) milestones")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            Text(sprint.description)
                .font(.subheadline)
                .foregroundColor(.mediumGreyHex)
                .lineLimit(2)
            
            // Quick milestone preview
            if !sprint.targetMilestones.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Key Milestones")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    ForEach(sprint.targetMilestones.prefix(2), id: \.id) { milestone in
                        HStack(spacing: 8) {
                            Image(systemName: "flag.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text(milestone.title)
                                .font(.caption)
                                .foregroundColor(.mediumGreyHex)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Sprint Customization Card

struct SprintCustomizationCard: View {
    @Binding var sprint: Sprint
    let weekNumber: Int
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
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
                    
                    Text(sprint.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textMainHex)
                        
                        TextField("Sprint description", text: $sprint.description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Milestones
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Milestones")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textMainHex)
                        
                        ForEach(Array(sprint.targetMilestones.enumerated()), id: \.offset) { index, milestone in
                            HStack(spacing: 12) {
                                TextField("Milestone title", text: milestoneTitleBinding(for: index))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button(action: {
                                    sprint.targetMilestones.remove(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        Button(action: {
                            let newMilestone = SprintMilestone(
                                title: "New Milestone",
                                description: "Custom milestone",
                                targetDate: Date()
                            )
                            sprint.targetMilestones.append(newMilestone)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Milestone")
                            }
                            .foregroundColor(.accentHex)
                            .font(.subheadline)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Methods
    
    private func milestoneTitleBinding(for index: Int) -> Binding<String> {
        Binding(
            get: { sprint.targetMilestones[index].title },
            set: { sprint.targetMilestones[index].title = $0 }
        )
    }
}

// MARK: - Lottie View (Placeholder)

struct LottieView: View {
    let name: String
    
    var body: some View {
        // Placeholder for Lottie animation
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(.green)
    }
}

// MARK: - Preview

struct SprintCreationView_Previews: PreviewProvider {
    static var previews: some View {
        SprintCreationView(
            goal: TwelveWeekGoal(
                title: "Learn SwiftUI",
                description: "Master iOS development with SwiftUI",
                category: .learning,
                aiContext: GoalAIContext()
            ),
            aiSuggestions: []
        )
    }
} 