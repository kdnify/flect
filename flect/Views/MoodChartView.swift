import SwiftUI

struct MoodChartView: View {
    let moodData: [MoodDataPoint]
    @State private var selectedTimeframe: TimeFrame = .week
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            timeframeSelector
            chartSection
            statisticsSection
            Spacer()
        }
        .padding()
        .background(Color.backgroundHex)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Your Mood")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textMainHex)
            
            Text("Track your emotional patterns")
                .font(.subheadline)
                .foregroundColor(.mediumGreyHex)
        }
    }
    
    // MARK: - Timeframe Selector
    
    private var timeframeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                Button(action: {
                    selectedTimeframe = timeframe
                    HapticManager.shared.selection()
                }) {
                    Text(timeframe.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .textMainHex)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeframe == timeframe ? Color.accentHex : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Timeline")
                .font(.headline)
                .foregroundColor(.textMainHex)
            
            if filteredMoodData.isEmpty {
                emptyStateView
            } else {
                moodTimelineChart
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundColor(.mediumGreyHex)
            
            Text("No mood data yet")
                .font(.subheadline)
                .foregroundColor(.mediumGreyHex)
            
            Text("Check in daily to see your patterns")
                .font(.caption)
                .foregroundColor(.mediumGreyHex)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
    }
    
    private var moodTimelineChart: some View {
        VStack(spacing: 12) {
            moodLevelIndicators
            // Chart area
            GeometryReader { geometry in
                ZStack {
                    // Background grid
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        for i in 0...4 {
                            let y = height - (height / 4 * CGFloat(i))
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(Color.mediumGreyHex.opacity(0.2), lineWidth: 1)
                    // Mood line chart
                    if filteredMoodData.count > 1 {
                        moodLineChart(in: geometry)
                    }
                    // Mood points
                    ForEach(Array(filteredMoodData.enumerated()), id: \.offset) { index, moodDataPoint in
                        let x = geometry.size.width / CGFloat(max(filteredMoodData.count - 1, 1)) * CGFloat(index)
                        let moodLevelValue = moodLevel(for: moodDataPoint.mood)
                        let y = geometry.size.height - (geometry.size.height / 4 * CGFloat(moodLevelValue - 1))
                        Circle()
                            .fill(Color.moodColor(for: moodDataPoint.mood))
                            .frame(width: 12, height: 12)
                            .position(x: x, y: y)
                            .overlay(
                                Circle().stroke(Color.borderColorHex, lineWidth: 1)
                            )
                            .accessibilityLabel("Mood: \(moodDataPoint.mood)")
                    }
                }
            }
            .frame(height: 120)
            .padding()
            .background(Color.cardBackgroundHex)
            .cornerRadius(12)
        }
    }
    
    private func moodLineChart(in geometry: GeometryProxy) -> some View {
        Path { path in
            let points = filteredMoodData.enumerated().map { index, moodDataPoint in
                let x = geometry.size.width / CGFloat(max(filteredMoodData.count - 1, 1)) * CGFloat(index)
                let moodLevelValue = moodLevel(for: moodDataPoint.mood)
                let y = geometry.size.height - (geometry.size.height / 4 * CGFloat(moodLevelValue - 1))
                return CGPoint(x: x, y: y)
            }
            
            if let firstPoint = points.first {
                path.move(to: firstPoint)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(Color.accentHex, lineWidth: 2)
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.textMainHex)
            
            if !filteredMoodData.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    StatCard(
                        title: "Average Mood",
                        value: "",
                        subtitle: averageMoodText,
                        icon: "heart.fill",
                        color: .accentHex
                    )
                    
                    StatCard(
                        title: "Total Days",
                        value: "\(filteredMoodData.count)",
                        subtitle: selectedTimeframe.rawValue.lowercased(),
                        icon: "calendar",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Best Day",
                        value: "",
                        subtitle: bestMoodDate,
                        icon: "star.fill",
                        color: Color.moodColor(for: bestMoodName)
                    )
                    
                    StatCard(
                        title: "Trend",
                        value: moodTrendEmoji,
                        subtitle: moodTrendText,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var filteredMoodData: [MoodDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        return moodData.filter { moodDataPoint in
            switch selectedTimeframe {
            case .week:
                return calendar.dateInterval(of: .weekOfYear, for: now)?.contains(moodDataPoint.day) ?? false
            case .month:
                return calendar.dateInterval(of: .month, for: now)?.contains(moodDataPoint.day) ?? false
            case .all:
                return true
            }
        }.sorted { $0.day < $1.day }
    }
    
    private var averageMood: Double {
        guard !filteredMoodData.isEmpty else { return 0 }
        let total = filteredMoodData.reduce(0) { sum, moodDataPoint in
            sum + moodValue(from: moodDataPoint.mood)
        }
        return Double(total) / Double(filteredMoodData.count)
    }
    
    private var averageMoodText: String {
        switch averageMood {
        case 4.5...: return "Amazing"
        case 3.5..<4.5: return "Good"
        case 2.5..<3.5: return "Okay"
        case 1.5..<2.5: return "Bad"
        default: return "Awful"
        }
    }
    
    private var bestMoodEmoji: String {
        guard let bestMoodDataPoint = filteredMoodData.max(by: { 
            moodValue(from: $0.mood) < moodValue(from: $1.mood) 
        }) else { return "😐" }
        return bestMoodDataPoint.mood
    }
    
    private var bestMoodDate: String {
        guard let bestMoodDataPoint = filteredMoodData.max(by: { 
            moodValue(from: $0.mood) < moodValue(from: $1.mood) 
        }) else { return "No data" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: bestMoodDataPoint.day)
    }
    
    private var moodTrendEmoji: String {
        guard filteredMoodData.count >= 3 else { return "📊" }
        
        let recent = Array(filteredMoodData.suffix(3))
        let firstMood = moodValue(from: recent.first!.mood)
        let lastMood = moodValue(from: recent.last!.mood)
        
        if lastMood > firstMood {
            return "📈"
        } else if lastMood < firstMood {
            return "📉"
        } else {
            return "➡️"
        }
    }
    
    private var moodTrendText: String {
        guard filteredMoodData.count >= 3 else { return "Need more data" }
        
        let recent = Array(filteredMoodData.suffix(3))
        let firstMood = moodValue(from: recent.first!.mood)
        let lastMood = moodValue(from: recent.last!.mood)
        
        if lastMood > firstMood {
            return "Improving"
        } else if lastMood < firstMood {
            return "Declining"
        } else {
            return "Stable"
        }
    }
    
    // MARK: - Helper Functions
    
    private func moodValue(from name: String) -> Int {
        switch name {
        case "Rough": return 1
        case "Okay": return 2
        case "Neutral": return 3
        case "Good": return 4
        case "Great": return 5
        default: return 3
        }
    }
    
    private func moodColor(from name: String) -> Color {
        switch name {
        case "Rough": return .red
        case "Okay": return .orange
        case "Neutral": return .yellow
        case "Good": return .green
        case "Great": return .purple
        default: return .gray
        }
    }
    
    private func moodLevelEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "😢"
        case 2: return "😞"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😍"
        default: return "😐"
        }
    }
    
    private func moodName(for level: Int) -> String {
        switch level {
        case 1: return "Rough"
        case 2: return "Okay"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Neutral"
        }
    }
    
    private func moodLevel(for mood: String) -> Int {
        switch mood {
        case "Rough": return 1
        case "Okay": return 2
        case "Neutral": return 3
        case "Good": return 4
        case "Great": return 5
        default: return 3
        }
    }
    
    private var bestMoodName: String {
        guard let bestMoodDataPoint = filteredMoodData.max(by: { moodLevel(for: $0.mood) < moodLevel(for: $1.mood) }) else { return "Neutral" }
        return bestMoodDataPoint.mood
    }
    
    private var moodLevelIndicators: some View {
        HStack {
            ForEach(1...5, id: \.self) { level in
                Circle()
                    .fill(Color.moodColor(for: moodName(for: level)))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle().stroke(Color.borderColorHex, lineWidth: 1)
                    )
                if level < 5 { Spacer() }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - TimeFrame Enum

enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case all = "All Time"
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textMainHex)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textMainHex)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.mediumGreyHex)
            }
        }
        .padding(12)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
    }
}

#Preview {
    MoodChartView(moodData: [])
} 