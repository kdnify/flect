import SwiftUI

struct JournalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: JournalEntry
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Reflection
                    reflectionSection
                    
                    // Progress Notes
                    if !entry.progressNotes.isEmpty {
                        progressNotesSection
                    }
                    
                    // Extracted Tasks
                    if !entry.extractedTasks.isEmpty {
                        extractedTasksSection
                    }
                    
                    // Original Brain Dump
                    originalBrainDumpSection
                }
                .padding()
            }
            .background(Color.background)
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.mediumGrey)
                
                Spacer()
                
                Text("Journal Entry")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMain)
                
                Spacer()
                
                Button("Edit") {
                    // TODO: Navigate to edit view
                }
                .foregroundColor(.accent)
            }
            .padding()
            .background(Color.cardBackground)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Date and mood
            CardView {
                HStack {
                    Text(entry.mood.rawValue)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.mood.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.textMain)
                        
                        Text(formatDate(entry.date))
                            .font(.subheadline)
                            .foregroundColor(.mediumGrey)
                    }
                    
                    Spacer()
                    
                    if !entry.extractedTasks.isEmpty {
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("\(entry.extractedTasks.count)", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.accent)
                            
                            Text("tasks")
                                .font(.caption)
                                .foregroundColor(.mediumGrey)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    private var reflectionSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "quote.bubble")
                        .foregroundColor(.accent)
                    
                    Text("Reflection")
                        .font(.headline)
                        .foregroundColor(.textMain)
                    
                    Spacer()
                }
                
                Text(entry.reflection)
                    .font(.body)
                    .foregroundColor(.textMain)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal)
    }
    
    private var progressNotesSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.accent)
                    
                    Text("Progress & Accountability")
                        .font(.headline)
                        .foregroundColor(.textMain)
                    
                    Spacer()
                }
                
                Text(entry.progressNotes)
                    .font(.body)
                    .foregroundColor(.textMain)
                    .multilineTextAlignment(.leading)
                    .italic()
            }
        }
        .padding(.horizontal)
    }
    
    private var extractedTasksSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                extractedTasksHeader
                extractedTasksList
            }
        }
        .padding(.horizontal)
    }
    
    private var extractedTasksHeader: some View {
        HStack {
            Image(systemName: "checklist")
                .foregroundColor(.accent)
            
            Text("Extracted Tasks")
                .font(.headline)
                .foregroundColor(.textMain)
            
            Spacer()
            
            Text("\(entry.extractedTasks.count)")
                .font(.caption)
                .foregroundColor(.mediumGrey)
        }
    }
    
    private var extractedTasksList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(entry.extractedTasks.enumerated()), id: \.element.id) { index, task in
                taskRow(task)
                
                if index < entry.extractedTasks.count - 1 {
                    Divider()
                }
            }
        }
    }
    
    private func taskRow(_ task: TaskItem) -> some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .accent : .mediumGrey)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundColor(task.isCompleted ? .mediumGrey : .textMain)
                    .strikethrough(task.isCompleted)
                
                HStack {
                    Circle()
                        .fill(priorityColor(task.priority))
                        .frame(width: 6, height: 6)
                    
                    Text(task.priority.displayName)
                        .font(.caption)
                        .foregroundColor(.mediumGrey)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var originalBrainDumpSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.mediumGrey)
                    
                    Text("Original Brain Dump")
                        .font(.headline)
                        .foregroundColor(.textMain)
                    
                    Spacer()
                }
                
                Text(entry.originalBrainDump)
                    .font(.body)
                    .foregroundColor(.mediumGrey)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .background(Color.background)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .mediumGrey
        case .medium: return .accent
        case .high: return .error
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    JournalDetailView(
        entry: JournalEntry(
            mood: .focused,
            reflection: "Today was productive and I managed to organize my thoughts effectively. The brain dump approach really helps me see the big picture and identify what's most important. I'm feeling more clarity about my priorities and next steps.",
            progressNotes: "Successfully identified key priorities and made good progress on planning. The act of writing everything down helped me realize I was overthinking some tasks that are actually quite manageable.",
            extractedTasks: [
                TaskItem(title: "Review quarterly goals and adjust timeline", priority: .high),
                TaskItem(title: "Call mom and catch up", priority: .medium),
                TaskItem(title: "Plan weekend activities", isCompleted: true, priority: .low)
            ],
            originalBrainDump: "Need to review quarterly goals and make sure I'm on track. Feeling a bit overwhelmed with the timeline but maybe it's not as bad as I think. Also should call mom, haven't talked to her in a while. Might be nice to plan something fun for the weekend too. Actually feeling pretty focused today and want to make progress on key projects."
        )
    )
} 