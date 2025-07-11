import SwiftUI

struct HistoryView: View {
    @StateObject private var checkInService = CheckInService.shared
    @State private var selectedTimeframe: TimeframeFilter = .month
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !checkInService.checkIns.isEmpty {
                        timeframeSelector
                        moodPatternsCard
                        checkInsList
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("History")
        }
    }
    
    // MARK: - Subviews
    
    private var timeframeSelector: some View {
        HStack(spacing: 12) {
            ForEach(TimeframeFilter.allCases, id: \.self) { timeframe in
                Button(action: {
                    selectedTimeframe = timeframe
                }) {
                    Text(timeframe.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .mediumGreyHex)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTimeframe == timeframe ? Color.accentHex : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.mediumGreyHex, lineWidth: 1)
                                .opacity(selectedTimeframe == timeframe ? 0 : 1)
                        )
                }
            }
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.mediumGreyHex)
            
            Text("Start Your Journey")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            Text("Complete your first check-in to start tracking patterns and insights")
                .font(.body)
                .foregroundColor(.mediumGreyHex)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 100)
    }
    
    private var moodPatternsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.accentHex)
                    
                    Text("Mood Patterns")
                        .font(.headline)
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                }
                
                // Mood trend visualization
                HStack(spacing: 8) {
                    ForEach(filteredCheckIns.suffix(7).indices, id: \.self) { index in
                        let checkIn = filteredCheckIns.suffix(7)[index]
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.moodColor(for: checkIn.moodEmoji))
                                .frame(width: 24, height: 24)
                                .shadow(color: Color.moodColor(for: checkIn.moodEmoji).opacity(0.15), radius: 4, x: 0, y: 1)
                                .overlay(
                                    Circle().stroke(Color.borderColorHex, lineWidth: 1)
                                )
                                .accessibilityLabel("Mood: \(checkIn.moodEmoji)")
                            Text(dayOfWeek(checkIn.date))
                                .font(.caption2)
                                .foregroundColor(.mediumGreyHex)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                if filteredCheckIns.count >= 3 {
                    Text(moodTrendText)
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                        .italic()
                }
            }
        }
    }
    
    private var checkInsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Reflections")
                    .font(.headline)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Text("\(filteredCheckIns.count) total")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(filteredCheckIns.reversed()) { checkIn in
                    CheckInHistoryCard(checkIn: checkIn)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var filteredCheckIns: [DailyCheckIn] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeframe {
        case .week:
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            return checkInService.checkIns.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return checkInService.checkIns.filter { $0.date >= monthAgo }
        case .all:
            return checkInService.checkIns
        }
    }
    
    private var moodTrendText: String {
        let recentMoods = filteredCheckIns.suffix(7).map { moodScore(from: $0.moodEmoji) }
        if recentMoods.count < 3 { return "Keep checking in to see patterns!" }
        
        let recent = Array(recentMoods.suffix(3))
        let earlier = Array(recentMoods.prefix(3))
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let earlierAvg = earlier.reduce(0, +) / Double(earlier.count)
        let trend = recentAvg - earlierAvg
        
        if trend > 0.1 {
            return "📈 Your mood has been trending upward recently"
        } else if trend < -0.1 {
            return "📉 You might be going through a challenging period"
        } else {
            return "➡️ Your mood has been fairly consistent"
        }
    }
    
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    // Helper function to convert emoji to numerical score
    private func moodScore(from emoji: String) -> Double {
        switch emoji {
        case "😭", "😢", "☹️", "😞": return 0.2
        case "😔", "😕", "🙁": return 0.4
        case "😐", "😌", "😑": return 0.6
        case "🙂", "😊", "😄": return 0.8
        case "😁", "😆", "🤩", "😍", "🥳": return 1.0
        default: return 0.6 // Default neutral
        }
    }
}

struct CheckInHistoryCard: View {
    let checkIn: DailyCheckIn
    @State private var isExpanded = false
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Circle()
                        .fill(Color.moodColor(for: checkIn.moodEmoji))
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.moodColor(for: checkIn.moodEmoji).opacity(0.15), radius: 6, x: 0, y: 2)
                        .overlay(
                            Circle().stroke(Color.borderColorHex, lineWidth: 1)
                        )
                        .accessibilityLabel("Mood: \(checkIn.moodEmoji)")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatDate(checkIn.date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textMainHex)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.mediumGreyHex)
                            .font(.caption)
                    }
                }
                
                // Content preview
                VStack(alignment: .leading, spacing: 8) {
                    if !checkIn.happyThing.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text("😊")
                            Text(checkIn.happyThing)
                                .font(.subheadline)
                                .foregroundColor(.textMainHex)
                                .lineLimit(isExpanded ? nil : 2)
                        }
                    }
                    
                    if !checkIn.improveThing.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text("🎯")
                            Text(checkIn.improveThing)
                                .font(.subheadline)
                                .foregroundColor(.textMainHex)
                                .lineLimit(isExpanded ? nil : 2)
                        }
                    }
                }
                
                // AI response if expanded
                if isExpanded, let aiResponse = checkIn.aiResponse {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Insight:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentHex)
                        
                        Text(aiResponse)
                            .font(.subheadline)
                            .foregroundColor(.textMainHex)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.backgroundHex)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    // Helper function to convert emoji to numerical score
    private func moodScore(from emoji: String) -> Double {
        switch emoji {
        case "😭", "😢", "☹️", "😞": return 0.2
        case "😔", "😕", "🙁": return 0.4
        case "😐", "😌", "😑": return 0.6
        case "🙂", "😊", "😄": return 0.8
        case "😁", "😆", "🤩", "😍", "🥳": return 1.0
        default: return 0.6 // Default neutral
        }
    }
}

enum TimeframeFilter: CaseIterable {
    case week, month, all
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .all: return "All"
        }
    }
}

#Preview {
    HistoryView()
} 