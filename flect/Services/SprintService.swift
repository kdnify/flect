import Foundation
import Combine

class SprintService: ObservableObject {
    static let shared = SprintService()
    
    @Published var activeSprints: [Sprint] = []
    @Published var completedSprints: [Sprint] = []
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let sprintsKey = "user_sprints"
    
    private init() {
        loadSprints()
    }
    
    // MARK: - Sprint Management
    
    func createSprints(for goal: TwelveWeekGoal, suggestions: [SprintSuggestion]) -> [Sprint] {
        let calendar = Calendar.current
        var currentDate = Date()
        
        let sprints = suggestions.enumerated().map { index, suggestion in
            let sprint = Sprint(
                goalId: goal.id,
                title: suggestion.title,
                description: suggestion.description,
                startDate: currentDate,
                weekNumber: index + 1,
                targetMilestones: suggestion.suggestedMilestones.enumerated().map { milestoneIndex, milestoneTitle in
                    let milestoneDate = calendar.date(byAdding: .weekOfYear, value: milestoneIndex, to: currentDate) ?? currentDate
                    return SprintMilestone(
                        title: milestoneTitle,
                        description: "Milestone for \(suggestion.title)",
                        targetDate: milestoneDate
                    )
                }
            )
            
            // Add suggested tasks
            var sprintWithTasks = sprint
            sprintWithTasks.tasks = suggestion.estimatedTasks.enumerated().map { taskIndex, taskTitle in
                let taskDate = calendar.date(byAdding: .day, value: taskIndex * 2, to: currentDate) ?? currentDate
                return SprintTask(
                    title: taskTitle,
                    description: "Task for \(suggestion.title)",
                    priority: taskIndex == 0 ? .high : .medium,
                    dueDate: taskDate,
                    estimatedHours: Double.random(in: 1...4)
                )
            }
            
            // Move to next sprint start date
            currentDate = calendar.date(byAdding: .weekOfYear, value: 4, to: currentDate) ?? currentDate
            
            return sprintWithTasks
        }
        
        // Add to active sprints
        activeSprints.append(contentsOf: sprints)
        saveSprints()
        
        return sprints
    }
    
    func updateSprintProgress(sprintId: UUID, progress: Double) {
        if let index = activeSprints.firstIndex(where: { $0.id == sprintId }) {
            activeSprints[index].currentProgress = min(1.0, max(0.0, progress))
            
            // Check if sprint is completed
            if activeSprints[index].currentProgress >= 1.0 {
                completeSprint(sprintId: sprintId)
            }
            
            saveSprints()
        }
    }
    
    func completeTask(sprintId: UUID, taskId: UUID) {
        if let sprintIndex = activeSprints.firstIndex(where: { $0.id == sprintId }),
           let taskIndex = activeSprints[sprintIndex].tasks.firstIndex(where: { $0.id == taskId }) {
            
            activeSprints[sprintIndex].tasks[taskIndex].isCompleted = true
            activeSprints[sprintIndex].tasks[taskIndex].completedDate = Date()
            
            // Update sprint progress
            let completedTasks = activeSprints[sprintIndex].tasks.filter { $0.isCompleted }.count
            let totalTasks = activeSprints[sprintIndex].tasks.count
            let newProgress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
            
            updateSprintProgress(sprintId: sprintId, progress: newProgress)
        }
    }
    
    func completeMilestone(sprintId: UUID, milestoneId: UUID) {
        if let sprintIndex = activeSprints.firstIndex(where: { $0.id == sprintId }),
           let milestoneIndex = activeSprints[sprintIndex].targetMilestones.firstIndex(where: { $0.id == milestoneId }) {
            
            activeSprints[sprintIndex].targetMilestones[milestoneIndex].isCompleted = true
            activeSprints[sprintIndex].targetMilestones[milestoneIndex].completedDate = Date()
            
            saveSprints()
        }
    }
    
    private func completeSprint(sprintId: UUID) {
        if let index = activeSprints.firstIndex(where: { $0.id == sprintId }) {
            var completedSprint = activeSprints[index]
            completedSprint.isCompleted = true
            completedSprint.completedDate = Date()
            
            completedSprints.append(completedSprint)
            activeSprints.remove(at: index)
            
            saveSprints()
        }
    }
    
