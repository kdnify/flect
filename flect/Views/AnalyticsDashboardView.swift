import SwiftUI

struct AnalyticsDashboardView: View {
    @StateObject private var patternAnalysisService = PatternAnalysisService.shared
    @StateObject private var checkInService = CheckInService.shared
    @StateObject private var taskService = TaskService.shared
    @StateObject private var goalService = GoalService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTimeframe: Timeframe = .week
    @State private var selectedInsightType: InsightType?
    @State private var showingInsightDetail = false
    
    private enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Timeframe selector
                    timeframeSelector
                    
                    // Overview cards
                    overviewSection
                    
                    // Mood trends
                    moodTrendsSection
                    
                    // Task analytics
                    taskAnalyticsSection
                    
                    // Goal progress
                    goalProgressSection
                    
                    // Behavioral insights
                    behavioralInsightsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color.backgroundHex)
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingInsightDetail) {
            if let insight = selectedInsight {
                InsightDetailView(insight: insight)
            }
        }
    }
    
    // MARK: - Timeframe Selector
    
    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Button(action: { selectedTimeframe = timeframe }) {
                        Text(timeframe.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTimeframe == timeframe ? .semibold : .medium)
                            .foregroundColor(selectedTimeframe == timeframe ? .accentHex : .mediumGreyHex)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTimeframe == timeframe ? Color.accentHex.opacity(0.1) : Color.clear)
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            AnalyticsCard(
                title: "Average Mood",
                value: String(format: "%.1f", averageMood),
                icon: "face.smiling",
                color: .blue
            )
            
            AnalyticsCard(
                title: "Check-in Rate",
                value: "\(Int(checkInRate * 100))%",
                icon: "calendar",
                color: .orange
            )
            
            AnalyticsCard(
                title: "Task Completion",
                value: "\(Int(taskCompletionRate * 100))%",
                icon: "checkmark.circle",
                color: .green
            )
            
            AnalyticsCard(
                title: "Goal Progress",
                value: "\(Int(goalProgressRate * 100))%",
                icon: "target",
                color: .purple
            )
        }
    }
    
    // MARK: - Mood Trends Section
    
    private var moodTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Trends")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            // Mood line chart
            MoodLineChart(data: moodData)
                .frame(height: 200)
            
            // Mood correlations
            VStack(spacing: 12) {
                ForEach(moodCorrelations, id: \.title) { correlation in
                    MoodCorrelationRow(correlation: correlation)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
    }
    
    // MARK: - Task Analytics Section
    
    private var taskAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Analytics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            // Task completion by category
            VStack(spacing: 12) {
                ForEach(taskCategoryBreakdown, id: \.category) { breakdown in
                    TaskCategoryRow(breakdown: breakdown)
                }
            }
            
            // Task completion by priority
            VStack(spacing: 12) {
                ForEach(taskPriorityBreakdown, id: \.priority) { breakdown in
                    TaskPriorityRow(breakdown: breakdown)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
    }
    
    // MARK: - Goal Progress Section
    
    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Progress")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            // Goal progress chart
            GoalProgressChart(data: goalProgressData)
                .frame(height: 200)
            
            // Goal category breakdown
            VStack(spacing: 12) {
                ForEach(goalCategoryBreakdown, id: \.category) { breakdown in
                    GoalCategoryRow(breakdown: breakdown)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
    }
    
    // MARK: - Behavioral Insights Section
    
    private var behavioralInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Behavioral Insights")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            // Insights grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(patternAnalysisService.insights) { insight in
                    InsightCard(insight: insight)
                        .onTapGesture {
                            selectedInsight = insight
                            showingInsightDetail = true
                        }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    
    private var selectedInsight: UserInsight? {
        guard let type = selectedInsightType else { return nil }
        return patternAnalysisService.insights.first { $0.type == type }
    }
    
    private var averageMood: Double {
        let checkIns = checkInService.getCheckIns(for: selectedTimeframe)
        let moodScores = checkIns.map { checkIn -> Double in
            switch checkIn.moodName.lowercased() {
            case "excellent": return 5.0
            case "good": return 4.0
            case "neutral": return 3.0
            case "bad": return 2.0
            case "terrible": return 1.0
            default: return 3.0
            }
        }
        return moodScores.reduce(0.0, +) / Double(max(1, moodScores.count))
    }
    
    private var checkInRate: Double {
        let checkIns = checkInService.getCheckIns(for: selectedTimeframe)
        let calendar = Calendar.current
        let today = Date()
        let startDate: Date
        
        switch selectedTimeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: today)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: today)!
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: today)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: today)!
        }
        
        let totalDays = calendar.dateComponents([.day], from: startDate, to: today).day! + 1
        return Double(checkIns.count) / Double(totalDays)
    }
    
    private var taskCompletionRate: Double {
        let tasks = taskService.getTasks(for: selectedTimeframe)
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter { $0.isCompleted }.count) / Double(tasks.count)
    }
    
    private var goalProgressRate: Double {
        let goals = goalService.getGoals(for: selectedTimeframe)
        guard !goals.isEmpty else { return 0 }
        return goals.reduce(0.0) { $0 + ($1.progressPercentage / 100.0) } / Double(goals.count)
    }
    
    private var moodData: [(Date, Double)] {
        let checkIns = checkInService.getCheckIns(for: selectedTimeframe)
        return checkIns.map { checkIn in
            let moodScore: Double = {
                switch checkIn.moodName.lowercased() {
                case "excellent": return 5.0
                case "good": return 4.0
                case "neutral": return 3.0
                case "bad": return 2.0
                case "terrible": return 1.0
                default: return 3.0
                }
            }()
            return (checkIn.date, moodScore)
        }
    }
    
    private var moodCorrelations: [MoodCorrelation] {
        let insights = patternAnalysisService.insights
        var correlations: [MoodCorrelation] = []
        
        // Sleep correlation
        if let sleepInsight = insights.first(where: { $0.title == "Sleep-Mood Connection" }),
           let sleepData = sleepInsight.metadata?.frequencyData {
            correlations.append(MoodCorrelation(
                title: "Sleep Quality",
                description: sleepInsight.description,
                positiveRate: Double(sleepData["goodSleepMood"] ?? 0) / 100.0,
                negativeRate: Double(sleepData["badSleepMood"] ?? 0) / 100.0
            ))
        }
        
        // Social correlation
        if let socialInsight = insights.first(where: { $0.title == "Social-Mood Connection" }),
           let socialData = socialInsight.metadata?.frequencyData {
            correlations.append(MoodCorrelation(
                title: "Social Interaction",
                description: socialInsight.description,
                positiveRate: Double(socialData["socialMood"] ?? 0) / 100.0,
                negativeRate: Double(socialData["aloneMood"] ?? 0) / 100.0
            ))
        }
        
        // Energy correlation
        if let energyInsight = insights.first(where: { $0.title == "Energy-Mood Connection" }),
           let energyData = energyInsight.metadata?.frequencyData {
            correlations.append(MoodCorrelation(
                title: "Energy Level",
                description: energyInsight.description,
                positiveRate: Double(energyData["highEnergyMood"] ?? 0) / 100.0,
                negativeRate: Double(energyData["lowEnergyMood"] ?? 0) / 100.0
            ))
        }
        
        return correlations
    }
    
    private var taskCategoryBreakdown: [TaskCategoryBreakdown] {
        let tasks = taskService.getTasks(for: selectedTimeframe)
        var breakdown: [TaskCategory: (total: Int, completed: Int)] = [:]
        
        for task in tasks {
            var stats = breakdown[task.category] ?? (0, 0)
            stats.total += 1
            if task.isCompleted {
                stats.completed += 1
            }
            breakdown[task.category] = stats
        }
        
        return TaskCategory.allCases.map { category in
            let stats = breakdown[category] ?? (0, 0)
            return TaskCategoryBreakdown(
                category: category,
                totalTasks: stats.total,
                completedTasks: stats.completed
            )
        }
    }
    
    private var taskPriorityBreakdown: [TaskPriorityBreakdown] {
        let tasks = taskService.getTasks(for: selectedTimeframe)
        var breakdown: [TaskPriority: (total: Int, completed: Int)] = [:]
        
        for task in tasks {
            var stats = breakdown[task.priority] ?? (0, 0)
            stats.total += 1
            if task.isCompleted {
                stats.completed += 1
            }
            breakdown[task.priority] = stats
        }
        
        return TaskPriority.allCases.map { priority in
            let stats = breakdown[priority] ?? (0, 0)
            return TaskPriorityBreakdown(
                priority: priority,
                totalTasks: stats.total,
                completedTasks: stats.completed
            )
        }
    }
    
    private var goalProgressData: [(String, Double)] {
        let goals = goalService.getGoals(for: selectedTimeframe)
        return goals.map { ($0.title, $0.progressPercentage) }
    }
    
    private var goalCategoryBreakdown: [GoalCategoryBreakdown] {
        let goals = goalService.getGoals(for: selectedTimeframe)
        var breakdown: [TaskCategory: (total: Int, completed: Int)] = [:]
        
        for goal in goals {
            var stats = breakdown[goal.category] ?? (0, 0)
            stats.total += 1
            if goal.isCompleted {
                stats.completed += 1
            }
            breakdown[goal.category] = stats
        }
        
        return TaskCategory.allCases.map { category in
            let stats = breakdown[category] ?? (0, 0)
            return GoalCategoryBreakdown(
                category: category,
                totalGoals: stats.total,
                completedGoals: stats.completed
            )
        }
    }
}

