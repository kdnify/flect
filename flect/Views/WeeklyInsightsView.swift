import SwiftUI

struct WeeklyInsightsView: View {
    @StateObject private var checkInService = CheckInService.shared
    @StateObject private var goalService = GoalService.shared
    @StateObject private var userPreferences = UserPreferencesService.shared
    @State private var selectedWeek: Date = Date()
    @State private var isLoading = false
    @State private var weeklyInsights: WeeklyInsightData?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                if isLoading {
                    loadingSection
                } else if let insights = weeklyInsights {
                    insightsContent(insights)
                } else {
                    noDataSection
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
        .onAppear {
            loadWeeklyInsights()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.mediumGreyHex)
                .font(.subheadline)
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Weekly Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text("AI-powered analysis of your week")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                Button("Share") {
                    // TODO: Share insights
                }
                .foregroundColor(.accentHex)
                .font(.subheadline)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 20)
        }
        .background(Color.cardBackgroundHex)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentHex))
                
                Text("Analyzing your week...")
                    .font(.headline)
                    .foregroundColor(.textMainHex)
                
                Text("Our AI is processing your check-ins and goals to provide personalized insights")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    // MARK: - No Data Section
    
    private var noDataSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.mediumGreyHex)
                
                Text("No Data Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Text("Complete a few daily check-ins to start seeing your weekly insights and patterns.")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Insights Content
    
    private func insightsContent(_ insights: WeeklyInsightData) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Week summary
                weekSummarySection(insights)
                
                // Mood analysis
                moodAnalysisSection(insights)
                
                // Goal progress
                goalProgressSection(insights)
                
                // AI insights
                aiInsightsSection(insights)
                
                // Patterns and trends
                patternsSection(insights)
                
                // Recommendations
                recommendationsSection(insights)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Week Summary Section
    
    private func weekSummarySection(_ insights: WeeklyInsightData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Week Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Text(insights.weekRange)
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
            }
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Check-ins",
                    value: "\(insights.totalCheckIns)",
                    subtitle: "of 7 days",
                    icon: "chart.bar",
                    color: .blue
                )
                
                StatCard(
                    title: "Avg Mood",
                    value: insights.averageMood,
                    subtitle: "this week",
                    icon: "face.smiling",
                    color: .green
                )
                
                StatCard(
                    title: "Goals",
                    value: "\(insights.activeGoals)",
                    subtitle: "in progress",
                    icon: "target",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Mood Analysis Section
    
    private func moodAnalysisSection(_ insights: WeeklyInsightData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Analysis")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            // Mood chart
            MoodChartView(moodData: insights.moodData)
                .frame(height: 120)
            
            // Mood insights
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textMainHex)
                
                ForEach(insights.moodInsights, id: \.self) { insight in
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(.mediumGreyHex)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Goal Progress Section
    
    private func goalProgressSection(_ insights: WeeklyInsightData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Progress")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            if insights.goalProgress.isEmpty {
                Text("No active goals this week")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .padding(.vertical, 20)
            } else {
                ForEach(insights.goalProgress, id: \.goalId) { progress in
                    GoalProgressSummaryCard(progress: progress)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - AI Insights Section
    
    private func aiInsightsSection(_ insights: WeeklyInsightData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.accentHex)
                
                Text("AI Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(insights.aiInsights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.accentHex)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(.textMainHex)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Patterns Section
    
    private func patternsSection(_ insights: WeeklyInsightData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns & Trends")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            VStack(spacing: 12) {
                ForEach(insights.patterns, id: \.self) { pattern in
                    PatternCard(pattern: pattern)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Recommendations Section
    
    private func recommendationsSection(_ insights: WeeklyInsightData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
            }
            
            VStack(spacing: 12) {
                ForEach(insights.recommendations, id: \.self) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions
    
    private func loadWeeklyInsights() {
        isLoading = true
        
        // Generate real insights from actual data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            weeklyInsights = generateRealWeeklyInsights()
            isLoading = false
        }
    }
    
    private func generateRealWeeklyInsights() -> WeeklyInsightData {
        let personalityType = userPreferences.personalityProfile?.primaryType ?? PersonalityType.supporter
        
        // Get real check-in data for the past week
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedWeek)?.start ?? selectedWeek
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: selectedWeek)?.end ?? selectedWeek
        
        let weeklyCheckIns = checkInService.checkIns.filter { checkIn in
            checkIn.date >= weekStart && checkIn.date < weekEnd
        }
        
        // Calculate real statistics
        let totalCheckIns = weeklyCheckIns.count
        let averageMood = calculateAverageMood(from: weeklyCheckIns)
        let activeGoals = goalService.activeGoals.count
        
        // Generate real mood data
        let moodData = generateRealMoodData(for: weeklyCheckIns)
        
        // Generate real insights based on actual data
        let moodInsights = generateRealMoodInsights(from: weeklyCheckIns, personality: personalityType)
        let goalProgress = generateRealGoalProgress()
        let aiInsights = generateRealAIInsights(from: weeklyCheckIns, personality: personalityType)
        let patterns = generateRealPatterns(from: weeklyCheckIns)
        let recommendations = generateRealRecommendations(from: weeklyCheckIns, personality: personalityType)
        
        // Format week range
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let weekRange = "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
        
        return WeeklyInsightData(
            weekRange: weekRange,
            totalCheckIns: totalCheckIns,
            averageMood: averageMood,
            activeGoals: activeGoals,
            moodData: moodData,
            moodInsights: moodInsights,
            goalProgress: goalProgress,
            aiInsights: aiInsights,
            patterns: patterns,
            recommendations: recommendations
        )
    }
    
    private func calculateAverageMood(from checkIns: [DailyCheckIn]) -> String {
        guard !checkIns.isEmpty else { return "No data 😶" }
        
        let moodValues = checkIns.map { getMoodValue($0.moodName) }
        let averageValue = moodValues.reduce(0, +) / Double(moodValues.count)
        
        return getMoodDisplayName(averageValue)
    }
    
    private func generateRealMoodData(for checkIns: [DailyCheckIn]) -> [MoodDataPoint] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: selectedWeek)?.start ?? selectedWeek
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) ?? weekStart
            let checkIn = checkIns.first { calendar.isDate($0.date, inSameDayAs: date) }
            
            let mood = checkIn?.moodName ?? "No Check-in"
            let value = getMoodValue(mood)
            
            return MoodDataPoint(day: date, mood: mood, value: value)
        }
    }
    
    private func generateRealMoodInsights(from checkIns: [DailyCheckIn], personality: PersonalityType) -> [String] {
        var insights: [String] = []
        
        if checkIns.isEmpty {
            insights.append("No check-ins this week - consider starting your daily reflection habit")
            return insights
        }
        
        // Analyze mood patterns
        let moodCounts = Dictionary(grouping: checkIns, by: { $0.moodName })
        let mostCommonMood = moodCounts.max(by: { $0.value.count < $1.value.count })?.key ?? "Unknown"
        
        insights.append("Your most common mood this week was \(mostCommonMood)")
        
        // Check for improvement
        if checkIns.count >= 2 {
            let firstHalf = Array(checkIns.prefix(checkIns.count / 2))
            let secondHalf = Array(checkIns.suffix(checkIns.count / 2))
            
            let firstAvg = firstHalf.map { getMoodValue($0.moodName) }.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.map { getMoodValue($0.moodName) }.reduce(0, +) / Double(secondHalf.count)
            
            if secondAvg > firstAvg {
                insights.append("Your mood improved throughout the week - great progress!")
            } else if secondAvg < firstAvg {
                insights.append("Your mood declined this week - consider what might be causing this")
            }
        }
        
        // Personality-specific insights
        switch personality {
        case PersonalityType.achiever:
            insights.append("Your consistent check-ins show strong commitment to self-improvement")
        case PersonalityType.explorer:
            insights.append("Your varied mood patterns reflect your natural curiosity and adaptability")
        default:
            insights.append("Your daily reflections are building valuable self-awareness")
        }
        
        return insights
    }
    
    private func generateRealGoalProgress() -> [GoalProgressData] {
        return goalService.activeGoals.prefix(3).map { goal in
            let weeklyProgress = calculateWeeklyProgress(for: goal)
            let milestoneCompleted = goal.milestones.contains { $0.isCompleted && 
                Calendar.current.isDate($0.completedDate ?? Date(), equalTo: selectedWeek, toGranularity: .weekOfYear) }
            
            return GoalProgressData(
                goalId: goal.id,
                goalTitle: goal.title,
                goalCategory: goal.category.displayName,
                progressPercentage: goal.progressPercentage,
                weeklyProgress: weeklyProgress,
                milestoneCompleted: milestoneCompleted
            )
        }
    }
    
    private func calculateWeeklyProgress(for goal: TwelveWeekGoal) -> Int {
        // Calculate progress made this week
        let weeklyProgress = goalService.getDailyProgressThisWeek(for: goal.id)
        guard !weeklyProgress.isEmpty else { return 0 }
        
        let averageRating = weeklyProgress.reduce(0) { $0 + $1.progressRating } / weeklyProgress.count
        return Int((Double(averageRating) / 5.0) * 20) // Convert to percentage
    }
    
    private func generateRealAIInsights(from checkIns: [DailyCheckIn], personality: PersonalityType) -> [String] {
        var insights: [String] = []
        
        if checkIns.isEmpty {
            insights.append("Start your daily reflection habit to unlock personalized insights")
            return insights
        }
        
        // Analyze check-in consistency
        let consistencyRate = Double(checkIns.count) / 7.0
        if consistencyRate >= 0.8 {
            insights.append("Excellent consistency! You're building a strong reflection habit")
        } else if consistencyRate >= 0.5 {
            insights.append("Good progress on consistency. Try to check in daily for better insights")
        } else {
            insights.append("Consider making daily reflection a priority for deeper insights")
        }
        
        // Personality-specific insights
        switch personality {
        case PersonalityType.achiever:
            insights.append("Your goal-oriented approach is showing in your consistent tracking")
        case PersonalityType.explorer:
            insights.append("Your natural curiosity is helping you discover new patterns in your mood")
        case PersonalityType.supporter:
            insights.append("Your caring nature extends to self-care through daily reflection")
        default:
            insights.append("Your daily reflections are building valuable self-awareness")
        }
        
        return insights
    }
    
    private func generateRealPatterns(from checkIns: [DailyCheckIn]) -> [PatternData] {
        var patterns: [PatternData] = []
        
        if checkIns.isEmpty {
            return patterns
        }
        
        // Analyze check-in timing
        let morningCheckIns = checkIns.filter { 
            Calendar.current.component(.hour, from: $0.date) < 12 
        }.count
        
        if morningCheckIns > checkIns.count / 2 {
            patterns.append(PatternData(
                title: "Morning Person",
                description: "You prefer to reflect early in the day",
                icon: "sunrise.fill",
                color: .orange
            ))
        }
        
        // Analyze mood consistency
        let moodValues = checkIns.map { getMoodValue($0.moodName) }
        let moodVariance = calculateVariance(moodValues)
        
        if moodVariance < 0.5 {
            patterns.append(PatternData(
                title: "Stable Mood",
                description: "Your mood has been consistent this week",
                icon: "heart.fill",
                color: .green
            ))
        } else {
            patterns.append(PatternData(
                title: "Mood Variability",
                description: "Your mood has varied significantly this week",
                icon: "waveform.path.ecg",
                color: .blue
            ))
        }
        
        return patterns
    }
    
    private func generateRealRecommendations(from checkIns: [DailyCheckIn], personality: PersonalityType) -> [RecommendationData] {
        var recommendations: [RecommendationData] = []
        
        if checkIns.isEmpty {
            recommendations.append(RecommendationData(
                title: "Start Daily Reflection",
                description: "Begin your daily reflection habit for better insights",
                priority: .high,
                category: "Habits"
            ))
            return recommendations
        }
        
        // Check consistency
        let consistencyRate = Double(checkIns.count) / 7.0
        if consistencyRate < 0.7 {
            recommendations.append(RecommendationData(
                title: "Improve Consistency",
                description: "Try to check in daily for more accurate insights",
                priority: .high,
                category: "Habits"
            ))
        }
        
        // Personality-specific recommendations
        switch personality {
        case PersonalityType.achiever:
            recommendations.append(RecommendationData(
                title: "Set Weekly Targets",
                description: "Break down your goals into weekly milestones",
                priority: .medium,
                category: "Goal Setting"
            ))
        case PersonalityType.explorer:
            recommendations.append(RecommendationData(
                title: "Try New Activities",
                description: "Experiment with different reflection prompts",
                priority: .medium,
                category: "Innovation"
            ))
        default:
            recommendations.append(RecommendationData(
                title: "Celebrate Progress",
                description: "Acknowledge your daily reflection achievements",
                priority: .medium,
                category: "Motivation"
            ))
        }
        
        return recommendations
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    private func createMockWeeklyInsights() -> WeeklyInsightData {
        let personalityType = userPreferences.personalityProfile?.primaryType ?? PersonalityType.supporter
        
        return WeeklyInsightData(
            weekRange: "Dec 9 - Dec 15",
            totalCheckIns: 6,
            averageMood: "Good 😊",
            activeGoals: goalService.activeGoals.count,
            moodData: createMockMoodData(),
            moodInsights: [
                "Your mood was most positive on Wednesday and Friday",
                "You tend to feel better after physical activities",
                "Stress levels were highest on Monday and Tuesday"
            ],
            goalProgress: createMockGoalProgress(),
            aiInsights: createMockAIInsights(for: personalityType),
            patterns: createMockPatterns(),
            recommendations: createMockRecommendations(for: personalityType)
        )
    }
    
    private func createMockMoodData() -> [MoodDataPoint] {
        let moods = ["Great", "Good", "Neutral", "Okay", "Rough", "Good", "Great"]
        return moods.enumerated().map { index, mood in
            MoodDataPoint(
                day: Calendar.current.date(byAdding: .day, value: index - 6, to: Date()) ?? Date(),
                mood: mood,
                value: getMoodValue(mood)
            )
        }
    }
    
    private func getMoodValue(_ mood: String) -> Double {
        switch mood {
        case "Great": return 5.0
        case "Good": return 4.0
        case "Neutral": return 3.0
        case "Okay": return 2.0
        case "Rough": return 1.0
        default: return 3.0
        }
    }
    
    private func getMoodDisplayName(_ value: Double) -> String {
        switch value {
        case 4.5...5.0: return "Great 😊"
        case 3.5..<4.5: return "Good 🙂"
        case 2.5..<3.5: return "Neutral 😐"
        case 1.5..<2.5: return "Okay 😕"
        case 0.0..<1.5: return "Rough 😞"
        default: return "No data 😶"
        }
    }
    
    private func createMockGoalProgress() -> [GoalProgressData] {
        return goalService.activeGoals.prefix(2).map { goal in
            GoalProgressData(
                goalId: goal.id,
                goalTitle: goal.title,
                goalCategory: goal.category.displayName,
                progressPercentage: goal.progressPercentage,
                weeklyProgress: Int.random(in: 5...15),
                milestoneCompleted: Bool.random()
            )
        }
    }
    
    private func createMockAIInsights(for personality: PersonalityType) -> [String] {
        switch personality {
        case PersonalityType.achiever:
            return [
                "You're making excellent progress on your goals! Your consistency is impressive.",
                "Consider breaking down larger tasks into smaller, more manageable chunks.",
                "Your productivity peaks in the morning - schedule important work then."
            ]
        case PersonalityType.explorer:
            return [
                "You're naturally curious and open to new experiences - leverage this strength!",
                "Try experimenting with different approaches to your goals.",
                "Your creativity flows best when you're not constrained by rigid schedules."
            ]
        default:
            return [
                "You're building great momentum with your daily check-ins.",
                "Your mood patterns show you're most positive after social interactions.",
                "Consider setting smaller, more frequent milestones to maintain motivation."
            ]
        }
    }
    
    private func createMockPatterns() -> [PatternData] {
        return [
            PatternData(
                title: "Productivity Peak",
                description: "You're most productive between 9-11 AM",
                icon: "clock.fill",
                color: .blue
            ),
            PatternData(
                title: "Mood Boosters",
                description: "Exercise and social activities improve your mood",
                icon: "heart.fill",
                color: .green
            ),
            PatternData(
                title: "Stress Triggers",
                description: "Monday mornings and deadlines cause stress",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            )
        ]
    }
    
    private func createMockRecommendations(for personality: PersonalityType) -> [RecommendationData] {
        switch personality {
        case PersonalityType.achiever:
            return [
                RecommendationData(
                    title: "Set Daily Targets",
                    description: "Break your weekly goals into daily actionable targets",
                    priority: .high,
                    category: "Productivity"
                ),
                RecommendationData(
                    title: "Track Progress",
                    description: "Use the progress tracking feature to monitor your advancement",
                    priority: .medium,
                    category: "Goal Management"
                )
            ]
        case PersonalityType.explorer:
            return [
                RecommendationData(
                    title: "Try New Approaches",
                    description: "Experiment with different methods to achieve your goals",
                    priority: .high,
                    category: "Innovation"
                ),
                RecommendationData(
                    title: "Document Learnings",
                    description: "Keep track of what works and what doesn't",
                    priority: .medium,
                    category: "Learning"
                )
            ]
        default:
            return [
                RecommendationData(
                    title: "Maintain Consistency",
                    description: "Keep up your daily check-in habit for better insights",
                    priority: .high,
                    category: "Habits"
                ),
                RecommendationData(
                    title: "Celebrate Small Wins",
                    description: "Acknowledge your progress, no matter how small",
                    priority: .medium,
                    category: "Motivation"
                )
            ]
        }
    }
}

// MARK: - Data Models

struct WeeklyInsightData {
    let weekRange: String
    let totalCheckIns: Int
    let averageMood: String
    let activeGoals: Int
    let moodData: [MoodDataPoint]
    let moodInsights: [String]
    let goalProgress: [GoalProgressData]
    let aiInsights: [String]
    let patterns: [PatternData]
    let recommendations: [RecommendationData]
}

struct MoodDataPoint {
    let day: Date
    let mood: String
    let value: Double
}

struct GoalProgressData {
    let goalId: UUID
    let goalTitle: String
    let goalCategory: String
    let progressPercentage: Int
    let weeklyProgress: Int
    let milestoneCompleted: Bool
}

struct PatternData: Hashable {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct RecommendationData: Hashable {
    let title: String
    let description: String
    let priority: RecommendationPriority
    let category: String
}

enum RecommendationPriority: String, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Component Views

// Remove StatCard
// Remove MoodChartView
// Remove GoalProgressCard

struct PatternCard: View {
    let pattern: PatternData
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: pattern.icon)
                .font(.title3)
                .foregroundColor(pattern.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textMainHex)
                
                Text(pattern.description)
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            Spacer()
        }
        .padding(12)
        .background(pattern.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RecommendationCard: View {
    let recommendation: RecommendationData
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                    
                    Text(recommendation.category)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(recommendation.priority.color)
                        .cornerRadius(6)
                }
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            Spacer()
        }
        .padding(12)
        .background(recommendation.priority.color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct WeeklyInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyInsightsView()
    }
} 