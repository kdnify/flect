import SwiftUI

struct DaylioCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var checkInService = CheckInService.shared
    @StateObject private var goalService = GoalService.shared
    @State private var selectedMood: MoodLevel = .neutral
    @State private var selectedActivities: Set<Activity> = []
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var savedCheckIn: DailyCheckIn?
    @State private var showingPostSubmission = false
    
    // Brain dump state
    @State private var dailyBrainDump = DailyBrainDump()
    
    // Modern mood levels to match FirstCheckInView design
    private let modernMoodLevels = [
        ReflectionMoodLevel(name: "Rough", color: Color.red.opacity(0.6), description: "Challenging day"),
        ReflectionMoodLevel(name: "Okay", color: Color.orange.opacity(0.6), description: "Getting through"),
        ReflectionMoodLevel(name: "Neutral", color: Color.gray.opacity(0.6), description: "Balanced state"),
        ReflectionMoodLevel(name: "Good", color: Color.blue.opacity(0.6), description: "Positive energy"),
        ReflectionMoodLevel(name: "Great", color: Color.green.opacity(0.6), description: "Thriving today")
    ]
    
    @State private var selectedMoodIndex = 2 // Start with neutral
    
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
                        // Modern mood selection
                        modernMoodSelectionSection
                        
                        // Activities section
                        modernActivitiesSection
                        
                        // Goal progress section (if user has active goals)
                        if !goalService.activeGoals.isEmpty {
                            goalProgressSection
                        }
                        
                        // Submit section
                        modernSubmitSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
        .sheet(isPresented: $showingSuccess) {
            if let checkIn = savedCheckIn {
                CheckInSuccessView(checkIn: checkIn)
            }
        }
        .sheet(isPresented: $showingPostSubmission) {
            PostSubmissionView(
                dailyBrainDump: dailyBrainDump,
                selectedMood: selectedMood
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            // Map modern mood to old MoodLevel for compatibility
            updateSelectedMood()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.mediumGreyHex)
                
                Spacer()
                
                Text(currentDateString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                // Remove debug button for cleaner design
                Text("")
                    .frame(width: 40) // Balance the layout
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            VStack(spacing: 12) {
                Text("Daily Reflection")
                    .font(.system(size: 32, weight: .ultraLight, design: .default))
                    .foregroundColor(.textMainHex)
                    .tracking(0.5)
                
                Text("Take a moment to reflect on your day")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
            }
            .padding(.horizontal, 24)
            
            Divider()
                .background(Color.mediumGreyHex.opacity(0.2))
        }
    }
    
    // MARK: - Modern Mood Selection
    
    private var modernMoodSelectionSection: some View {
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
                ForEach(Array(modernMoodLevels.enumerated()), id: \.offset) { index, mood in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMoodIndex = index
                            updateSelectedMood()
                        }
                        HapticManager.shared.lightImpact()
                    }) {
                        HStack(spacing: 20) {
                            // Mood indicator circle
                            ZStack {
                                Circle()
                                    .fill(mood.color)
                                    .frame(width: selectedMoodIndex == index ? 50 : 40, height: selectedMoodIndex == index ? 50 : 40)
                                    .overlay(
                                        Circle()
                                            .stroke(mood.color.opacity(0.3), lineWidth: selectedMoodIndex == index ? 3 : 1)
                                            .frame(width: selectedMoodIndex == index ? 60 : 48, height: selectedMoodIndex == index ? 60 : 48)
                                    )
                                    .shadow(color: mood.color.opacity(0.3), radius: selectedMoodIndex == index ? 12 : 6, x: 0, y: selectedMoodIndex == index ? 6 : 3)
                                
                                if selectedMoodIndex == index {
                                    Circle()
                                        .fill(mood.color.opacity(0.2))
                                        .frame(width: 70, height: 70)
                                        .blur(radius: 8)
                                }
                            }
                            
                            // Mood text
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mood.name)
                                    .font(.system(size: 18, weight: selectedMoodIndex == index ? .semibold : .medium))
                                    .foregroundColor(.textMainHex)
                                
                                Text(mood.description)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.mediumGreyHex)
                            }
                            
                            Spacer()
                            
                            // Selection indicator
                            if selectedMoodIndex == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(mood.color)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedMoodIndex == index ? mood.color.opacity(0.08) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedMoodIndex == index ? mood.color.opacity(0.3) : Color.mediumGreyHex.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Modern Activities Section
    
    private var modernActivitiesSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("What did you do today?")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.textMainHex)
                
                Text("Select activities that were part of your day")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Activity.allCases, id: \.self) { activity in
                    Button(action: {
                        toggleActivity(activity)
                        HapticManager.shared.lightImpact()
                    }) {
                        Text(activity.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedActivities.contains(activity) ? .white : .textMainHex)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedActivities.contains(activity) ? 
                                          LinearGradient(colors: [modernMoodLevels[selectedMoodIndex].color, modernMoodLevels[selectedMoodIndex].color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) : 
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
    
    // MARK: - Goal Progress Section
    
    private var goalProgressSection: some View {
        GoalBrainDumpCard(
            goals: goalService.activeGoals,
            brainDump: $dailyBrainDump,
            selectedMood: selectedMood
        )
    }
    
    // MARK: - Modern Submit Section
    
    private var modernSubmitSection: some View {
        VStack(spacing: 16) {
            if isSubmitting {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .accentColor(modernMoodLevels[selectedMoodIndex].color)
                    Text("Saving your reflection...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mediumGreyHex)
                }
                .padding(.vertical, 18)
            } else {
                Button(action: submitCheckIn) {
                    HStack(spacing: 12) {
                        Text("Complete Reflection")
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
                                modernMoodLevels[selectedMoodIndex].color.opacity(0.9),
                                modernMoodLevels[selectedMoodIndex].color.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: modernMoodLevels[selectedMoodIndex].color.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Activity count
            Text("\(selectedActivities.count) activities selected")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.mediumGreyHex)
        }
    }
    
    // MARK: - Helper Functions
    
    private func updateSelectedMood() {
        // Map modern mood index to old MoodLevel enum for compatibility
        switch selectedMoodIndex {
        case 0: selectedMood = .awful
        case 1: selectedMood = .bad
        case 2: selectedMood = .neutral
        case 3: selectedMood = .good
        case 4: selectedMood = .amazing
        default: selectedMood = .neutral
        }
    }
    
    // MARK: - Helper Properties
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: CheckInService.shared.now) // Use simulated date
    }
    
    // MARK: - Actions
    
    private func toggleActivity(_ activity: Activity) {
        HapticManager.shared.lightImpact()
        
        if selectedActivities.contains(activity) {
            selectedActivities.remove(activity)
        } else {
            selectedActivities.insert(activity)
        }
    }
    
    private func submitCheckIn() {
        isSubmitting = true
        HapticManager.shared.success()
        
        Task {
            do {
                // Convert to our existing format
                let moodName = selectedMood.name // Use mood name instead of emoji
                let happyThing = selectedActivities.map { $0.name }.joined(separator: ", ")
                let improveThing = dailyBrainDump.brainDumpContent.isEmpty ? "No specific improvements noted" : dailyBrainDump.brainDumpContent
                
                let checkIn = try await checkInService.submitCheckIn(
                    happyThing: happyThing,
                    improveThing: improveThing,
                    moodName: moodName
                )
                
                // Save brain dump if there's content
                if !dailyBrainDump.brainDumpContent.isEmpty || !dailyBrainDump.goalsWorkedOn.isEmpty {
                    goalService.saveDailyBrainDump(dailyBrainDump)
                }
                
                await MainActor.run {
                    savedCheckIn = checkIn
                    isSubmitting = false
                    
                    // Show post-submission flow only if brain dump is complete
                    if dailyBrainDump.isAIChatUnlocked {
                        showingPostSubmission = true
                    } else {
                        showingSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // TODO: Show error state
                    print("Error submitting check-in: \(error)")
                }
            }
        }
    }
}

// MARK: - Mood Level Enum

enum MoodLevel: CaseIterable {
    case awful, bad, neutral, good, amazing
    
    var name: String {
        switch self {
        case .awful: return "Awful"
        case .bad: return "Bad"
        case .neutral: return "Okay"
        case .good: return "Good"
        case .amazing: return "Amazing"
        }
    }
    
    var emoji: String {
        switch self {
        case .awful: return "😢"
        case .bad: return "😞"
        case .neutral: return "😐"
        case .good: return "😊"
        case .amazing: return "😍"
        }
    }
    
    var color: Color {
        switch self {
        case .awful: return Color.red
        case .bad: return Color.orange
        case .neutral: return Color.yellow
        case .good: return Color.green
        case .amazing: return Color.purple
        }
    }
    
    var value: Int {
        switch self {
        case .awful: return 1
        case .bad: return 2
        case .neutral: return 3
        case .good: return 4
        case .amazing: return 5
        }
    }
}

// MARK: - Activity Enum

enum Activity: String, CaseIterable {
    case work, exercise, friends, family, food, shopping, entertainment, travel, sleep, learning
    
    var name: String {
        switch self {
        case .work: return "Work"
        case .exercise: return "Exercise"
        case .friends: return "Friends"
        case .family: return "Family"
        case .food: return "Food"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .travel: return "Travel"
        case .sleep: return "Sleep"
        case .learning: return "Learning"
        }
    }
    
    var icon: String {
        switch self {
        case .work: return "briefcase"
        case .exercise: return "figure.run"
        case .friends: return "person.3"
        case .family: return "house"
        case .food: return "fork.knife"
        case .shopping: return "bag"
        case .entertainment: return "tv"
        case .travel: return "airplane"
        case .sleep: return "bed.double"
        case .learning: return "book"
        }
    }
    

}

// MARK: - Activity Tag Component

struct ActivityTag: View {
    let activity: Activity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: activity.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentHex)
                
                Text(activity.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .textMainHex)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentHex : Color.cardBackgroundHex)
            )
        }
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Success View

