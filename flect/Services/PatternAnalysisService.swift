import Foundation
import Combine

class PatternAnalysisService: ObservableObject {
    static let shared = PatternAnalysisService()
    
    @Published var insights: [UserInsight] = []
    @Published var isLoading = false
    
    private let checkInService = CheckInService.shared
    private let taskService = TaskService.shared
    private let goalService = GoalService.shared
    private let userDefaults = UserDefaults.standard
    private let insightsKey = "flect_insights"
    
    private init() {
        loadInsights()
        
        // Subscribe to check-in changes
        checkInService.$checkIns
            .sink { [weak self] _ in
                self?.analyzePatterns()
            }
            .store(in: &cancellables)
        
        // Subscribe to task changes
        taskService.$allTasks
            .sink { [weak self] _ in
                self?.analyzePatterns()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Pattern Analysis
    
    func analyzePatterns() {
        isLoading = true
        
        Task {
            do {
                // Analyze mood patterns
                let moodPatterns = try await analyzeMoodPatterns()
                
                // Analyze task patterns
                let taskPatterns = try await analyzeTaskPatterns()
                
                // Analyze goal patterns
                let goalPatterns = try await analyzeGoalPatterns()
                
                // Analyze behavioral patterns
                let behavioralPatterns = try await analyzeBehavioralPatterns()
                
                // Combine and filter insights
                await MainActor.run {
                    let allInsights = moodPatterns + taskPatterns + goalPatterns + behavioralPatterns
                    let filteredInsights = filterInsights(allInsights)
                    insights = filteredInsights
                    saveInsights()
                    isLoading = false
                }
            } catch {
                print("Error analyzing patterns: \(error)")
                isLoading = false
            }
        }
    }
    
    // MARK: - Mood Pattern Analysis
    
    private func analyzeMoodPatterns() async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        let checkIns = checkInService.checkIns
        
        // Analyze mood trends
        let moodTrends = try await analyzeMoodTrends(checkIns)
        insights.append(contentsOf: moodTrends)
        
        // Analyze mood correlations
        let moodCorrelations = try await analyzeMoodCorrelations(checkIns)
        insights.append(contentsOf: moodCorrelations)
        
        // Analyze mood predictions
        let moodPredictions = try await analyzeMoodPredictions(checkIns)
        insights.append(contentsOf: moodPredictions)
        
        return insights
    }
    
    private func analyzeMoodTrends(_ checkIns: [DailyCheckIn]) async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        
        // Analyze weekly mood trends
        let weeklyTrend = try await analyzeWeeklyMoodTrend(checkIns)
        if let weeklyInsight = weeklyTrend {
            insights.append(weeklyInsight)
        }
        
        // Analyze time-of-day mood patterns
        let timeOfDayPattern = try await analyzeTimeOfDayMoodPattern(checkIns)
        if let timeInsight = timeOfDayPattern {
            insights.append(timeInsight)
        }
        
        // Analyze activity-mood correlations
        let activityCorrelations = try await analyzeActivityMoodCorrelations(checkIns)
        insights.append(contentsOf: activityCorrelations)
        
        return insights
    }
    
    private func analyzeWeeklyMoodTrend(_ checkIns: [DailyCheckIn]) async throws -> UserInsight? {
        guard checkIns.count >= 7 else { return nil }
        
        let recentCheckIns = Array(checkIns.prefix(7))
        let moodScores = recentCheckIns.map { checkIn -> Double in
            switch checkIn.moodName.lowercased() {
            case "excellent": return 5.0
            case "good": return 4.0
            case "neutral": return 3.0
            case "bad": return 2.0
            case "terrible": return 1.0
            default: return 3.0
            }
        }
        
        let averageMood = moodScores.reduce(0.0, +) / Double(moodScores.count)
        let trend = moodScores.last! - moodScores.first!
        
        let description: String
        if trend > 0.5 {
            description = "Your mood has been improving over the past week. Keep up the positive momentum!"
        } else if trend < -0.5 {
            description = "Your mood has been declining over the past week. Consider what factors might be affecting your wellbeing."
        } else {
            description = "Your mood has been relatively stable over the past week, averaging \(String(format: "%.1f", averageMood)) out of 5."
        }
        
        return UserInsight(
            type: .pattern,
            title: "Weekly Mood Trend",
            description: description,
            confidence: 0.8,
            dataPoints: 7,
            metadata: InsightMetadata(
                relatedCheckInIds: recentCheckIns.map { $0.id },
                frequencyData: ["averageMood": Int(averageMood * 100)]
            )
        )
    }
    
