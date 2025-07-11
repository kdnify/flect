import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @StateObject private var habitService = HabitService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: habit.frequency.icon)
                                .font(.title)
                                .foregroundColor(.accentHex)
                            
                            Text(habit.frequency.displayName)
                                .font(.headline)
                                .foregroundColor(.mediumGreyHex)
                        }
                        
                        Text(habit.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textMainHex)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Description
                    if !habit.description.isEmpty {
                        Text(habit.description)
                            .font(.body)
                            .foregroundColor(.textMainHex)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Streak
                    VStack(spacing: 8) {
                        Text("Current Streak")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.mediumGreyHex)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                            
                            Text("\(habit.currentStreak)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.textMainHex)
                        }
                        
                        Text("Longest: \(habit.longestStreak)")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                    }
                    
                    // Completion rate
                    VStack(spacing: 8) {
                        Text("Completion Rate")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.mediumGreyHex)
                        
                        Text("\(Int(habit.completionRate * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.textMainHex)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textMainHex)
                        
                        DetailRow(
                            icon: habit.category.emoji,
                            title: "Category",
                            value: habit.category.displayName,
                            color: Color(habit.category.color)
                        )
                        
                        DetailRow(
                            icon: habit.timeOfDay.icon,
                            title: "Time of Day",
                            value: habit.timeOfDay.displayName,
                            color: .accentHex
                        )
                        
                        DetailRow(
                            icon: habit.source.icon,
                            title: "Source",
                            value: habit.source.displayName,
                            color: .blue
                        )
                        
                        if let goalId = habit.goalId,
                           let goal = goalService.getGoal(by: goalId) {
                            DetailRow(
                                icon: "target",
                                title: "Goal",
                                value: goal.title,
                                color: .purple
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.cardBackgroundHex)
                    .cornerRadius(16)
                    
                    // Completion history
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Completion History")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textMainHex)
                        
                        if habit.completionHistory.isEmpty {
                            Text("No completions yet")
                                .font(.subheadline)
                                .foregroundColor(.mediumGreyHex)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 24)
                        } else {
                            ForEach(habit.completionHistory.sorted { $0.date > $1.date }, id: \.date) { completion in
                                CompletionRow(completion: completion)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.cardBackgroundHex)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color.backgroundHex)
            .navigationTitle("Habit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if !habit.isCompletedToday {
                            Button(action: {
                                habitService.completeHabit(habit.id)
                                dismiss()
                            }) {
                                Label("Complete Today", systemImage: "checkmark.circle.fill")
                            }
                        }
                        
                        Button(action: {
                            habitService.archiveHabit(habit.id)
                            dismiss()
                        }) {
                            Label("Archive", systemImage: "archivebox")
                        }
                        
                        Button(role: .destructive, action: {
                            habitService.deleteHabit(habit.id)
                            dismiss()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            if icon.first?.isEmoji ?? false {
                Text(icon)
                    .font(.subheadline)
                    .frame(width: 20)
            } else {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                    .frame(width: 20)
            }
            
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

struct CompletionRow: View {
    let completion: HabitCompletion
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundColor(.green)
            
            Text(formatDate(completion.date))
                .font(.subheadline)
                .foregroundColor(.textMainHex)
            
            Spacer()
            
            if let note = completion.note {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct HabitDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HabitDetailView(habit: Habit(
            title: "Sample Habit",
            description: "This is a sample habit description.",
            category: .health,
            frequency: .daily,
            timeOfDay: .morning,
            source: .manual
        ))
    }
} 