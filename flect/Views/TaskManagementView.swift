import SwiftUI

struct TaskManagementView: View {
    @StateObject private var taskService = TaskService.shared
    @StateObject private var goalService = GoalService.shared
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedSort: TaskSort = .priority
    @State private var selectedGoal: UUID?
    @State private var selectedSprint: UUID?
    @State private var searchText = ""
    @State private var showingAddTask = false
    @State private var showingTaskDetail: AppTask?
    @State private var showingFilterSheet = false
    @State private var showingAnalytics = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            mainContent
                .background(Color.backgroundHex)
                .navigationBarHidden(true)
                .sheet(isPresented: $showingFilterSheet) {
                    TaskFilterSheet(
                        selectedGoal: $selectedGoal,
                        selectedSprint: $selectedSprint
                    )
                }
                .sheet(isPresented: $showingAnalytics) {
                    // TaskAnalyticsView() removed
                }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
        .sheet(item: $showingTaskDetail) { task in
            TaskDetailView(task: task)
        }
    }

    // Main content extracted from body
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerBar
            if selectedGoal != nil || selectedSprint != nil {
                activeFiltersSection
            }
            searchSection
            filterSortSection
            contentSection
        }
    }

    // Header bar extracted
    private var headerBar: some View {
        HStack {
            Button("Close") {
                dismiss()
            }
            .foregroundColor(.mediumGreyHex)
            .font(.subheadline)
            Spacer()
            VStack(spacing: 2) {
                Text("Task Management")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                Text("Manage your tasks and to-dos")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            Spacer()
            HStack(spacing: 16) {
                Button(action: { showingAnalytics = true }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundColor(.accentHex)
                }
                Button(action: { showingFilterSheet = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(.accentHex)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // Filter and sort section extracted
    private var filterSortSection: some View {
        VStack(spacing: 0) {
            filterTabsSection
            sortOptionsSection
        }
    }

    // Content section extracted
    private var contentSection: some View {
        if taskService.allTasks.isEmpty {
            AnyView(emptyStateSection)
        } else {
            AnyView(taskListSection)
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
                    Text("Task Management")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text("Manage your tasks and to-dos")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                Button("Add Task") {
                    showingAddTask = true
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
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                
                TextField("Search tasks...", text: $searchText)
                    .font(.subheadline)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.mediumGreyHex)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.cardBackgroundHex)
            .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.cardBackgroundHex)
    }
    
    // MARK: - Filter Tabs Section
    
    private var filterTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getTaskCount(for: filter)
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.cardBackgroundHex)
    }
    
    // MARK: - Sort Options Section
    
    private var sortOptionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskSort.allCases, id: \.self) { sort in
                    SortButton(
                        sort: sort,
                        isSelected: selectedSort == sort
                    ) {
                        selectedSort = sort
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.cardBackgroundHex)
    }
    
    // MARK: - Active Filters Section
    
    private var activeFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if let goalId = selectedGoal {
                    ActiveFilterPill(
                        icon: "target",
                        text: "Goal Filter",
                        color: .blue
                    ) {
                        selectedGoal = nil
                    }
                }
                
                if let sprintId = selectedSprint {
                    ActiveFilterPill(
                        icon: "timer",
                        text: "Sprint Filter",
                        color: .purple
                    ) {
                        selectedSprint = nil
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Color.cardBackgroundHex)
    }
    
    // MARK: - Empty State Section
    
    private var emptyStateSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checklist")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.mediumGreyHex)
                
                Text("No Tasks Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Text("Tasks will appear here when you chat with AI or create them manually. Start a conversation to see AI-suggested tasks!")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingAddTask = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        
                        Text("Create Your First Task")
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
                    taskService.createMockTasks()
                }) {
                    Text("Add Sample Tasks")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Task List Section
    
    private var taskListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(getFilteredTasks()) { task in
                    TaskCard(task: task) {
                        showingTaskDetail = task
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFilteredTasks() -> [AppTask] {
        var filtered = switch selectedFilter {
        case .all:
            taskService.allTasks
        case .active:
            taskService.getActiveTasks()
        case .completed:
            taskService.getCompletedTasks()
        case .extracted:
            goalService.getExtractedTasks()
        case .highPriority:
            taskService.getTasksByPriority(.high)
        case .today:
            taskService.getTasksForDate(Date())
        }
        
        // Apply goal filter - temporarily disabled since AppTask doesn't have goalId
        // if let goalId = selectedGoal {
        //     filtered = filtered.filter { $0.goalId == goalId }
        // }
        
        // Apply sprint filter - temporarily disabled since AppTask doesn't have sprintId
        // if let sprintId = selectedSprint {
        //     filtered = filtered.filter { $0.sprintId == sprintId }
        // }
        
        // Apply search
        let searched = searchText.isEmpty ? filtered : filtered.filter { task in
            task.title.localizedCaseInsensitiveContains(searchText) ||
            task.description.localizedCaseInsensitiveContains(searchText)
        }
        
        return sortTasks(searched)
    }
    
    private func getTaskCount(for filter: TaskFilter) -> Int {
        switch filter {
        case .all:
            return taskService.allTasks.count
        case .active:
            return taskService.getActiveTasks().count
        case .completed:
            return taskService.getCompletedTasks().count
        case .extracted:
            return goalService.getExtractedTasks().count
        case .highPriority:
            return taskService.getTasksByPriority(.high).count
        case .today:
            return taskService.getTasksForDate(Date()).count
        }
    }
    
    private func sortTasks(_ tasks: [AppTask]) -> [AppTask] {
        switch selectedSort {
        case .priority:
            return tasks.sorted { task1, task2 in
                let priorityOrder: [TaskPriority] = [.high, .medium, .low]
                let index1 = priorityOrder.firstIndex(of: task1.priority) ?? 0
                let index2 = priorityOrder.firstIndex(of: task2.priority) ?? 0
                return index1 < index2
            }
        case .dueDate:
            return tasks.sorted { task1, task2 in
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 < date2
            }
        case .category:
            return tasks.sorted { $0.category.rawValue < $1.category.rawValue }
        case .created:
            return tasks.sorted { $0.createdDate > $1.createdDate }
        }
    }
}

// MARK: - Task Filter

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    case extracted = "AI Extracted"
    case highPriority = "High Priority"
    case today = "Today"
}

// MARK: - Filter Tab

struct FilterTab: View {
    let filter: TaskFilter
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .accentHex : .mediumGreyHex)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .accentHex : .mediumGreyHex)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.accentHex.opacity(0.1) : Color.clear)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentHex.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sort Button