    // MARK: - Analytics
    
    func getSprintAnalytics(for sprint: Sprint) -> SprintAnalytics {
        let tasksCompleted = sprint.tasks.filter { $0.isCompleted }.count
        let totalTasks = sprint.tasks.count
        let completionRate = totalTasks > 0 ? Double(tasksCompleted) / Double(totalTasks) : 0.0
        
        // Calculate average task completion time
        let completedTasks = sprint.tasks.filter { $0.isCompleted && $0.completedDate != nil }
        let averageCompletionTime: TimeInterval? = completedTasks.isEmpty ? nil : {
            let totalTime = completedTasks.reduce(0) { total, task in
                guard let completedDate = task.completedDate else { return total }
                return total + completedDate.timeIntervalSince(sprint.startDate)
            }
            return totalTime / Double(completedTasks.count)
        }()
        
        // Calculate schedule status
        let calendar = Calendar.current
        let today = Date()
        let daysAheadOfSchedule: Int? = sprint.endDate > today ? calendar.dateComponents([.day], from: today, to: sprint.endDate).day : nil
        let daysBehindSchedule: Int? = sprint.endDate < today && !sprint.isCompleted ? calendar.dateComponents([.day], from: sprint.endDate, to: today).day : nil
        
        // Find most productive day (mock data for now)
        let mostProductiveDay = "Wednesday"
        
        return SprintAnalytics(
            sprint: sprint,
            tasksCompleted: tasksCompleted,
            totalTasks: totalTasks,
            averageTaskCompletionTime: averageCompletionTime,
            mostProductiveDay: mostProductiveDay,
            completionRate: completionRate,
            daysAheadOfSchedule: daysAheadOfSchedule,
            daysBehindSchedule: daysBehindSchedule
        )
    }
    
    func getActiveSprintsForGoal(goalId: UUID) -> [Sprint] {
        return activeSprints.filter { $0.goalId == goalId }
    }
    
    func getCompletedSprintsForGoal(goalId: UUID) -> [Sprint] {
        return completedSprints.filter { $0.goalId == goalId }
    }
    
    // MARK: - Data Persistence
    
    private func saveSprints() {
        let allSprints = activeSprints + completedSprints
        if let encoded = try? JSONEncoder().encode(allSprints) {
            userDefaults.set(encoded, forKey: sprintsKey)
        }
    }
    
    private func loadSprints() {
        guard let data = userDefaults.data(forKey: sprintsKey),
              let allSprints = try? JSONDecoder().decode([Sprint].self, from: data) else {
            return
        }
        
        activeSprints = allSprints.filter { !$0.isCompleted }
        completedSprints = allSprints.filter { $0.isCompleted }
    }
    
    // MARK: - Mock Data for Testing
    
    func createMockSprints() {
        let mockGoal = TwelveWeekGoal(
            title: "Learn SwiftUI",
            description: "Master iOS development with SwiftUI",
            category: .learning,
            aiContext: GoalAIContext()
        )
        
        let mockSuggestions = [
            SprintSuggestion(
                weekNumber: 1,
                title: "Foundation & Planning",
                description: "Establish clear objectives and create detailed action plans",
                suggestedMilestones: ["Complete goal breakdown", "Set up tracking systems", "Create timeline"],
                estimatedTasks: ["Research best practices", "Create project plan", "Set up progress tracking"],
                focusAreas: ["Planning", "Organization", "Goal Setting"]
            ),
            SprintSuggestion(
                weekNumber: 2,
                title: "Execution & Progress",
                description: "Focus on high-impact actions and measurable progress",
                suggestedMilestones: ["Complete 25% of major tasks", "Establish daily routines", "Track key metrics"],
                estimatedTasks: ["Execute core activities", "Monitor progress daily", "Adjust plans as needed"],
                focusAreas: ["Execution", "Consistency", "Measurement"]
            )
        ]
        
        _ = createSprints(for: mockGoal, suggestions: mockSuggestions)
    }
} 