import SwiftUI

struct AddHabitView: View {
    @StateObject private var habitService = HabitService.shared
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: TaskCategory = .personal
    @State private var selectedFrequency: HabitFrequency = .daily
    @State private var selectedTimeOfDay: HabitTimeOfDay = .morning
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
                    
                    Text("Add Habit")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveHabit()
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
                            Text("Habit Title")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            TextField("Enter habit title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            TextField("Enter habit description", text: $description, axis: .vertical)
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
                        
                        // Frequency
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Frequency")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            HStack(spacing: 12) {
                                ForEach(HabitFrequency.allCases, id: \.self) { frequency in
                                    FrequencyButton(
                                        frequency: frequency,
                                        isSelected: selectedFrequency == frequency
                                    ) {
                                        selectedFrequency = frequency
                                    }
                                }
                            }
                        }
                        
                        // Time of Day
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time of Day")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            
                            HStack(spacing: 12) {
                                ForEach(HabitTimeOfDay.allCases, id: \.self) { timeOfDay in
                                    TimeOfDayButton(
                                        timeOfDay: timeOfDay,
                                        isSelected: selectedTimeOfDay == timeOfDay
                                    ) {
                                        selectedTimeOfDay = timeOfDay
                                    }
                                }
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
    
    private func saveHabit() {
        let habit = Habit(
            title: title,
            description: description,
            category: selectedCategory,
            frequency: selectedFrequency,
            timeOfDay: selectedTimeOfDay,
            source: .manual
        )
        
        habitService.addHabit(habit)
        dismiss()
    }
}

// MARK: - Supporting Views

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

struct FrequencyButton: View {
    let frequency: HabitFrequency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: frequency.icon)
                    .font(.subheadline)
                
                Text(frequency.displayName)
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

struct TimeOfDayButton: View {
    let timeOfDay: HabitTimeOfDay
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: timeOfDay.icon)
                    .font(.subheadline)
                
                Text(timeOfDay.displayName)
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

// MARK: - Preview

struct AddHabitView_Previews: PreviewProvider {
    static var previews: some View {
        AddHabitView()
    }
} 