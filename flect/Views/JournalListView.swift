import SwiftUI

struct JournalListView: View {
    @Environment(\.dismiss) private var dismiss
    let entries: [JournalEntry]
    @State private var searchText = ""
    @State private var selectedMoodFilter: Mood?
    @State private var selectedEntry: JournalEntry?
    
    var filteredEntries: [JournalEntry] {
        var filtered = entries
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { entry in
                entry.reflection.localizedCaseInsensitiveContains(searchText) ||
                entry.progressNotes.localizedCaseInsensitiveContains(searchText) ||
                entry.originalBrainDump.localizedCaseInsensitiveContains(searchText) ||
                entry.extractedTasks.contains { task in
                    task.title.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Apply mood filter
        if let moodFilter = selectedMoodFilter {
            filtered = filtered.filter { $0.mood == moodFilter }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search and Filters
                searchAndFiltersSection
                
                // Entries List
                entriesListSection
            }
            .background(Color.background)
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedEntry) { entry in
            JournalDetailView(entry: entry)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button("Done") {
                dismiss()
            }
            .foregroundColor(.mediumGrey)
            
            Spacer()
            
            Text("Journal Entries")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMain)
            
            Spacer()
            
            Text("\(filteredEntries.count)")
                .font(.caption)
                .foregroundColor(.mediumGrey)
        }
        .padding()
        .background(Color.cardBackground)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var searchAndFiltersSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.mediumGrey)
                
                TextField("Search entries...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.accent)
                }
            }
            .padding(12)
            .background(Color.cardBackground)
            .cornerRadius(8)
            
            // Mood filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button("All") {
                        selectedMoodFilter = nil
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedMoodFilter == nil ? Color.accent : Color.cardBackground)
                    .foregroundColor(selectedMoodFilter == nil ? .white : .textMain)
                    .cornerRadius(16)
                    
                    ForEach(Mood.allCases, id: \.self) { mood in
                        Button(mood.rawValue + " " + mood.displayName) {
                            selectedMoodFilter = selectedMoodFilter == mood ? nil : mood
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedMoodFilter == mood ? Color.accent : Color.cardBackground)
                        .foregroundColor(selectedMoodFilter == mood ? .white : .textMain)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var entriesListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredEntries) { entry in
                        JournalEntryCard(entry: entry) {
                            selectedEntry = entry
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        CardView {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.title)
                    .foregroundColor(.mediumGrey)
                
                VStack(spacing: 8) {
                    Text("No entries found")
                        .font(.headline)
                        .foregroundColor(.textMain)
                    
                    Text("Try adjusting your search or filters")
                        .font(.body)
                        .foregroundColor(.mediumGrey)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    JournalListView(entries: [
        JournalEntry(
            mood: .focused,
            reflection: "Today was productive and I managed to organize my thoughts effectively.",
            progressNotes: "Successfully identified key priorities and made good progress on planning.",
            extractedTasks: [
                TaskItem(title: "Review quarterly goals", priority: .high),
                TaskItem(title: "Call mom", priority: .medium)
            ],
            originalBrainDump: "Need to review quarterly goals and make sure I'm on track. Also should call mom, haven't talked to her in a while."
        )
    ])
} 