import SwiftUI

struct AIChatView: View {
    @StateObject private var goalService = GoalService.shared
    @State private var currentMessage = ""
    @State private var isTyping = false
    @Environment(\.dismiss) private var dismiss
    
    let chatSession: ChatSession
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Messages
                messagesSection
                
                // Input
                messageInputSection
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.mediumGreyHex)
                .font(.subheadline)
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("AI Coach")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text("Daily Reflection Chat")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                Button("⚙️") {
                    // TODO: Settings
                }
                .foregroundColor(.accentHex)
                .font(.title2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Context summary
            contextSummarySection
        }
        .background(Color.cardBackgroundHex)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var contextSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Context")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Text(DateFormatter.localizedString(from: chatSession.date, dateStyle: .medium, timeStyle: .none))
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            if !chatSession.goalContext.isEmpty {
                HStack {
                    Text("Goals:")
                        .font(.caption2)
                        .foregroundColor(.mediumGreyHex)
                    
                    ForEach(goalService.activeGoals.filter { chatSession.goalContext.contains($0.id) }, id: \.id) { goal in
                        HStack(spacing: 4) {
                            Text(goal.category.emoji)
                            Text(goal.title)
                                .font(.caption2)
                                .foregroundColor(.textMainHex)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: goal.category.color).opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Messages Section
    
    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(chatSession.messages, id: \.id) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if isTyping {
                        TypingIndicator()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: chatSession.messages.count) { _ in
                if let lastMessage = chatSession.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Input Section
    
    private var messageInputSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TextField("Type your message...", text: $currentMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.cardBackgroundHex)
                    .cornerRadius(20)
                    .lineLimit(1, reservesSpace: false)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentHex)
                }
                .disabled(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .animation(.easeInOut(duration: 0.2), value: currentMessage.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 34) // Account for safe area
        }
        .background(Color.backgroundHex)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: -1)
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let messageText = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: messageText, type: .user)
        goalService.addMessageToSession(chatSession.id, message: userMessage)
        
        // Clear input
        currentMessage = ""
        
        // Show typing indicator
        isTyping = true
        HapticManager.shared.selection()
        
        // Get AI response
        Task {
            let aiResponse = await goalService.getAIResponse(for: messageText, in: chatSession.id)
            
            await MainActor.run {
                isTyping = false
                
                // Add AI response after a brief delay for realism
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    goalService.addMessageToSession(chatSession.id, message: aiResponse)
                    HapticManager.shared.lightImpact()
                }
            }
        }
    }
}

// MARK: - Message Bubble Component

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.type == .user {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.type == .user ? .trailing : .leading, spacing: 4) {
                if message.type == .ai {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: message.type.backgroundColor))
                            .frame(width: 8, height: 8)
                        
                        Text(message.type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.mediumGreyHex)
                        
                        Spacer()
                    }
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.type == .user ? .white : .textMainHex)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: message.type.backgroundColor))
                    .cornerRadius(16)
                
                Text(DateFormatter.localizedString(from: message.timestamp, dateStyle: .none, timeStyle: .short))
                    .font(.caption2)
                    .foregroundColor(.mediumGreyHex)
            }
            
            if message.type == .ai {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Typing Indicator Component

struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: MessageType.ai.backgroundColor))
                        .frame(width: 8, height: 8)
                    
                    Text("AI Coach")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.mediumGreyHex)
                    
                    Spacer()
                }
                
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.gray)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: animationPhase)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.cardBackgroundHex)
                .cornerRadius(16)
            }
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animationPhase = 0
        }
    }
}

// MARK: - Preview

struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView(chatSession: ChatSession(
            goalContext: [],
            brainDumpContext: "Had a great workout today and worked on my business plan.",
            moodContext: "😊 Good"
        ))
    }
} 