    private func analyzeTimeOfDayMoodPattern(_ checkIns: [DailyCheckIn]) async throws -> UserInsight? {
        guard checkIns.count >= 14 else { return nil }
        
        let calendar = Calendar.current
        var morningMoods: [Double] = []
        var afternoonMoods: [Double] = []
        var eveningMoods: [Double] = []
        
        for checkIn in checkIns {
            let hour = calendar.component(.hour, from: checkIn.date)
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
            
            if hour < 12 {
                morningMoods.append(moodScore)
            } else if hour < 17 {
                afternoonMoods.append(moodScore)
            } else {
                eveningMoods.append(moodScore)
            }
        }
        
        let morningAvg = morningMoods.reduce(0.0, +) / Double(morningMoods.count)
        let afternoonAvg = afternoonMoods.reduce(0.0, +) / Double(afternoonMoods.count)
        let eveningAvg = eveningMoods.reduce(0.0, +) / Double(eveningMoods.count)
        
        let bestTime: String
        let worstTime: String
        
        if morningAvg > afternoonAvg && morningAvg > eveningAvg {
            bestTime = "morning"
        } else if afternoonAvg > morningAvg && afternoonAvg > eveningAvg {
            bestTime = "afternoon"
        } else {
            bestTime = "evening"
        }
        
        if morningAvg < afternoonAvg && morningAvg < eveningAvg {
            worstTime = "morning"
        } else if afternoonAvg < morningAvg && afternoonAvg < eveningAvg {
            worstTime = "afternoon"
        } else {
            worstTime = "evening"
        }
        
        return UserInsight(
            type: .pattern,
            title: "Time of Day Mood Pattern",
            description: "You tend to feel best during the \(bestTime) and less energetic during the \(worstTime). Consider scheduling important tasks during your peak hours.",
            confidence: 0.7,
            dataPoints: checkIns.count,
            metadata: InsightMetadata(
                frequencyData: [
                    "morningMood": Int(morningAvg * 100),
                    "afternoonMood": Int(afternoonAvg * 100),
                    "eveningMood": Int(eveningAvg * 100)
                ]
            )
        )
    }
    
    private func analyzeActivityMoodCorrelations(_ checkIns: [DailyCheckIn]) async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        
        // Analyze sleep quality correlation
        if let sleepInsight = try await analyzeSleepMoodCorrelation(checkIns) {
            insights.append(sleepInsight)
        }
        
        // Analyze social interaction correlation
        if let socialInsight = try await analyzeSocialMoodCorrelation(checkIns) {
            insights.append(socialInsight)
        }
        
        // Analyze energy level correlation
        if let energyInsight = try await analyzeEnergyMoodCorrelation(checkIns) {
            insights.append(energyInsight)
        }
        
        return insights
    }
    
    // MARK: - Task Pattern Analysis
    
    private func analyzeTaskPatterns() async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        let tasks = taskService.allTasks
        
        // Analyze task completion patterns
        let completionPatterns = try await analyzeTaskCompletionPatterns(tasks)
        insights.append(contentsOf: completionPatterns)
        
        // Analyze task category patterns
        let categoryPatterns = try await analyzeTaskCategoryPatterns(tasks)
        insights.append(contentsOf: categoryPatterns)
        
        // Analyze task priority patterns
        let priorityPatterns = try await analyzeTaskPriorityPatterns(tasks)
        insights.append(contentsOf: priorityPatterns)
        
        return insights
    }
    
    // MARK: - Goal Pattern Analysis
    
    private func analyzeGoalPatterns() async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        let goals = goalService.activeGoals
        
        // Analyze goal progress patterns
        let progressPatterns = try await analyzeGoalProgressPatterns(goals)
        insights.append(contentsOf: progressPatterns)
        
        // Analyze goal category patterns
        let categoryPatterns = try await analyzeGoalCategoryPatterns(goals)
        insights.append(contentsOf: categoryPatterns)
        
        return insights
    }
    
    // MARK: - Behavioral Pattern Analysis
    
    private func analyzeBehavioralPatterns() async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        
        // Analyze check-in frequency patterns
        let frequencyPatterns = try await analyzeCheckInFrequencyPatterns()
        insights.append(contentsOf: frequencyPatterns)
        
        // Analyze engagement patterns
        let engagementPatterns = try await analyzeEngagementPatterns()
        insights.append(contentsOf: engagementPatterns)
        
        return insights
    }
    
    // MARK: - Helper Methods
    
    private func filterInsights(_ insights: [UserInsight]) -> [UserInsight] {
        // Remove expired insights
        let currentInsights = insights.filter { !$0.isExpired }
        
        // Sort by confidence and recency
        return currentInsights.sorted { insight1, insight2 in
            if insight1.confidence == insight2.confidence {
                return insight1.createdAt > insight2.createdAt
            }
            return insight1.confidence > insight2.confidence
        }
    }
    
    private func saveInsights() {
        if let encoded = try? JSONEncoder().encode(insights) {
            userDefaults.set(encoded, forKey: insightsKey)
        }
    }
    
    private func loadInsights() {
        guard let data = userDefaults.data(forKey: insightsKey),
              let loadedInsights = try? JSONDecoder().decode([UserInsight].self, from: data) else {
            return
        }
        insights = loadedInsights
    }
}