struct DaylioSuccessView: View {
    let checkIn: DailyCheckIn
    let mood: MoodLevel
    let activities: Set<Activity>
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Circle()
                    .fill(mood.color)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(mood.emoji)
                            .font(.system(size: 40))
                    )
                    .shadow(color: mood.color.opacity(0.3), radius: 20)
                
                Text("Day saved!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textMainHex)
                
                Text("You felt \(mood.name.lowercased()) today")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                
                if !activities.isEmpty {
                    Text("Activities: \(activities.map { $0.name }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            Button("Continue") {
                onDismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(mood.color)
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .background(Color.backgroundHex)
    }
}

// MARK: - Simple Success View

struct CheckInSuccessView: View {
    let checkIn: DailyCheckIn
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 10)
                
                Text("Check-in saved!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textMainHex)
                
                Text("Thanks for sharing how you're feeling today.")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button("Continue") {
                NotificationCenter.default.post(name: Notification.Name("checkInCompleted"), object: nil)
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.accentHex)
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .background(Color.backgroundHex)
    }
}

// MARK: - Goal Progress Brain Dump Component

struct GoalBrainDumpCard: View {
    let goals: [TwelveWeekGoal]
    @Binding var brainDump: DailyBrainDump
    let selectedMood: MoodLevel
    @State private var isRecording = false
    @State private var showingVoiceOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                    
                    if brainDump.isAIChatUnlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Ready for submission")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Progress bar toward AI chat unlock
                ProgressView(value: brainDump.progressCompletion)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentHex))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("Tell me about your day \(progressText)")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            // Goal selector
            if !goals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Which goals did you work on today?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(goals) { goal in
                            Button(action: {
                                toggleGoal(goal.id)
                                HapticManager.shared.selection()
                            }) {
                                VStack(spacing: 4) {
                                    Text(goal.category.emoji)
                                        .font(.title2)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(brainDump.goalsWorkedOn.contains(goal.id) ? Color(hex: goal.category.color).opacity(0.2) : Color.gray.opacity(0.1))
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(brainDump.goalsWorkedOn.contains(goal.id) ? Color(hex: goal.category.color) : Color.clear, lineWidth: 2)
                                        )
                                    
                                    Text(goal.title)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.textMainHex)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
            }
            
            // Brain dump input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tell me about your progress, feelings, or thoughts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                    
                    Button(action: { showingVoiceOptions.toggle() }) {
                        Image(systemName: isRecording ? "mic.fill" : "mic")
                            .font(.title3)
                            .foregroundColor(isRecording ? .red : .accentHex)
                    }
                }
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: Binding(
                        get: { brainDump.brainDumpContent },
                        set: { newValue in
                            brainDump.updateContent(newValue)
                        }
                    ))
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    if brainDump.brainDumpContent.isEmpty {
                        Text("Share your thoughts about today's progress...")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                
                // Word/sentence count
                HStack {
                    Text("\(brainDump.wordCount) words, \(brainDump.sentenceCount) sentences")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                    
                    Spacer()
                    
                    if !brainDump.isAIChatUnlocked {
                        Text("Need 2+ sentences to unlock AI chat")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
        .actionSheet(isPresented: $showingVoiceOptions) {
            ActionSheet(
                title: Text("Voice Note"),
                message: Text("Record your thoughts"),
                buttons: [
                    .default(Text("Start Recording")) {
                        startRecording()
                    },
                    .cancel()
                ]
            )
        }

    }
    
    private var progressText: String {
        let completion = brainDump.progressCompletion
        if completion >= 1.0 {
            return "✨ (AI chat unlocked!)"
        } else if completion >= 0.7 {
            return "📝 (almost there!)"
        } else if completion >= 0.3 {
            return "💭 (keep going!)"
        } else {
            return "🎯 (to unlock AI chat)"
        }
    }
    
    private func toggleGoal(_ goalId: UUID) {
        if brainDump.goalsWorkedOn.contains(goalId) {
            brainDump.goalsWorkedOn.remove(goalId)
        } else {
            brainDump.goalsWorkedOn.insert(goalId)
        }
    }
    
    private func startRecording() {
        isRecording = true
        // TODO: Implement voice recording
        // For now, just simulate recording
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRecording = false
        }
    }
}

#Preview {
    DaylioCheckInView()
} 