import SwiftUI

struct PostSubmissionView: View {
    @StateObject private var goalService = GoalService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAIChat = false
    @State private var showingCallOption = false
    @State private var coachMessage: String = ""
    @State private var isLoadingCoachMessage = true
    
    let dailyBrainDump: DailyBrainDump
    let selectedMood: MoodLevel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                Spacer()
                // Main content: Only the coach message
                if isLoadingCoachMessage {
                    ProgressView("Getting your coach's message...")
                        .padding()
                } else {
                    coachMessageSection
                }
                Spacer()
                // Action buttons: Only show AI chat if coach message loaded
                if !isLoadingCoachMessage {
                    actionButtonsSection
                }
                Spacer()
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
            .onAppear {
                fetchCoachMessage()
            }
        }
        .sheet(isPresented: $showingAIChat) {
            if let session = getCurrentChatSession() {
                AIChatView(chatSession: session)
            }
        }
        .sheet(isPresented: $showingCallOption) {
            CallOptionView(
                dailyBrainDump: dailyBrainDump,
                selectedMood: selectedMood
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.mediumGreyHex)
                .font(.subheadline)
                
                Spacer()
                
                Text("Daily Check-In Complete")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                // Placeholder for symmetry
                Text("Done")
                    .foregroundColor(.clear)
                    .font(.subheadline)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Success indicator
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                Text("Great job reflecting on your day!")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 16)
        }
        .background(Color.cardBackgroundHex)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Coach Message Section
    private var coachMessageSection: some View {
        VStack(spacing: 24) {
            Text("Message from your Coach")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
                .multilineTextAlignment(.center)
            Text(coachMessage)
                .font(.body)
                .foregroundColor(.mediumGreyHex)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Call option
            Button(action: { 
                showingCallOption = true
                HapticManager.shared.mediumImpact()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice Call")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Talk it out with your AI coach")
                            .font(.caption)
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .opacity(0.6)
                }
                .foregroundColor(.white)
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            
            // Text option
            Button(action: { 
                showingAIChat = true
                HapticManager.shared.mediumImpact()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "message.fill")
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Text Chat")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Have a conversation via messages")
                            .font(.caption)
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .opacity(0.6)
                }
                .foregroundColor(.textMainHex)
                .padding(20)
                .background(Color.cardBackgroundHex)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.mediumGreyHex.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Skip for now
            Button(action: {
                HapticManager.shared.lightImpact()
                dismiss()
            }) {
                Text("Skip for now")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }
    
    // MARK: - Fetch Coach Message
    private func fetchCoachMessage() {
        isLoadingCoachMessage = true
        print("[DEBUG] fetchCoachMessage called")
        Task {
            let message = await goalService.getCheckInCoachMessage(
                mood: selectedMood,
                brainDump: dailyBrainDump
            )
            await MainActor.run {
                print("[DEBUG] Coach message received: \(message)")
                if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    coachMessage = "(Could not load your coach's message. But I'm still proud of you for checking in today!)"
                } else {
                    coachMessage = message
                }
                isLoadingCoachMessage = false
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getCurrentChatSession() -> ChatSession? {
        // Check if there's already a chat session for today
        if let existingSession = goalService.getTodaysChatSession() {
            return existingSession
        }
        
        // Create a new chat session
        return goalService.createChatSession(from: dailyBrainDump, mood: "\(selectedMood.emoji) \(selectedMood.name)")
    }
}

// MARK: - Call Option View (Placeholder)

struct CallOptionView: View {
    @Environment(\.dismiss) private var dismiss
    
    let dailyBrainDump: DailyBrainDump
    let selectedMood: MoodLevel
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "phone.badge.waveform.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Voice Call Feature")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.textMainHex)
                    
                    Text("Voice calling with AI coach is coming soon! For now, try the text chat option.")
                        .font(.body)
                        .foregroundColor(.mediumGreyHex)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button("Got it") {
                    dismiss()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.bottom, 40)
            }
            .background(Color.backgroundHex)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct PostSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        PostSubmissionView(
            dailyBrainDump: DailyBrainDump(
                goalsWorkedOn: [],
                brainDumpContent: "Had a great workout today and worked on my business plan. Feeling motivated!"
            ),
            selectedMood: MoodLevel.good
        )
    }
} 