// MARK: - Correlation Analysis

extension PatternAnalysisService {
    private func analyzeSleepMoodCorrelation(_ checkIns: [DailyCheckIn]) async throws -> UserInsight? {
        let sleepCheckIns = checkIns.filter { $0.sleep != nil }
        guard sleepCheckIns.count >= 7 else { return nil }
        
        var goodSleepMoods: [Double] = []
        var badSleepMoods: [Double] = []
        
        for checkIn in sleepCheckIns {
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
            
            if checkIn.sleep == 2 { // Great sleep
                goodSleepMoods.append(moodScore)
            } else if checkIn.sleep == 0 { // Bad sleep
                badSleepMoods.append(moodScore)
            }
        }
        
        guard !goodSleepMoods.isEmpty && !badSleepMoods.isEmpty else { return nil }
        
        let goodSleepAvg = goodSleepMoods.reduce(0.0, +) / Double(goodSleepMoods.count)
        let badSleepAvg = badSleepMoods.reduce(0.0, +) / Double(badSleepMoods.count)
        let difference = goodSleepAvg - badSleepAvg
        
        if abs(difference) >= 0.5 {
            let description = difference > 0 ?
                "You tend to feel \(String(format: "%.1f", difference)) points better on days with good sleep. Prioritize your sleep schedule!" :
                "Surprisingly, your mood doesn't seem strongly tied to sleep quality. Consider other factors that might be more influential."
            
            return UserInsight(
                type: .correlation,
                title: "Sleep-Mood Connection",
                description: description,
                confidence: abs(difference) / 4.0, // Max difference is 4.0
                dataPoints: sleepCheckIns.count,
                metadata: InsightMetadata(
                    frequencyData: [
                        "goodSleepMood": Int(goodSleepAvg * 100),
                        "badSleepMood": Int(badSleepAvg * 100)
                    ]
                )
            )
        }
        
        return nil
    }
    
    private func analyzeSocialMoodCorrelation(_ checkIns: [DailyCheckIn]) async throws -> UserInsight? {
        let socialCheckIns = checkIns.filter { $0.social != nil }
        guard socialCheckIns.count >= 7 else { return nil }
        
        var socialMoods: [Double] = []
        var aloneMoods: [Double] = []
        
        for checkIn in socialCheckIns {
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
            
            if checkIn.social == 2 { // With Others
                socialMoods.append(moodScore)
            } else if checkIn.social == 0 { // Alone
                aloneMoods.append(moodScore)
            }
        }
        
        guard !socialMoods.isEmpty && !aloneMoods.isEmpty else { return nil }
        
        let socialAvg = socialMoods.reduce(0.0, +) / Double(socialMoods.count)
        let aloneAvg = aloneMoods.reduce(0.0, +) / Double(aloneMoods.count)
        let difference = socialAvg - aloneAvg
        
        if abs(difference) >= 0.5 {
            let description = difference > 0 ?
                "You tend to feel \(String(format: "%.1f", difference)) points better on days with more social interaction. Consider scheduling more social activities!" :
                "You seem to thrive with more alone time, feeling \(String(format: "%.1f", abs(difference))) points better. Honor your need for solitude."
            
            return UserInsight(
                type: .correlation,
                title: "Social-Mood Connection",
                description: description,
                confidence: abs(difference) / 4.0,
                dataPoints: socialCheckIns.count,
                metadata: InsightMetadata(
                    frequencyData: [
                        "socialMood": Int(socialAvg * 100),
                        "aloneMood": Int(aloneAvg * 100)
                    ]
                )
            )
        }
        
        return nil
    }
    
