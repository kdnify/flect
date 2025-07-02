import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    let onTap: () -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(entry.mood.rawValue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.mood.displayName)
                            .font(.headline)
                            .foregroundColor(.textMain)
                        
                        Text(formatDate(entry.date))
                            .font(.caption)
                            .foregroundColor(.mediumGrey)
                    }
                    
                    Spacer()
                    
                    if !entry.extractedTasks.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accent)
                            Text("\(entry.extractedTasks.count)")
                                .font(.caption)
                                .foregroundColor(.mediumGrey)
                        }
                    }
                }
                
                // Reflection preview
                Text(entry.reflection)
                    .font(.body)
                    .foregroundColor(.textMain)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Progress notes preview
                if !entry.progressNotes.isEmpty {
                    Text(entry.progressNotes)
                        .font(.caption)
                        .foregroundColor(.mediumGrey)
                        .lineLimit(2)
                        .italic()
                }
            }
        }
        .onTapGesture(perform: onTap)
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
}

struct TaskCard: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        CardView {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .accent : .mediumGrey)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body)
                        .foregroundColor(task.isCompleted ? .mediumGrey : .textMain)
                        .strikethrough(task.isCompleted)
                    
                    HStack {
                        // Priority indicator
                        Circle()
                            .fill(priorityColor(task.priority))
                            .frame(width: 8, height: 8)
                        
                        Text(task.priority.displayName)
                            .font(.caption)
                            .foregroundColor(.mediumGrey)
                        
                        if let dueDate = task.dueDate {
                            Spacer()
                            Text(formatDueDate(dueDate))
                                .font(.caption)
                                .foregroundColor(isOverdue(dueDate) ? .error : .mediumGrey)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onTapGesture(perform: onTap)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .mediumGrey
        case .medium: return .accent
        case .high: return .error
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !Calendar.current.isDateInToday(date)
    }
}

#Preview {
    VStack(spacing: 16) {
        JournalEntryCard(
            entry: JournalEntry(
                mood: .focused,
                reflection: "Today was productive. I managed to organize my thoughts and tackle some important tasks. The brain dump approach really helps me see the big picture.",
                progressNotes: "Identified key priorities and made good progress on planning.",
                extractedTasks: [
                    TaskItem(title: "Review quarterly goals", priority: .high),
                    TaskItem(title: "Call mom", priority: .medium)
                ],
                originalBrainDump: "Sample brain dump"
            )
        ) {
            print("Journal entry tapped")
        }
        
        TaskCard(
            task: TaskItem(title: "Review quarterly goals", priority: .high)
        ) {
            print("Task toggled")
        } onTap: {
            print("Task tapped")
        }
    }
    .padding()
    .background(Color.background)
} 