struct SortButton: View {
    let sort: TaskSort
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: sort.icon)
                    .font(.caption)
                
                Text(sort.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .accentHex : .mediumGreyHex)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentHex.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Task Sort

enum TaskSort: String, CaseIterable {
    case priority = "Priority"
    case dueDate = "Due Date"
    case category = "Category"
    case created = "Created"
    
    var icon: String {
        switch self {
        case .priority: return "flag.fill"
        case .dueDate: return "calendar"
        case .category: return "folder.fill"
        case .created: return "clock"
        }
    }
}

// MARK: - Task Card

struct TaskCard: View {
    let task: AppTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Priority indicator
                Circle()
                    .fill(Color(task.priority.color))
                    .frame(width: 12, height: 12)
                
                // Task content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textMainHex)
                            .strikethrough(task.isCompleted)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Category badge
                        Text(task.category.emoji)
                            .font(.caption)
                    }
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        // Due date
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(formatDate(dueDate))
                                    .font(.caption2)
                            }
                            .foregroundColor(isOverdue(dueDate) ? .red : .mediumGreyHex)
                        }
                        
                        Spacer()
                        
                        // Source indicator
                        if task.source == .aiConversation {
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                    .font(.caption2)
                                Text("AI")
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        // Completion status
                        if task.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.cardBackgroundHex)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !task.isCompleted
    }
}

// MARK: - Add Task View

struct AddTaskView: View {
    @StateObject private var taskService = TaskService.shared
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: TaskCategory = .personal
    @State private var selectedPriority: TaskPriority = .medium
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.mediumGreyHex)
                    
                    Spacer()
                    
                    Text("Add Task")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveTask()
                    }
                    .foregroundColor(.accentHex)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                Divider()
                
                // Form
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Title")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            TextField("Enter task title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            TextField("Enter task description", text: $description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(TaskCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Priority")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases, id: \.self) { priority in
                                    PriorityButton(
                                        priority: priority,
                                        isSelected: selectedPriority == priority
                                    ) {
                                        selectedPriority = priority
                                    }
                                }
                            }
                        }
                        
                        // Due Date
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Due Date")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textMainHex)
                                
                                Spacer()
                                
                                Toggle("", isOn: $hasDueDate)
                                    .labelsHidden()
                            }
                            
                            if hasDueDate {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
    }
    
    private func saveTask() {
        let task = AppTask(
            title: title,
            description: description,
            priority: selectedPriority,
            category: selectedCategory,
            dueDate: hasDueDate ? dueDate : nil,
            source: .manual
        )
        
        taskService.addTask(task)
        dismiss()
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: TaskCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(category.emoji)
                    .font(.subheadline)
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .textMainHex)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentHex : Color.cardBackgroundHex)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentHex : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Priority Button

struct PriorityButton: View {
    let priority: TaskPriority
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(priority.emoji)
                    .font(.subheadline)
                