    private func analyzeEnergyMoodCorrelation(_ checkIns: [DailyCheckIn]) async throws -> UserInsight? {
        let energyCheckIns = checkIns.filter { $0.energy != nil }
        guard energyCheckIns.count >= 7 else { return nil }
        
        var highEnergyMoods: [Double] = []
        var lowEnergyMoods: [Double] = []
        
        for checkIn in energyCheckIns {
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
            
            if checkIn.energy == 2 { // High Energy
                highEnergyMoods.append(moodScore)
            } else if checkIn.energy == 0 { // Low Energy
                lowEnergyMoods.append(moodScore)
            }
        }
        
        guard !highEnergyMoods.isEmpty && !lowEnergyMoods.isEmpty else { return nil }
        
        let highEnergyAvg = highEnergyMoods.reduce(0.0, +) / Double(highEnergyMoods.count)
        let lowEnergyAvg = lowEnergyMoods.reduce(0.0, +) / Double(lowEnergyMoods.count)
        let difference = highEnergyAvg - lowEnergyAvg
        
        if abs(difference) >= 0.5 {
            let description = difference > 0 ?
                "Higher energy levels correlate with better moods (\(String(format: "%.1f", difference)) points higher). Focus on activities that boost your energy!" :
                "Your mood seems relatively stable regardless of energy levels. You handle low-energy days well!"
            
            return UserInsight(
                type: .correlation,
                title: "Energy-Mood Connection",
                description: description,
                confidence: abs(difference) / 4.0,
                dataPoints: energyCheckIns.count,
                metadata: InsightMetadata(
                    frequencyData: [
                        "highEnergyMood": Int(highEnergyAvg * 100),
                        "lowEnergyMood": Int(lowEnergyAvg * 100)
                    ]
                )
            )
        }
        
        return nil
    }
}

// MARK: - Task Pattern Analysis

extension PatternAnalysisService {
    private func analyzeTaskCompletionPatterns(_ tasks: [AppTask]) async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        
        // Analyze completion rate by time of day
        let timeOfDayPattern = try await analyzeTaskCompletionTimePattern(tasks)
        if let timeInsight = timeOfDayPattern {
            insights.append(timeInsight)
        }
        
        // Analyze completion rate by task size
        let sizePattern = try await analyzeTaskSizePattern(tasks)
        if let sizeInsight = sizePattern {
            insights.append(sizeInsight)
        }
        
        // Analyze completion rate by priority
        let priorityPattern = try await analyzeTaskPriorityPattern(tasks)
        if let priorityInsight = priorityPattern {
            insights.append(priorityInsight)
        }
        
