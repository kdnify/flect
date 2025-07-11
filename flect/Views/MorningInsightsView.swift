import SwiftUI

struct MorningInsightsView: View {
    @StateObject private var goalService = GoalService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAIChat = false
    @State private var adviceSession: ChatSession?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        morningGreetingSection
                        
                        if let session = adviceSession {
                            adviceContentSection(session)
                        } else {
                            loadingSection
                        }
                        
                        actionButtonsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAIChat) {
            if let session = adviceSession {
                AIChatView(chatSession: session)
            }
        }
        .onAppear {
            loadAdviceSession()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Later") {
                    dismiss()
                }
                .foregroundColor(.mediumGreyHex)
                .font(.subheadline)
                
                Spacer()
                
                Text("Morning Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                // Placeholder for symmetry
                Text("Later")
                    .foregroundColor(.clear)
                    .font(.subheadline)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color.cardBackgroundHex)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Morning Greeting
    
    private var morningGreetingSection: some View {
        VStack(spacing: 16) {
            // Time-based greeting with subtle animation
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeBasedGreeting)
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.textMainHex)
                    
                    Text("Based on yesterday's reflection")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                // Subtle morning indicator
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.orange.opacity(0.3), .yellow.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    )
                    .shadow(color: .orange.opacity(0.2), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    // MARK: - Advice Content
    
    private func adviceContentSection(_ session: ChatSession) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if let firstMessage = session.messages.first, firstMessage.type == .ai {
                // AI advice card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Your AI Coach")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.mediumGreyHex)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Text("Personalized")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentHex)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentHex.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text(firstMessage.content)
                        .font(.body)
                        .foregroundColor(.textMainHex)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                    
                    // Action suggestions if available
                    if let context = firstMessage.messageContext,
                       !context.actionSuggestions.isEmpty {
                        actionSuggestionsView(context.actionSuggestions)
                    }
                }
                .padding(20)
                .background(Color.cardBackgroundHex)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
            
            // Previous day context if available
            if let context = session.previousDayContext {
                previousDayContextView(context)
            }
        }
    }
    
    private func actionSuggestionsView(_ suggestions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Actions")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.mediumGreyHex)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentHex)
                        
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.textMainHex)
                        
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(Color.accentHex.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private func previousDayContextView(_ context: PreviousDayContext) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yesterday's Reflection")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.mediumGreyHex)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 12) {
                // Mood
                HStack {
                    Text("Mood:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    Text(context.previousMood)
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                    
                    Spacer()
                }
                
                // Goals worked on
                if !context.previousGoals.isEmpty {
                    HStack(alignment: .top) {
                        Text("Goals:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textMainHex)
                        
                        let goalNames = goalService.activeGoals
                            .filter { context.previousGoals.contains($0.id) }
                            .map { $0.title }
                            .joined(separator: ", ")
                        
                        Text(goalNames)
                            .font(.subheadline)
                            .foregroundColor(.mediumGreyHex)
                        
                        Spacer()
                    }
                }
                
                // Wins and challenges
                if !context.previousWins.isEmpty || !context.previousChallenges.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if !context.previousWins.isEmpty {
                            insightBadge("✨ Wins", context.previousWins.first!, .green)
                        }
                        
                        if !context.previousChallenges.isEmpty {
                            insightBadge("🎯 Challenges", context.previousChallenges.first!, .orange)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackgroundHex.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mediumGreyHex.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func insightBadge(_ label: String, _ content: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            Text(content)
                .font(.caption)
                .foregroundColor(.textMainHex)
                .lineLimit(2)
        }
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Analyzing yesterday's reflection...")
                .font(.subheadline)
                .foregroundColor(.mediumGreyHex)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Start conversation button
            Button(action: {
                showingAIChat = true
                HapticManager.shared.mediumImpact()
            }) {
                HStack {
                    Text("Start Conversation")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            
            // Save for later
            Button(action: {
                HapticManager.shared.lightImpact()
                dismiss()
            }) {
                Text("I'll read this later")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Properties
    
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Welcome back"
        }
    }
    
    // MARK: - Actions
    
    private func loadAdviceSession() {
        if goalService.shouldShowNextDayAdvice() {
            adviceSession = goalService.createNextDayAdviceSession()
        }
    }
}

// MARK: - Preview

struct MorningInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        MorningInsightsView()
    }
} 