import Foundation
import Combine

class HabitService: ObservableObject {
    static let shared = HabitService()
    
    @Published var habits: [Habit] = []
    @Published var isLoading = false
    
    private let patternAnalysisService = PatternAnalysisService.shared
    private let goalService = GoalService.shared
    private let userDefaults = UserDefaults.standard
    private let habitsKey = "flect_habits"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadHabits()
        
        // Subscribe to pattern analysis updates
        patternAnalysisService.$insights
            .sink { [weak self] _ in
                self?.suggestNewHabits()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Habit Management
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveHabits()
        }
    }
    
    func deleteHabit(_ habitId: UUID) {
        habits.removeAll { $0.id == habitId }
        saveHabits()
    }
    
    func archiveHabit(_ habitId: UUID) {
        if var habit = getHabit(by: habitId) {
            habit.isArchived = true
            updateHabit(habit)
        }
    }
    
    func completeHabit(_ habitId: UUID) {
        if var habit = getHabit(by: habitId) {
            habit.completeHabit()
            updateHabit(habit)
        }
    }
    
    func getHabit(by id: UUID) -> Habit? {
        habits.first { $0.id == id }
    }
    
    // MARK: - Habit Filtering
    
    func getActiveHabits() -> [Habit] {
        habits.filter { !$0.isArchived }
    }
    
    func getArchivedHabits() -> [Habit] {
        habits.filter { $0.isArchived }
    }
    
    func getHabits(for category: TaskCategory) -> [Habit] {
        habits.filter { $0.category == category && !$0.isArchived }
    }
    
    func getHabits(for timeOfDay: HabitTimeOfDay) -> [Habit] {
        habits.filter { $0.timeOfDay == timeOfDay && !$0.isArchived }
    }
    
    func getHabits(for frequency: HabitFrequency) -> [Habit] {
        habits.filter { $0.frequency == frequency && !$0.isArchived }
    }
    
    func getHabits(for goal: UUID) -> [Habit] {
        habits.filter { $0.goalId == goal && !$0.isArchived }
    }
    
    func getHabitsForToday() -> [Habit] {
        let activeHabits = getActiveHabits()
        return activeHabits.filter { !$0.isCompletedToday }
    }
    
    func getOverdueHabits() -> [Habit] {
        let activeHabits = getActiveHabits()
        return activeHabits.filter { $0.isOverdue }
    }
    
    // MARK: - Habit Analytics
    
    func getHabitAnalytics() -> HabitAnalytics {
        let activeHabits = getActiveHabits()
        let totalHabits = activeHabits.count
        let completedToday = activeHabits.filter { $0.isCompletedToday }.count
        let overdueHabits = activeHabits.filter { $0.isOverdue }.count
        
        let averageStreak = activeHabits.reduce(0.0) { $0 + Double($1.currentStreak) } / Double(max(1, totalHabits))
        let longestStreak = activeHabits.map { $0.longestStreak }.max() ?? 0
        
        let categoryBreakdown = TaskCategory.allCases.map { category in
            let categoryHabits = getHabits(for: category)
            let completionRate = categoryHabits.reduce(0.0) { $0 + $1.completionRate } / Double(max(1, categoryHabits.count))
            return HabitCategoryBreakdown(
                category: category,
                totalHabits: categoryHabits.count,
                completionRate: completionRate
            )
        }
        
        let timeOfDayBreakdown = HabitTimeOfDay.allCases.map { timeOfDay in
            let timeHabits = getHabits(for: timeOfDay)
            let completionRate = timeHabits.reduce(0.0) { $0 + $1.completionRate } / Double(max(1, timeHabits.count))
            return HabitTimeBreakdown(
                timeOfDay: timeOfDay,
                totalHabits: timeHabits.count,
                completionRate: completionRate
            )
        }
        
        let frequencyBreakdown = HabitFrequency.allCases.map { frequency in
            let frequencyHabits = getHabits(for: frequency)
            let completionRate = frequencyHabits.reduce(0.0) { $0 + $1.completionRate } / Double(max(1, frequencyHabits.count))
            return HabitFrequencyBreakdown(
                frequency: frequency,
                totalHabits: frequencyHabits.count,
                completionRate: completionRate
            )
        }
        
        return HabitAnalytics(
            totalHabits: totalHabits,
            completedToday: completedToday,
            overdueHabits: overdueHabits,
            averageStreak: averageStreak,
            longestStreak: longestStreak,
            categoryBreakdown: categoryBreakdown,
            timeOfDayBreakdown: timeOfDayBreakdown,
            frequencyBreakdown: frequencyBreakdown
        )
    }
    
    // MARK: - AI Habit Suggestions
    
    private func suggestNewHabits() {
        let insights = patternAnalysisService.insights
        
        // Suggest habits based on mood patterns
        if let sleepInsight = insights.first(where: { $0.title == "Sleep-Mood Connection" }),
           let sleepData = sleepInsight.metadata?.frequencyData,
           let goodSleepMood = sleepData["goodSleepMood"],
           let badSleepMood = sleepData["badSleepMood"],
           (goodSleepMood - badSleepMood) >= 20 { // 20% difference in mood
            
            let sleepHabit = Habit(
                title: "Maintain consistent sleep schedule",
                description: "Go to bed and wake up at the same time every day to improve sleep quality and mood.",
                category: .health,
                frequency: .daily,
                timeOfDay: .evening,
                source: .patternBased
            )
            
            if !habits.contains(where: { $0.title == sleepHabit.title }) {
                addHabit(sleepHabit)
            }
        }
        
        // Suggest habits based on social patterns
        if let socialInsight = insights.first(where: { $0.title == "Social-Mood Connection" }),
           let socialData = socialInsight.metadata?.frequencyData,
           let socialMood = socialData["socialMood"],
           let aloneMood = socialData["aloneMood"],
           (socialMood - aloneMood) >= 20 { // 20% difference in mood
            
            let socialHabit = Habit(
                title: "Schedule social interaction",
                description: "Plan regular social activities to maintain positive mood and connection.",
                category: .relationships,
                frequency: .weekly,
                timeOfDay: .anytime,
                source: .patternBased
            )
            
            if !habits.contains(where: { $0.title == socialHabit.title }) {
                addHabit(socialHabit)
            }
        }
        
        // Suggest habits based on energy patterns
        if let energyInsight = insights.first(where: { $0.title == "Energy-Mood Connection" }),
           let energyData = energyInsight.metadata?.frequencyData,
           let highEnergyMood = energyData["highEnergyMood"],
           let lowEnergyMood = energyData["lowEnergyMood"],
           (highEnergyMood - lowEnergyMood) >= 20 { // 20% difference in mood
            
            let energyHabit = Habit(
                title: "Daily energy boost activity",
                description: "Take a short walk or do some stretches to maintain energy levels.",
                category: .health,
                frequency: .daily,
                timeOfDay: .afternoon,
                source: .patternBased
            )
            
            if !habits.contains(where: { $0.title == energyHabit.title }) {
                addHabit(energyHabit)
            }
        }
        
        // Suggest habits based on goals
        for goal in goalService.activeGoals {
            let habitSuggestion = suggestHabitForGoal(goal)
            if let habit = habitSuggestion,
               !habits.contains(where: { $0.title == habit.title }) {
                addHabit(habit)
            }
        }
    }
    
    private func suggestHabitForGoal(_ goal: Goal) -> Habit? {
        // Example habit suggestions based on goal category
        switch goal.category {
        case .health:
            return Habit(
                title: "Exercise for 30 minutes",
                description: "Regular exercise to support your health goals.",
                category: .health,
                frequency: .daily,
                timeOfDay: .morning,
                source: .goalDerived,
                goalId: goal.id
            )
            
        case .learning:
            return Habit(
                title: "Study/practice session",
                description: "Dedicated learning time to progress toward your goal.",
                category: .learning,
                frequency: .daily,
                timeOfDay: .afternoon,
                source: .goalDerived,
                goalId: goal.id
            )
            
        case .mindfulness:
            return Habit(
                title: "Meditation practice",
                description: "Daily mindfulness to support mental wellbeing.",
                category: .mindfulness,
                frequency: .daily,
                timeOfDay: .morning,
                source: .goalDerived,
                goalId: goal.id
            )
            
        default:
            return nil
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            userDefaults.set(encoded, forKey: habitsKey)
        }
    }
    
    private func loadHabits() {
        guard let data = userDefaults.data(forKey: habitsKey),
              let loadedHabits = try? JSONDecoder().decode([Habit].self, from: data) else {
            return
        }
        habits = loadedHabits
    }
}

// MARK: - Analytics Types

struct HabitAnalytics {
    let totalHabits: Int
    let completedToday: Int
    let overdueHabits: Int
    let averageStreak: Double
    let longestStreak: Int
    let categoryBreakdown: [HabitCategoryBreakdown]
    let timeOfDayBreakdown: [HabitTimeBreakdown]
    let frequencyBreakdown: [HabitFrequencyBreakdown]
}

struct HabitCategoryBreakdown {
    let category: TaskCategory
    let totalHabits: Int
    let completionRate: Double
}

struct HabitTimeBreakdown {
    let timeOfDay: HabitTimeOfDay
    let totalHabits: Int
    let completionRate: Double
}

struct HabitFrequencyBreakdown {
    let frequency: HabitFrequency
    let totalHabits: Int
    let completionRate: Double
} 