// MARK: - Supporting Types

struct MoodCorrelation {
    let title: String
    let description: String
    let positiveRate: Double
    let negativeRate: Double
}

struct TaskCategoryBreakdown {
    let category: TaskCategory
    let totalTasks: Int
    let completedTasks: Int
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

struct TaskPriorityBreakdown {
    let priority: TaskPriority
    let totalTasks: Int
    let completedTasks: Int
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

struct GoalCategoryBreakdown {
    let category: TaskCategory
    let totalGoals: Int
    let completedGoals: Int
    
    var completionRate: Double {
        guard totalGoals > 0 else { return 0 }
        return Double(completedGoals) / Double(totalGoals)
    }
}

// MARK: - Supporting Views

struct MoodLineChart: View {
    let data: [(Date, Double)]
    
    var body: some View {
        GeometryReader { geometry in
            if data.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Path { path in
                    let xStep = geometry.size.width / CGFloat(max(1, data.count - 1))
                    let yScale = geometry.size.height / 4.0 // Scale for 1-5 range
                    
                    path.move(to: CGPoint(
                        x: 0,
                        y: geometry.size.height - (data[0].1 - 1) * yScale
                    ))
                    
                    for i in 1..<data.count {
                        path.addLine(to: CGPoint(
                            x: CGFloat(i) * xStep,
                            y: geometry.size.height - (data[i].1 - 1) * yScale
                        ))
                    }
                }
                .stroke(Color.accentHex, lineWidth: 2)
                .shadow(color: Color.accentHex.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
    }
}

struct MoodCorrelationRow: View {
    let correlation: MoodCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(correlation.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textMainHex)
            
            Text(correlation.description)
                .font(.caption)
                .foregroundColor(.mediumGreyHex)
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * correlation.positiveRate)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geometry.size.width * correlation.negativeRate)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
    }
}

struct TaskCategoryRow: View {
    let breakdown: TaskCategoryBreakdown
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(breakdown.category.emoji)
                    .font(.subheadline)
                
