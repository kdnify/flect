import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var showingBrainDump = false
    @State private var selectedEntry: JournalEntry?
    @State private var showingJournalList = false
    @State private var showingProfile = false
    @State private var forceRefresh = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Today's Summary
                    todaysSummarySection
                    
                    // Recent Entries
                    recentEntriesSection
                    
                    // Pending Tasks
                    pendingTasksSection
                }
                .padding(.horizontal)
            }
            .background(Color.background)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingBrainDump) {
            BrainDumpView(viewModel: viewModel)
        }
        .onChange(of: showingBrainDump) { newValue in
            if newValue == false {
                viewModel.loadData()
                forceRefresh.toggle()
            }
        }
        .sheet(item: $selectedEntry) { entry in
            JournalDetailView(entry: entry)
        }
        .sheet(isPresented: $showingJournalList) {
            JournalListView(entries: viewModel.journalEntries)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("flect.")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(greetingText)
                        .font(.subheadline)
                        .foregroundColor(.mediumGrey)
                }
                
                Spacer()
                
                // Profile/Settings button
                Button(action: {
                    showingProfile = true
                }) {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.top)
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            PrimaryButton(title: "Brain Dump") {
                showingBrainDump = true
            }
            
            SecondaryButton(title: "Review") {
                showingJournalList = true
            }
        }
    }
    
    private var todaysSummarySection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today")
                        .font(.headline)
                        .foregroundColor(.textMain)
                    
                    Spacer()
                    
                    Text(formatDate(Date()))
                        .font(.caption)
                        .foregroundColor(.mediumGrey)
                }
                
                if let todaysEntry = viewModel.todaysEntry {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(todaysEntry.moodEmoji)
                            Text(todaysEntry.moodDisplayName)
                                .font(.subheadline)
                                .foregroundColor(.textMain)
                            Spacer()
                        }
                        
                        Text(todaysEntry.reflection)
                            .font(.body)
                            .foregroundColor(.textMain)
                            .lineLimit(2)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No journal entry yet today")
                            .font(.body)
                            .foregroundColor(.mediumGrey)
                        
                        Text("Tap 'Brain Dump' to get started")
                            .font(.caption)
                            .foregroundColor(.mediumGrey)
                    }
                }
                
                // Task summary
                let pendingCount = viewModel.pendingTasks.count
                let completedCount = viewModel.completedTasks.count
                
                if pendingCount > 0 || completedCount > 0 {
                    HStack {
                        if pendingCount > 0 {
                            Label("\(pendingCount) pending", systemImage: "circle")
                                .font(.caption)
                                .foregroundColor(.mediumGrey)
                        }
                        
                        if completedCount > 0 {
                            Label("\(completedCount) completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.accent)
                        }
                    }
                }
            }
        }
    }
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Entries")
                    .font(.headline)
                    .foregroundColor(.textMain)
                
                Spacer()
                
                Button("See All") {
                    showingJournalList = true
                }
                .font(.caption)
                .foregroundColor(.accent)
            }
            
            if viewModel.recentEntries.isEmpty {
                CardView {
                    VStack(spacing: 8) {
                        Image(systemName: "book.closed")
                            .font(.title)
                            .foregroundColor(.mediumGrey)
                        
                        Text("No journal entries yet")
                            .font(.body)
                            .foregroundColor(.mediumGrey)
                        
                        Text("Start with a brain dump to create your first entry")
                            .font(.caption)
                            .foregroundColor(.mediumGrey)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.recentEntries) { entry in
                        JournalEntryCard(entry: entry) {
                            selectedEntry = entry
                        }
                    }
                }
            }
        }
    }
    
    private var pendingTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pending Tasks")
                    .font(.headline)
                    .foregroundColor(.textMain)
                
                Spacer()
                
                if !viewModel.pendingTasks.isEmpty {
                    Text("\(viewModel.pendingTasks.count)")
                        .font(.caption)
                        .foregroundColor(.mediumGrey)
                }
            }
            
            if viewModel.pendingTasks.isEmpty {
                CardView {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.title)
                            .foregroundColor(.accent)
                        
                        Text("All caught up!")
                            .font(.body)
                            .foregroundColor(.textMain)
                        
                        Text("No pending tasks right now")
                            .font(.caption)
                            .foregroundColor(.mediumGrey)
                    }
                    .padding()
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.pendingTasks.prefix(3))) { task in
                        TaskCard(task: task) {
                            _Concurrency.Task {
                                await viewModel.toggleTaskCompletion(task)
                            }
                        } onTap: {
                            // Navigate to task detail
                        }
                    }
                    
                    if viewModel.pendingTasks.count > 3 {
                        Button("View \(viewModel.pendingTasks.count - 3) more tasks") {
                            // Navigate to full task list
                        }
                        .font(.caption)
                        .foregroundColor(.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
} 