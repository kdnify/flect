import SwiftUI

struct QuickCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var checkInService = CheckInService.shared
    @State private var happyThing: String = ""
    @State private var improveThing: String = ""
    @State private var selectedMood: String = "Neutral"
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var savedCheckIn: DailyCheckIn?
    @State private var moodAnimation: [String: Bool] = [:]
    
    private let moodEmojis = ["😌", "😊", "😃", "🤔", "😤", "😔", "😴", "😰"]
    
    var canSubmit: Bool {
        !happyThing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !improveThing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    moodSection
                    questionsSection
                    submitSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSuccess) {
            if let checkIn = savedCheckIn {
                CheckInSuccessView(checkIn: checkIn)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.mediumGreyHex)
                
                Spacer()
                
                Text("Quick Check-in")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                // Debug: Reset to sample data button
                Button("🧪") {
                    checkInService.resetToSampleData()
                }
                .foregroundColor(.accentHex)
                .font(.title2)
            }
            .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("How was your day?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.textMainHex)
                
                Text("Just two quick questions to help you reflect")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
            }
        }
    }
    
    // MARK: - Mood Section
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling?")
                .font(.headline)
                .foregroundColor(.textMainHex)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(moodEmojis, id: \.self) { emoji in
                        Button(action: {
                            selectedMood = moodNameFromEmoji(emoji)
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                moodAnimation[emoji] = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                moodAnimation[emoji] = false
                            }
                        }) {
                            ZStack {
                                if selectedMood == emoji {
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 4
                                        )
                                        .frame(width: 64, height: 64)
                                        .shadow(color: Color.purple.opacity(0.12), radius: 8, x: 0, y: 4)
                                }
                                Circle()
                                    .fill(selectedMood == emoji ? Color.accentHex.opacity(0.13) : Color.cardBackgroundHex)
                                    .frame(width: 60, height: 60)
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .scaleEffect(moodAnimation[emoji] == true ? 1.18 : 1.0)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: moodAnimation[emoji])
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Questions Section
    
    private var questionsSection: some View {
        VStack(spacing: 20) {
            // Happy thing question
            QuestionCard(
                icon: "heart.fill",
                iconColor: .accentHex,
                question: "What's one thing that made you happy today?",
                placeholder: "e.g., had coffee with a friend, finished a project...",
                text: $happyThing
            )
            
            // Improve thing question
            QuestionCard(
                icon: "arrow.up.circle.fill",
                iconColor: .accentHex,
                question: "What's one thing you could improve tomorrow?",
                placeholder: "e.g., get more sleep, call mom, organize desk...",
                text: $improveThing
            )
        }
    }
    
    // MARK: - Submit Section
    
    private var submitSection: some View {
        VStack(spacing: 16) {
            if isSubmitting {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Saving your check-in...")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                .padding(.vertical)
            } else {
                PrimaryButton(
                    title: "Complete Check-in",
                    action: {
                        submitCheckIn()
                    },
                    isDisabled: !canSubmit
                )
            }
            
            // Character counts for guidance
            if !happyThing.isEmpty || !improveThing.isEmpty {
                HStack {
                    if !happyThing.isEmpty {
                        Text("Happy: \(happyThing.count) chars")
                            .font(.caption2)
                            .foregroundColor(.mediumGreyHex)
                    }
                    
                    Spacer()
                    
                    if !improveThing.isEmpty {
                        Text("Improve: \(improveThing.count) chars")
                            .font(.caption2)
                            .foregroundColor(.mediumGreyHex)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions

    private func moodNameFromEmoji(_ emoji: String) -> String {
        switch emoji {
        case "😌": return "Neutral"
        case "😊": return "Good"
        case "😃": return "Great"
        case "🤔": return "Neutral"
        case "😤": return "Okay"
        case "😔": return "Rough"
        case "😴": return "Okay"
        case "😰": return "Rough"
        default: return "Neutral"
        }
    }

    private func submitCheckIn() {
        isSubmitting = true
        HapticManager.shared.success()
        
        Task {
            do {
                let checkIn = try await checkInService.submitCheckIn(
                    happyThing: happyThing.trimmingCharacters(in: .whitespacesAndNewlines),
                    improveThing: improveThing.trimmingCharacters(in: .whitespacesAndNewlines),
                    moodName: selectedMood // Use moodName directly
                )
                
                await MainActor.run {
                    isSubmitting = false
                    savedCheckIn = checkIn
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // Show error state
                }
            }
        }
    }
}

// MARK: - Question Card Component

struct QuestionCard: View {
    let icon: String
    let iconColor: Color
    let question: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                    
                    Text(question)
                        .font(.headline)
                        .foregroundColor(.textMainHex)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                TextEditor(text: $text)
                    .font(.body)
                    .foregroundColor(.textMainHex)
                    .frame(minHeight: 80)
                    .padding(.horizontal, -4) // TextEditor has built-in padding
                    .overlay(
                        Group {
                            if text.isEmpty {
                                VStack {
                                    HStack {
                                        Text(placeholder)
                                            .font(.body)
                                            .foregroundColor(.mediumGreyHex)
                                            .opacity(0.7)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .padding(.top, 8)
                                .padding(.leading, 0)
                                .allowsHitTesting(false)
                            }
                        }
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuickCheckInView()
} 