                Text(breakdown.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Text("\(breakdown.completedTasks)/\(breakdown.totalTasks)")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.cardBackgroundHex)
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color(breakdown.category.color))
                        .frame(width: geometry.size.width * breakdown.completionRate, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

struct TaskPriorityRow: View {
    let breakdown: TaskPriorityBreakdown
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(breakdown.priority.emoji)
                    .font(.subheadline)
                
                Text(breakdown.priority.displayName)
                    .font(.subheadline)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Text("\(breakdown.completedTasks)/\(breakdown.totalTasks)")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.cardBackgroundHex)
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color(breakdown.priority.color))
                        .frame(width: geometry.size.width * breakdown.completionRate, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

struct GoalProgressChart: View {
    let data: [(String, Double)]
    
    var body: some View {
        GeometryReader { geometry in
            if data.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(data, id: \.0) { item in
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottom) {
                                Rectangle()
                                    .fill(Color.cardBackgroundHex)
                                    .frame(width: 24, height: 150)
                                
                                Rectangle()
                                    .fill(Color.accentHex)
                                    .frame(width: 24, height: 150 * item.1 / 100.0)
                            }
                            .cornerRadius(4)
                            
                            Text(item.0)
                                .font(.caption2)
                                .foregroundColor(.mediumGreyHex)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(width: 60)
                                .rotationEffect(.degrees(-45))
                                .offset(y: 20)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct GoalCategoryRow: View {
    let breakdown: GoalCategoryBreakdown
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(breakdown.category.emoji)
                    .font(.subheadline)
                
                Text(breakdown.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Text("\(breakdown.completedGoals)/\(breakdown.totalGoals)")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.cardBackgroundHex)
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color(breakdown.category.color))
                        .frame(width: geometry.size.width * breakdown.completionRate, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Preview

struct AnalyticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsDashboardView()
    }
} 