import SwiftUI

struct SprintTrackingView: View {
    @StateObject private var sprintService = SprintService.shared
    @StateObject private var goalService = GoalService.shared
    @State private var selectedSprint: Sprint?
    @State private var showingSprintDetail = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if sprintService.activeSprints.isEmpty {
                    emptyStateSection
                } else {
                    sprintListSection
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSprintDetail) {
            if let sprint = selectedSprint {
                SprintDetailView(sprint: sprint)
            }
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
                    Text("Sprint Tracking")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text("Track your 4-week sprints")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                Button("Add Sprint") {
                    // TODO: Navigate to sprint planning
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
    
    // MARK: - Empty State Section
    
    private var emptyStateSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.mediumGreyHex)
                
                Text("No Active Sprints")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Text("Create your first sprint to start tracking progress on your goals. Sprints help break down big goals into manageable 4-week chunks.")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Navigate to sprint planning
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        
                        Text("Create Your First Sprint")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Button(action: {
                    sprintService.createMockSprints()
                }) {
                    Text("Add Sample Data")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Sprint List Section
    
    private var sprintListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sprintService.activeSprints) { sprint in
                    SprintCard(
                        sprint: sprint,
                        analytics: sprintService.getSprintAnalytics(for: sprint)
                    ) {
                        selectedSprint = sprint
                        showingSprintDetail = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
}

// MARK: - Sprint Card

struct SprintCard: View {
    let sprint: Sprint
    let analytics: SprintAnalytics
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week \(sprint.weekNumber)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentHex)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentHex.opacity(0.1))
                            .cornerRadius(6)
                        
                        Text(sprint.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textMainHex)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(sprint.progressPercentage)%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentHex)
                        
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                    }
                }
                
                // Progress bar
                ProgressView(value: sprint.currentProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentHex))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                // Stats
                HStack(spacing: 20) {
                    StatItem(
                        title: "Tasks",
                        value: "\(analytics.tasksCompleted)/\(analytics.totalTasks)",
                        color: .blue
                    )
                    
                    StatItem(
                        title: "Days Left",
                        value: "\(sprint.daysRemaining)",
                        color: sprint.daysRemaining < 7 ? .red : .green
                    )
                    
                    StatItem(
                        title: "Milestones",
                        value: "\(sprint.targetMilestones.filter { $0.isCompleted }.count)/\(sprint.targetMilestones.count)",
                        color: .purple
                    )
                }
                
                // Status indicator
                HStack {
                    Circle()
                        .fill(sprint.isActive ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(sprint.isActive ? "Active" : "Overdue")
                        .font(.caption)
                        .foregroundColor(sprint.isActive ? .green : .orange)
                    
                    Spacer()
                    
                    if sprint.isOverdue {
                        Text("\(abs(sprint.daysRemaining)) days overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(20)
            .background(Color.cardBackgroundHex)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.mediumGreyHex)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sprint Detail View

struct SprintDetailView: View {
    let sprint: Sprint
    @StateObject private var sprintService = SprintService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.mediumGreyHex)
                    
                    Spacer()
                    
                    Text("Sprint Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Edit") {
                        // TODO: Edit sprint
                    }
                    .foregroundColor(.accentHex)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Sprint overview
                        sprintOverviewSection
                        
                        // Tasks
                        tasksSection
                        
                        // Milestones
                        milestonesSection
                        
                        // Analytics
                        analyticsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
    }
    
    private var sprintOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sprint Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(sprint.description)
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Date")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                        Text(formatDate(sprint.startDate))
                            .font(.subheadline)
                            .foregroundColor(.textMainHex)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("End Date")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                        Text(formatDate(sprint.endDate))
                            .font(.subheadline)
                            .foregroundColor(.textMainHex)
                    }
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textMainHex)
                        
                        Spacer()
                        
                        Text("\(sprint.progressPercentage)%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.accentHex)
                    }
                    
                    ProgressView(value: sprint.currentProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentHex))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tasks")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            if sprint.tasks.isEmpty {
                Text("No tasks yet")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .padding(.vertical, 20)
            } else {
                ForEach(sprint.tasks) { task in
                    TaskRow(
                        task: task,
                        onToggle: {
                            sprintService.completeTask(sprintId: sprint.id, taskId: task.id)
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Milestones")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            if sprint.targetMilestones.isEmpty {
                Text("No milestones yet")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .padding(.vertical, 20)
            } else {
                ForEach(sprint.targetMilestones) { milestone in
                    MilestoneRow(
                        milestone: milestone,
                        onToggle: {
                            sprintService.completeMilestone(sprintId: sprint.id, milestoneId: milestone.id)
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            let analytics = sprintService.getSprintAnalytics(for: sprint)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(analytics.taskCompletionPercentage)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Task Completion")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                
                VStack(spacing: 4) {
                    Text(analytics.mostProductiveDay ?? "N/A")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Most Productive")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                
                VStack(spacing: 4) {
                    if let daysAhead = analytics.daysAheadOfSchedule {
                        Text("\(daysAhead)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Days Ahead")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                    } else if let daysBehind = analytics.daysBehindSchedule {
                        Text("\(daysBehind)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("Days Behind")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                    } else {
                        Text("On Track")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Schedule")
                            .font(.caption)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: SprintTask
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .green : .mediumGreyHex)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textMainHex)
                    .strikethrough(task.isCompleted)
                
                if let dueDate = task.dueDate {
                    Text("Due: \(formatDate(dueDate))")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
            }
            
            Spacer()
            
            Text(task.priority.emoji)
                .font(.subheadline)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: SprintMilestone
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: milestone.isCompleted ? "flag.fill" : "flag")
                    .font(.title3)
                    .foregroundColor(milestone.isCompleted ? .orange : .mediumGreyHex)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textMainHex)
                    .strikethrough(milestone.isCompleted)
                
                Text("Target: \(formatDate(milestone.targetDate))")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct SprintTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        SprintTrackingView()
    }
} 