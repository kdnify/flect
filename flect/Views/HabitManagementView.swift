import SwiftUI

struct HabitManagementView: View {
    @StateObject private var habitService = HabitService.shared
    @State private var selectedFilter: HabitFilter = .all
    @State private var showingAddHabit = false
    @State private var showingHabitDetail: Habit?
    @Environment(\.dismiss) private var dismiss
    
    private enum HabitFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case overdue = "Overdue"
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case archived = "Archived"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Filter tabs
                filterTabsSection
                
                // Content
                if habitService.habits.isEmpty {
                    emptyStateSection
                } else {
                    habitListSection
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
        .sheet(item: $showingHabitDetail) { habit in
            HabitDetailView(habit: habit)
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
                    Text("Habit Management")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                    
                    Text("Build better habits")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                Button("Add Habit") {
                    showingAddHabit = true
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
    
    // MARK: - Filter Tabs Section
    
    private var filterTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HabitFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: getHabitCount(for: filter)
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
    
    // MARK: - Empty State Section
    
    private var emptyStateSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.mediumGreyHex)
                
                Text("No Habits Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Text("Start building better habits by adding your first habit or letting AI suggest habits based on your patterns!")
                    .font(.body)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingAddHabit = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        
                        Text("Create Your First Habit")
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
                    habitService.suggestNewHabits()
                }) {
                    Text("Get AI Suggestions")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Habit List Section
    
    private var habitListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(getFilteredHabits()) { habit in
                    HabitCard(habit: habit) {
                        showingHabitDetail = habit
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFilteredHabits() -> [Habit] {
        switch selectedFilter {
        case .all:
            return habitService.getActiveHabits()
        case .today:
            return habitService.getHabitsForToday()
        case .overdue:
            return habitService.getOverdueHabits()
        case .morning:
            return habitService.getHabits(for: .morning)
        case .afternoon:
            return habitService.getHabits(for: .afternoon)
        case .evening:
            return habitService.getHabits(for: .evening)
        case .archived:
            return habitService.getArchivedHabits()
        }
    }
    
    private func getHabitCount(for filter: HabitFilter) -> Int {
        switch filter {
        case .all:
            return habitService.getActiveHabits().count
        case .today:
            return habitService.getHabitsForToday().count
        case .overdue:
            return habitService.getOverdueHabits().count
        case .morning:
            return habitService.getHabits(for: .morning).count
        case .afternoon:
            return habitService.getHabits(for: .afternoon).count
        case .evening:
            return habitService.getHabits(for: .evening).count
        case .archived:
            return habitService.getArchivedHabits().count
        }
    }
}

// MARK: - Filter Tab

struct FilterTab: View {
    let filter: HabitManagementView.HabitFilter
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

// MARK: - Habit Card

struct HabitCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category indicator
                Circle()
                    .fill(Color(habit.category.color))
                    .frame(width: 12, height: 12)
                
                // Habit content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(habit.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textMainHex)
                            .strikethrough(habit.isCompletedToday)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Source badge
                        if habit.source != .manual {
                            Image(systemName: habit.source.icon)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if !habit.description.isEmpty {
                        Text(habit.description)
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        // Frequency
                        HStack(spacing: 4) {
                            Image(systemName: habit.frequency.icon)
                                .font(.caption2)
                            Text(habit.frequency.displayName)
                                .font(.caption2)
                        }
                        .foregroundColor(.mediumGreyHex)
                        
                        Spacer()
                        
                        // Time of day
                        HStack(spacing: 4) {
                            Image(systemName: habit.timeOfDay.icon)
                                .font(.caption2)
                            Text(habit.timeOfDay.displayName)
                                .font(.caption2)
                        }
                        .foregroundColor(.mediumGreyHex)
                        
                        // Streak
                        if habit.currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                Text("\(habit.currentStreak)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
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
}

// MARK: - Preview

struct HabitManagementView_Previews: PreviewProvider {
    static var previews: some View {
        HabitManagementView()
    }
} 