        return insights
    }
    
    private func analyzeTaskCompletionTimePattern(_ tasks: [AppTask]) async throws -> UserInsight? {
        let completedTasks = tasks.filter { $0.isCompleted && $0.completedDate != nil }
        guard completedTasks.count >= 10 else { return nil }
        
        let calendar = Calendar.current
        var morningCompletions = 0
        var afternoonCompletions = 0
        var eveningCompletions = 0
        
        for task in completedTasks {
            let hour = calendar.component(.hour, from: task.completedDate!)
            if hour < 12 {
                morningCompletions += 1
            } else if hour < 17 {
                afternoonCompletions += 1
            } else {
                eveningCompletions += 1
            }
        }
        
        let total = Double(completedTasks.count)
        let morningRate = Double(morningCompletions) / total
        let afternoonRate = Double(afternoonCompletions) / total
        let eveningRate = Double(eveningCompletions) / total
        
        let bestTime: String
        let rate: Double
        
        if morningRate > afternoonRate && morningRate > eveningRate {
            bestTime = "morning"
            rate = morningRate
        } else if afternoonRate > morningRate && afternoonRate > eveningRate {
            bestTime = "afternoon"
            rate = afternoonRate
        } else {
            bestTime = "evening"
            rate = eveningRate
        }
        
        return UserInsight(
            type: .pattern,
            title: "Task Completion Time Pattern",
            description: "You're most productive in the \(bestTime), completing \(Int(rate * 100))% of your tasks during these hours. Consider scheduling important tasks during this time.",
            confidence: 0.7,
            dataPoints: completedTasks.count,
            metadata: InsightMetadata(
                frequencyData: [
                    "morningRate": Int(morningRate * 100),
                    "afternoonRate": Int(afternoonRate * 100),
                    "eveningRate": Int(eveningRate * 100)
                ]
            )
        )
    }
    
    private func analyzeTaskSizePattern(_ tasks: [AppTask]) async throws -> UserInsight? {
        let completedTasks = tasks.filter { $0.isCompleted && $0.completedDate != nil }
        guard completedTasks.count >= 10 else { return nil }
        
        var smallTaskCompletions = 0
        var mediumTaskCompletions = 0
        var largeTaskCompletions = 0
        
        for task in completedTasks {
            if let hours = task.estimatedHours {
                if hours <= 1 {
                    smallTaskCompletions += 1
                } else if hours <= 4 {
                    mediumTaskCompletions += 1
                } else {
                    largeTaskCompletions += 1
                }
            }
        }
        
        let total = Double(smallTaskCompletions + mediumTaskCompletions + largeTaskCompletions)
        guard total > 0 else { return nil }
        
        let smallRate = Double(smallTaskCompletions) / total
        let mediumRate = Double(mediumTaskCompletions) / total
        let largeRate = Double(largeTaskCompletions) / total
        
        let description: String
        if smallRate > mediumRate && smallRate > largeRate {
            description = "You excel at completing small tasks (≤1 hour), with a \(Int(smallRate * 100))% completion rate. Consider breaking down larger tasks into smaller chunks."
        } else if mediumRate > smallRate && mediumRate > largeRate {
            description = "You handle medium-sized tasks (1-4 hours) well, with a \(Int(mediumRate * 100))% completion rate. This seems to be your sweet spot for task size."
        } else {
            description = "You show strong follow-through on large tasks (>4 hours), with a \(Int(largeRate * 100))% completion rate. You're good at tackling big challenges!"
        }
        
        return UserInsight(
            type: .pattern,
            title: "Task Size Pattern",
            description: description,
            confidence: 0.7,
            dataPoints: Int(total),
            metadata: InsightMetadata(
                frequencyData: [
                    "smallRate": Int(smallRate * 100),
                    "mediumRate": Int(mediumRate * 100),
                    "largeRate": Int(largeRate * 100)
                ]
            )
        )
    }
    
    private func analyzeTaskPriorityPattern(_ tasks: [AppTask]) async throws -> UserInsight? {
        let completedTasks = tasks.filter { $0.isCompleted }
        guard completedTasks.count >= 10 else { return nil }
        
        var highPriorityCompletions = 0
        var mediumPriorityCompletions = 0
        var lowPriorityCompletions = 0
        
        var totalHighPriority = 0
        var totalMediumPriority = 0
        var totalLowPriority = 0
        
        for task in tasks {
            switch task.priority {
            case .high:
                totalHighPriority += 1
                if task.isCompleted { highPriorityCompletions += 1 }
            case .medium:
                totalMediumPriority += 1
                if task.isCompleted { mediumPriorityCompletions += 1 }
            case .low:
                totalLowPriority += 1
                if task.isCompleted { lowPriorityCompletions += 1 }
            }
        }
        
        let highRate = totalHighPriority > 0 ? Double(highPriorityCompletions) / Double(totalHighPriority) : 0
        let mediumRate = totalMediumPriority > 0 ? Double(mediumPriorityCompletions) / Double(totalMediumPriority) : 0
        let lowRate = totalLowPriority > 0 ? Double(lowPriorityCompletions) / Double(totalLowPriority) : 0
        
        let description: String
        if highRate > mediumRate && highRate > lowRate {
            description = "You prioritize high-priority tasks well, completing \(Int(highRate * 100))% of them. Keep focusing on what's most important!"
        } else if lowRate > highRate && lowRate > mediumRate {
            description = "You tend to complete more low-priority tasks (\(Int(lowRate * 100))%). Consider focusing more on high-priority items for greater impact."
        } else {
            description = "You maintain a balanced approach to task priorities, with similar completion rates across all levels."
        }
        
        return UserInsight(
            type: .pattern,
            title: "Task Priority Pattern",
            description: description,
            confidence: 0.8,
            dataPoints: tasks.count,
            metadata: InsightMetadata(
                frequencyData: [
                    "highRate": Int(highRate * 100),
                    "mediumRate": Int(mediumRate * 100),
                    "lowRate": Int(lowRate * 100)
                ]
            )
        )
    }
}

// MARK: - Goal Pattern Analysis

extension PatternAnalysisService {
    private func analyzeGoalProgressPatterns(_ goals: [Goal]) async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        
        // Analyze goal completion rate
        let completionPattern = try await analyzeGoalCompletionPattern(goals)
        if let completionInsight = completionPattern {
            insights.append(completionInsight)
        }
        
        // Analyze goal category success
        let categoryPattern = try await analyzeGoalCategorySuccessPattern(goals)
        if let categoryInsight = categoryPattern {
            insights.append(categoryInsight)
        }
        
        // Analyze goal timeframe success
        let timeframePattern = try await analyzeGoalTimeframePattern(goals)
        if let timeframeInsight = timeframePattern {
            insights.append(timeframeInsight)
        }
        
