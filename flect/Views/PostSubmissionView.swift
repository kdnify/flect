import SwiftUI

struct PostSubmissionView: View {
    @StateObject private var goalService = GoalService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAIChat = false
    @State private var showingCallOption = false
    
    let dailyBrainDump: DailyBrainDump
    let selectedMood: MoodLevel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Main content
                Spacer()
                
                mainContentSection
                
                Spacer()
                
                // Action buttons
                actionButtonsSection
                
                Spacer()
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
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
    
    // MARK: - Main Content Section
    
    private var mainContentSection: some View {
        VStack(spacing: 20) {
            // AI Coach prompt
            VStack(spacing: 12) {
                Text("Ready for your daily coaching session?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                    .multilineTextAlignment(.center)
                
                Text("I've reviewed your reflection and I'm here to help you process your day, celebrate wins, and plan ahead.")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Context preview
            contextPreviewSection
        }
        .padding(.horizontal, 20)
    }
    
    private var contextPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Context")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mood:")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    Text("\(selectedMood.emoji) \(selectedMood.name)")
                        .font(.body)
                        .foregroundColor(.mediumGreyHex)
                    
                    Spacer()
                }
                
                if !dailyBrainDump.goalsWorkedOn.isEmpty {
                    HStack {
                        Text("Goals:")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.textMainHex)
                        
                        let relevantGoals = goalService.activeGoals.filter { dailyBrainDump.goalsWorkedOn.contains($0.id) }
                        Text(relevantGoals.map { $0.title }.joined(separator: ", "))
                            .font(.body)
                            .foregroundColor(.mediumGreyHex)
                        
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reflection:")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    Text("\"\(dailyBrainDump.brainDumpContent.prefix(80))\(dailyBrainDump.brainDumpContent.count > 80 ? "..." : "")\"")
                        .font(.body)
                        .foregroundColor(.mediumGreyHex)
                        .italic()
                }
            }
        }
        .padding(16)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
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