                Text(priority.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .textMainHex)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(priority.color) : Color.cardBackgroundHex)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(priority.color) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    let task: AppTask
    @StateObject private var taskService = TaskService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditTask = false
    
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
                    
                    Text("Task Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Edit") {
                        showingEditTask = true
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
                        // Task info
                        taskInfoSection
                        
                        // Actions
                        actionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .sheet(isPresented: $showingEditTask) {
                EditTaskView(task: task)
            }
        }
    }
    
    private var taskInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textMainHex)
                        .strikethrough(task.isCompleted)
                    
                    Text(task.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            // Description
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
            }
            
            // Details
            VStack(spacing: 12) {
                DetailRow(
                    icon: "flag.fill",
                    title: "Priority",
                    value: task.priority.displayName,
                    color: Color(task.priority.color)
                )
                
                if let dueDate = task.dueDate {
                    DetailRow(
                        icon: "calendar",
                        title: "Due Date",
                        value: formatDate(dueDate),
                        color: isOverdue(dueDate) ? .red : .mediumGreyHex
                    )
                }
                
                DetailRow(
                    icon: "clock",
                    title: "Created",
                    value: formatDate(task.createdDate),
                    color: .mediumGreyHex
                )
                
                DetailRow(
                    icon: "brain.head.profile",
                    title: "Source",
                    value: task.source.displayName,
                    color: task.source == .aiConversation ? .blue : .mediumGreyHex
                )
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if !task.isCompleted {
                Button(action: {
                    taskService.completeTask(task.id)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                        
                        Text("Mark as Complete")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            
            Button(action: {
                taskService.deleteTask(task.id)
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                    
                    Text("Delete Task")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(12)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !task.isCompleted
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.mediumGreyHex)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textMainHex)
        }
    }
}

// MARK: - Edit Task View

struct EditTaskView: View {
    let task: AppTask
    @StateObject private var taskService = TaskService.shared
    @State private var title: String
    @State private var description: String
    @State private var selectedCategory: TaskCategory
    @State private var selectedPriority: TaskPriority
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(task: AppTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _selectedCategory = State(initialValue: task.category)
        _selectedPriority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.mediumGreyHex)
                    
                    Spacer()
                    
                    Text("Edit Task")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveTask()
                    }
                    .foregroundColor(.accentHex)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                Divider()
                
                // Form
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Title")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            TextField("Enter task title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            TextField("Enter task description", text: $description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(TaskCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Priority")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases, id: \.self) { priority in
                                    PriorityButton(
                                        priority: priority,
                                        isSelected: selectedPriority == priority
                                    ) {
                                        selectedPriority = priority
                                    }
                                }
                            }
                        }
                        
                        // Due Date
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Due Date")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textMainHex)
                                
                                Spacer()
                                
                                Toggle("", isOn: $hasDueDate)
                                    .labelsHidden()
                            }
                            
                            if hasDueDate {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
    }
    
    private func saveTask() {
        // For now, just add the new task since AppTask doesn't support updating
        // In a real implementation, you'd want to modify the AppTask model to support this
        let newTask = AppTask(
            title: title,
            description: description,
            priority: selectedPriority,
            category: selectedCategory,
            dueDate: hasDueDate ? dueDate : nil,
            source: task.source,
            notes: task.notes
        )
        
        taskService.addTask(newTask)
        dismiss()
    }
}

// MARK: - Active Filter Pill

struct ActiveFilterPill: View {
    let icon: String
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Task Filter Sheet

struct TaskFilterSheet: View {
    @Binding var selectedGoal: UUID?
    @Binding var selectedSprint: UUID?
    @StateObject private var goalService = GoalService.shared
    @StateObject private var sprintService = SprintService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                goalsSection
                sprintsSection
            }
            .navigationTitle("Filter Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        selectedGoal = nil
                        selectedSprint = nil
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }

    private var goalsSection: some View {
        Section("Filter by Goal") {
            ForEach(goalService.activeGoals) { goal in
                Button(action: {
                    selectedGoal = goal.id
                    dismiss()
                }) {
                    HStack {
                        Text(goal.title)
                            .foregroundColor(.textMainHex)
                        Spacer()
                        if selectedGoal == goal.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentHex)
                        }
                    }
                }
            }
        }
    }

    private var sprintsSection: some View {
        Section("Filter by Sprint") {
            ForEach(sprintService.activeSprints) { sprint in
                Button(action: {
                    selectedSprint = sprint.id
                    dismiss()
                }) {
                    HStack {
                        Text(sprint.title)
                            .foregroundColor(.textMainHex)
                        Spacer()
                        if selectedSprint == sprint.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentHex)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct TaskManagementView_Previews: PreviewProvider {
    static var previews: some View {
        TaskManagementView()
    }
} 

// Analytics section temporarily removed 