        return insights
    }
    
    private func analyzeGoalCompletionPattern(_ goals: [Goal]) async throws -> UserInsight? {
        let completedGoals = goals.filter { $0.isCompleted }
        guard goals.count >= 5 else { return nil }
        
        let completionRate = Double(completedGoals.count) / Double(goals.count)
        let averageProgress = goals.reduce(0.0) { $0 + ($1.progressPercentage / 100.0) } / Double(goals.count)
        
        let description: String
        if completionRate > 0.7 {
            description = "You have an impressive goal completion rate of \(Int(completionRate * 100))%! Your commitment to achieving your goals is paying off."
        } else if completionRate > 0.4 {
            description = "You're making steady progress with a \(Int(completionRate * 100))% goal completion rate. Keep pushing forward!"
        } else {
            description = "Your current goal completion rate is \(Int(completionRate * 100))%. Consider setting more achievable milestones or adjusting your approach."
        }
        
        return UserInsight(
            type: .pattern,
            title: "Goal Achievement Pattern",
            description: description,
            confidence: 0.8,
            dataPoints: goals.count,
            metadata: InsightMetadata(
                frequencyData: [
                    "completionRate": Int(completionRate * 100),
                    "averageProgress": Int(averageProgress * 100)
                ]
            )
        )
    }
    
    private func analyzeGoalCategorySuccessPattern(_ goals: [Goal]) async throws -> UserInsight? {
        guard goals.count >= 5 else { return nil }
        
        var categorySuccessRates: [TaskCategory: (completed: Int, total: Int)] = [:]
        
        for goal in goals {
            let category = goal.category
            var stats = categorySuccessRates[category] ?? (0, 0)
            if goal.isCompleted {
                stats.completed += 1
            }
            stats.total += 1
            categorySuccessRates[category] = stats
        }
        
        var bestCategory: TaskCategory?
        var bestRate = 0.0
        var worstCategory: TaskCategory?
        var worstRate = 1.0
        
        for (category, stats) in categorySuccessRates {
            let rate = Double(stats.completed) / Double(stats.total)
            if rate > bestRate {
                bestRate = rate
                bestCategory = category
            }
            if rate < worstRate {
                worstRate = rate
                worstCategory = category
            }
        }
        
        guard let best = bestCategory, let worst = worstCategory else { return nil }
        
        let description = "You excel in \(best.displayName.lowercased()) goals with a \(Int(bestRate * 100))% success rate, while \(worst.displayName.lowercased()) goals show more room for growth at \(Int(worstRate * 100))%. Consider applying your successful strategies across categories."
        
        return UserInsight(
            type: .pattern,
            title: "Goal Category Success Pattern",
            description: description,
            confidence: 0.7,
            dataPoints: goals.count,
            metadata: InsightMetadata(
                frequencyData: categorySuccessRates.mapValues { Int(Double($0.completed) / Double($0.total) * 100) }
            )
        )
    }
    
    private func analyzeGoalTimeframePattern(_ goals: [Goal]) async throws -> UserInsight? {
        let completedGoals = goals.filter { $0.isCompleted }
        guard completedGoals.count >= 5 else { return nil }
        
        var shortTermSuccess = 0
        var shortTermTotal = 0
        var longTermSuccess = 0
        var longTermTotal = 0
        
        let calendar = Calendar.current
        let thirtyDays: TimeInterval = 30 * 24 * 60 * 60
        
        for goal in goals {
            let duration = goal.endDate.timeIntervalSince(goal.startDate)
            if duration <= thirtyDays {
                shortTermTotal += 1
                if goal.isCompleted { shortTermSuccess += 1 }
            } else {
                longTermTotal += 1
                if goal.isCompleted { longTermSuccess += 1 }
            }
        }
        
        let shortTermRate = shortTermTotal > 0 ? Double(shortTermSuccess) / Double(shortTermTotal) : 0
        let longTermRate = longTermTotal > 0 ? Double(longTermSuccess) / Double(longTermTotal) : 0
        
        let description: String
        if abs(shortTermRate - longTermRate) < 0.2 {
            description = "You show consistent success rates across both short-term (\(Int(shortTermRate * 100))%) and long-term (\(Int(longTermRate * 100))%) goals. Keep maintaining this balanced approach!"
        } else if shortTermRate > longTermRate {
            description = "You excel at short-term goals (\(Int(shortTermRate * 100))% success rate) compared to long-term ones (\(Int(longTermRate * 100))%). Consider breaking down long-term goals into shorter milestones."
        } else {
            description = "You show strong follow-through on long-term goals (\(Int(longTermRate * 100))% success rate) compared to short-term ones (\(Int(shortTermRate * 100))%). Your persistence pays off!"
        }
        
        return UserInsight(
            type: .pattern,
            title: "Goal Timeframe Pattern",
            description: description,
            confidence: 0.7,
            dataPoints: goals.count,
            metadata: InsightMetadata(
                frequencyData: [
                    "shortTermRate": Int(shortTermRate * 100),
                    "longTermRate": Int(longTermRate * 100)
                ]
            )
        )
    }
} 

// MARK: - Behavioral Pattern Analysis

