import SwiftUI

// MARK: - Main Insight Card Component

struct InsightCard: View {
    let insight: UserInsight
    let onTap: (() -> Void)?
    
    init(insight: UserInsight, onTap: (() -> Void)? = nil) {
        self.insight = insight
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and type
                HStack {
                    Image(systemName: insight.type.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: insight.confidenceLevel.color))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.type.displayName)
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                        
                        Text(insight.confidenceLevel.displayName)
                            .font(.caption2)
                            .foregroundColor(Color(hex: insight.confidenceLevel.color))
                    }
                    
                    Spacer()
                    
                    ConfidenceBadge(level: insight.confidenceLevel)
                }
                
                // Main content
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundColor(.textMainHex)
                        .multilineTextAlignment(.leading)
                    
                    Text(insight.description)
                        .font(.body)
                        .foregroundColor(.textMainHex)
                        .opacity(0.8)
                        .multilineTextAlignment(.leading)
                }
                
                // Footer with data points
                HStack {
                    Label("\(insight.dataPoints) data points", systemImage: "chart.bar")
                        .font(.caption2)
                        .foregroundColor(.mediumGreyHex)
                    
                    Spacer()
                    
                    Text(formatTimeAgo(insight.createdAt))
                        .font(.caption2)
                        .foregroundColor(.mediumGreyHex)
                }
            }
            .padding(16)
            .background(Color.cardBackgroundHex)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: insight.confidenceLevel.color).opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let level: ConfidenceLevel
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < level.value + 1 ? Color(hex: level.color) : Color.mediumGreyHex.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Insight Summary Card

struct InsightSummaryCard: View {
    let insights: [UserInsight]
    let onViewAll: () -> Void
    
    var activeInsights: [UserInsight] {
        insights.filter { $0.isActive && !$0.isExpired }.prefix(3).map { $0 }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.accentHex)
                    
                    Text("Personal Insights")
                        .font(.headline)
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                    
                    if !insights.isEmpty {
                        Button("See All") {
                            onViewAll()
                        }
                        .font(.caption)
                        .foregroundColor(.accentHex)
                    }
                }
                
                // Content
                if activeInsights.isEmpty {
                    EmptyInsightsView()
                } else {
                    VStack(spacing: 12) {
                        ForEach(activeInsights) { insight in
                            CompactInsightRow(insight: insight)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Compact Insight Row

struct CompactInsightRow: View {
    let insight: UserInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.title3)
                .foregroundColor(Color(hex: insight.confidenceLevel.color))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .foregroundColor(.textMainHex)
                    .lineLimit(1)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
                    .lineLimit(2)
            }
            
            Spacer()
            
            ConfidenceBadge(level: insight.confidenceLevel)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty States

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.title)
                .foregroundColor(.mediumGreyHex)
            
            VStack(spacing: 4) {
                Text("Building your insights")
                    .font(.subheadline)
                    .foregroundColor(.textMainHex)
                
                Text("Keep checking in daily to discover patterns")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Check-in Prompt Card

struct QuickCheckInPromptCard: View {
    let onCheckIn: () -> Void
    let hasCheckedInToday: Bool
    
    var body: some View {
        CardView {
            HStack(spacing: 16) {
                Image(systemName: hasCheckedInToday ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(hasCheckedInToday ? .accentHex : .accentHex)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hasCheckedInToday ? "Today's check-in complete" : "Quick check-in")
                        .font(.headline)
                        .foregroundColor(.textMainHex)
                    
                    Text(hasCheckedInToday ? "See you tomorrow!" : "One happy thing, one to improve")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                if !hasCheckedInToday {
                    Button("Start") {
                        onCheckIn()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentHex)
                    .cornerRadius(20)
                }
            }
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let checkInDates: [Date]
    
    private var streakEmoji: String {
        switch currentStreak {
        case 0: return "💫"
        case 1...3: return "🌱"
        case 4...7: return "🔥"
        case 8...21: return "🚀"
        default: return "💎"
        }
    }
    
    private var streakMessage: String {
        switch currentStreak {
        case 0: return "Start your streak"
        case 1: return "Great start!"
        case 2...3: return "Building momentum"
        case 4...7: return "On fire!"
        case 8...21: return "Incredible consistency"
        default: return "Legendary dedication"
        }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(streakEmoji)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(currentStreak) day streak")
                            .font(.headline)
                            .foregroundColor(.textMainHex)
                        
                        Text(streakMessage)
                            .font(.subheadline)
                            .foregroundColor(.mediumGreyHex)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Best: \(longestStreak)")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                    }
                }
                
                // Mini calendar view of recent days
                StreakCalendarView(checkInDates: checkInDates)
            }
        }
    }
}

// MARK: - Mini Streak Calendar

struct StreakCalendarView: View {
    let checkInDates: [Date]
    private let calendar = Calendar.current
    
    private var last7Days: [Date] {
        (0..<7).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: Date())
        }.reversed()
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(last7Days, id: \.self) { date in
                let hasCheckIn = checkInDates.contains { calendar.isDate($0, inSameDayAs: date) }
                
                VStack(spacing: 2) {
                    Text(dayOfWeek(date))
                        .font(.caption2)
                        .foregroundColor(.mediumGreyHex)
                    
                    Circle()
                        .fill(hasCheckIn ? Color.accentHex : Color.mediumGreyHex.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
    
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}

// MARK: - Extensions
// Color extension removed to avoid duplication with Colors.swift

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Sample insights for preview
            InsightCard(insight: UserInsight(
                type: .pattern,
                title: "You're happiest on weekends",
                description: "Your mood tends to be 40% better on Saturday and Sunday compared to weekdays.",
                confidence: 0.85,
                dataPoints: 12
            ))
            
            InsightCard(insight: UserInsight(
                type: .correlation,
                title: "Exercise boosts your mood",
                description: "You mention being happy about exercise 3x more than other activities.",
                confidence: 0.72,
                dataPoints: 8
            ))
            
            QuickCheckInPromptCard(onCheckIn: {}, hasCheckedInToday: false)
            
            StreakCard(
                currentStreak: 5,
                longestStreak: 12,
                checkInDates: [
                    Date(),
                    Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                    Calendar.current.date(byAdding: .day, value: -2, to: Date())!
                ]
            )
        }
        .padding()
    }
    .background(Color.backgroundHex)
} 