extension PatternAnalysisService {
    private func analyzeCheckInFrequencyPatterns() async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        let checkIns = checkInService.checkIns
        
        // Analyze daily check-in consistency
        let consistencyPattern = try await analyzeCheckInConsistencyPattern(checkIns)
        if let consistencyInsight = consistencyPattern {
            insights.append(consistencyInsight)
        }
        
        // Analyze check-in timing patterns
        let timingPattern = try await analyzeCheckInTimingPattern(checkIns)
        if let timingInsight = timingPattern {
            insights.append(timingInsight)
        }
        
        // Analyze check-in detail patterns
        let detailPattern = try await analyzeCheckInDetailPattern(checkIns)
        if let detailInsight = detailPattern {
            insights.append(detailInsight)
        }
        
        return insights
    }
    
    private func analyzeCheckInConsistencyPattern(_ checkIns: [DailyCheckIn]) async throws -> UserInsight? {
        guard checkIns.count >= 14 else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today)!
        
        var daysCovered = Set<Date>()
        for checkIn in checkIns {
            if checkIn.date >= twoWeeksAgo && checkIn.date <= today {
                let normalizedDate = calendar.startOfDay(for: checkIn.date)
                daysCovered.insert(normalizedDate)
            }
        }
        
        let totalDays = calendar.dateComponents([.day], from: twoWeeksAgo, to: today).day! + 1
        let consistencyRate = Double(daysCovered.count) / Double(totalDays)
        
        let description: String
        if consistencyRate >= 0.9 {
            description = "Excellent check-in consistency! You've logged your mood \(Int(consistencyRate * 100))% of days in the past two weeks. This regular reflection helps build self-awareness."
        } else if consistencyRate >= 0.7 {
            description = "Good check-in habits - you've logged your mood \(Int(consistencyRate * 100))% of days in the past two weeks. Try to make it a daily ritual for even better insights."
        } else {
            description = "You've logged your mood \(Int(consistencyRate * 100))% of days in the past two weeks. More regular check-ins will help build a clearer picture of your patterns."
        }
        
        return UserInsight(
            type: .pattern,
            title: "Check-in Consistency",
            description: description,
            confidence: 0.9,
            dataPoints: totalDays,
            metadata: InsightMetadata(
                frequencyData: [
                    "consistencyRate": Int(consistencyRate * 100),
                    "daysCovered": daysCovered.count,
                    "totalDays": totalDays
                ]
            )
        )
    }
    
    private func analyzeCheckInTimingPattern(_ checkIns: [DailyCheckIn]) async throws -> UserInsight? {
        guard checkIns.count >= 14 else { return nil }
        
        let calendar = Calendar.current
        var morningCheckIns = 0
        var afternoonCheckIns = 0
        var eveningCheckIns = 0
        
        for checkIn in checkIns {
            let hour = calendar.component(.hour, from: checkIn.date)
            if hour < 12 {
                morningCheckIns += 1
            } else if hour < 17 {
                afternoonCheckIns += 1
            } else {
                eveningCheckIns += 1
            }
        }
        
        let total = Double(checkIns.count)
        let morningRate = Double(morningCheckIns) / total
        let afternoonRate = Double(afternoonCheckIns) / total
        let eveningRate = Double(eveningCheckIns) / total
        
        let preferredTime: String
        let rate: Double
        
        if morningRate > afternoonRate && morningRate > eveningRate {
            preferredTime = "morning"
            rate = morningRate
        } else if afternoonRate > morningRate && afternoonRate > eveningRate {
            preferredTime = "afternoon"
            rate = afternoonRate
        } else {
            preferredTime = "evening"
            rate = eveningRate
        }
        
        return UserInsight(
            type: .pattern,
            title: "Check-in Timing Pattern",
            description: "You tend to check in during the \(preferredTime) (\(Int(rate * 100))% of entries). This consistency helps build a reliable reflection habit.",
            confidence: 0.8,
            dataPoints: checkIns.count,
            metadata: InsightMetadata(
                frequencyData: [
                    "morningRate": Int(morningRate * 100),
                    "afternoonRate": Int(afternoonRate * 100),
                    "eveningRate": Int(eveningRate * 100)
                ]
            )
        )
    }
    
    private func analyzeCheckInDetailPattern(_ checkIns: [DailyCheckIn]) async throws -> UserInsight? {
        guard checkIns.count >= 14 else { return nil }
        
        let detailedCheckIns = checkIns.filter { checkIn in
            let hasEnergy = checkIn.energy != nil
            let hasSleep = checkIn.sleep != nil
            let hasSocial = checkIn.social != nil
            let hasHighlight = checkIn.highlight != nil
            return hasEnergy && hasSleep && hasSocial && hasHighlight
        }
        
        let detailRate = Double(detailedCheckIns.count) / Double(checkIns.count)
        
        let description: String
        if detailRate >= 0.8 {
            description = "You're great at providing comprehensive check-ins! \(Int(detailRate * 100))% of your entries include complete details about energy, sleep, social interaction, and highlights."
        } else if detailRate >= 0.5 {
            description = "You provide detailed check-ins \(Int(detailRate * 100))% of the time. More complete entries can help uncover deeper patterns in your wellbeing."
        } else {
            description = "You tend to keep check-ins brief, with \(Int(detailRate * 100))% including full details. Consider adding more context for richer insights."
        }
        
        return UserInsight(
            type: .pattern,
            title: "Check-in Detail Pattern",
            description: description,
            confidence: 0.8,
            dataPoints: checkIns.count,
            metadata: InsightMetadata(
                frequencyData: [
                    "detailRate": Int(detailRate * 100),
                    "detailedCheckIns": detailedCheckIns.count,
                    "totalCheckIns": checkIns.count
                ]
            )
        )
    }
    
    private func analyzeEngagementPatterns() async throws -> [UserInsight] {
        var insights: [UserInsight] = []
        
        // Analyze task engagement
        let taskEngagement = try await analyzeTaskEngagementPattern()
        if let taskInsight = taskEngagement {
            insights.append(taskInsight)
        }
        
        // Analyze goal engagement
        let goalEngagement = try await analyzeGoalEngagementPattern()
        if let goalInsight = goalEngagement {
            insights.append(goalInsight)
        }
        
        return insights
    }
    
    private func analyzeTaskEngagementPattern() async throws -> UserInsight? {
        let tasks = taskService.allTasks
        guard !tasks.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let recentTasks = tasks.filter { $0.createdDate >= lastWeek }
        let completedRecentTasks = recentTasks.filter { $0.isCompleted }
        
        let taskCreationRate = Double(recentTasks.count) / 7.0
        let taskCompletionRate = recentTasks.isEmpty ? 0 : Double(completedRecentTasks.count) / Double(recentTasks.count)
        
        let description: String
        if taskCreationRate >= 2.0 && taskCompletionRate >= 0.7 {
            description = "Strong task engagement! You're creating \(String(format: "%.1f", taskCreationRate)) tasks per day and completing \(Int(taskCompletionRate * 100))% of them."
        } else if taskCreationRate >= 1.0 || taskCompletionRate >= 0.5 {
            description = "Moderate task engagement with \(String(format: "%.1f", taskCreationRate)) tasks created per day and \(Int(taskCompletionRate * 100))% completion rate."
        } else {
            description = "Light task engagement recently. Consider using tasks more actively to track and achieve your goals."
        }
        
        return UserInsight(
            type: .pattern,
            title: "Task Engagement Pattern",
            description: description,
            confidence: 0.8,
            dataPoints: tasks.count,
            metadata: InsightMetadata(
                frequencyData: [
                    "taskCreationRate": Int(taskCreationRate * 100),
                    "taskCompletionRate": Int(taskCompletionRate * 100)
                ]
            )
        )
    }
    
    private func analyzeGoalEngagementPattern() async throws -> UserInsight? {
        let goals = goalService.activeGoals
        guard !goals.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!
        
        let recentGoals = goals.filter { $0.startDate >= lastMonth }
        let activeGoalsWithProgress = goals.filter { $0.progressPercentage > 0 }
        
        let goalCreationRate = Double(recentGoals.count)
        let goalProgressRate = Double(activeGoalsWithProgress.count) / Double(goals.count)
        
        let description: String
        if goalCreationRate >= 3.0 && goalProgressRate >= 0.7 {
            description = "Excellent goal engagement! You've set \(recentGoals.count) new goals this month and are making progress on \(Int(goalProgressRate * 100))% of your goals."
        } else if goalCreationRate >= 1.0 || goalProgressRate >= 0.5 {
            description = "Good goal engagement with \(recentGoals.count) new goals this month and progress on \(Int(goalProgressRate * 100))% of your goals."
        } else {
            description = "Consider setting new goals or revisiting existing ones to maintain momentum. \(Int(goalProgressRate * 100))% of your goals show recent progress."
        }
        
        return UserInsight(
            type: .pattern,
            title: "Goal Engagement Pattern",
            description: description,
            confidence: 0.8,
            dataPoints: goals.count,
            metadata: InsightMetadata(
                frequencyData: [
                    "recentGoals": recentGoals.count,
                    "goalProgressRate": Int(goalProgressRate * 100)
                ]
            )
        )
    }
} 