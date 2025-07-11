import SwiftUI

struct PersonalDashboard: View {
    @StateObject private var checkInService = CheckInService.shared
    @State private var showingQuickCheckIn = false
    @State private var showingHistory = false
    @State private var showingExportSheet = false
    @State private var forceRefresh = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with greeting and streak
                    headerSection
                    
                    // Primary action - Check-in or insights
                    primaryActionSection
                    
                    // Insights section - the heart of the app
                    insightsSection
                    
                    // Progress tracking
                    progressSection
                    
                    // Quick actions
                    quickActionsSection
                }
                .padding()
                .refreshable {
                    forceRefresh.toggle()
                }
            }
            .background(Color.backgroundHex)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingQuickCheckIn) {
            QuickCheckInView()
        }
        .sheet(isPresented: $showingHistory) {
            // HistoryView() // TODO: Add back when properly added to project
            Text("History View Coming Soon!")
                .font(.title)
                .foregroundColor(.textMainHex)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundHex)
        }
        .confirmationDialog("Export Options", isPresented: $showingExportSheet, titleVisibility: .visible) {
            Button("Export as Text") {
                exportAsText()
            }
            Button("Share Insights") {
                shareInsights()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how you'd like to export your reflection data")
        }
        .id(forceRefresh) // Force refresh mechanism
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    Text("Ready to reflect?")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                
                Spacer()
                
                // Streak indicator
                streakIndicator
            }
            
            // Progress bar showing weekly check-ins
            weeklyProgressBar
        }
    }
    
    private var streakIndicator: some View {
        VStack(spacing: 2) {
            Text("\(checkInService.calculateUserEngagement().currentStreak)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.accentHex)
            
            Text("day streak")
                .font(.caption2)
                .foregroundColor(.mediumGreyHex)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.cardBackgroundHex)
        .cornerRadius(12)
        .onTapGesture {
            HapticManager.shared.lightImpact()
        }
    }
    
    private var weeklyProgressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This week")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
                
                Spacer()
                
                Text("\(weeklyCheckIns)/7")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentHex)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.mediumGreyHex.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.accentHex)
                        .frame(width: geometry.size.width * (Double(weeklyCheckIns) / 7.0), height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: weeklyCheckIns)
                }
            }
            .frame(height: 4)
        }
    }
    
    // MARK: - Primary Action Section
    
    private var primaryActionSection: some View {
        Group {
            if checkInService.hasCheckedInToday() {
                // Show insights when checked in
                todaysCompletionCard
            } else {
                // Show check-in prompt
                checkInPromptCard
            }
        }
    }
    
    private var todaysCompletionCard: some View {
        CardView {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentHex)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's reflection complete")
                            .font(.headline)
                            .foregroundColor(.textMainHex)
                        
                        Text("Great consistency! See your insights below.")
                            .font(.subheadline)
                            .foregroundColor(.mediumGreyHex)
                    }
                    
                    Spacer()
                    
                    Button("🔄") {
                        HapticManager.shared.mediumImpact()
                        // resetData() // Removed debug call
                    }
                    .foregroundColor(.mediumGreyHex)
                    .font(.title2)
                }
                
                // Today's AI response if available
                if let todaysCheckIn = checkInService.getTodaysCheckIn(),
                   let aiResponse = todaysCheckIn.aiResponse {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Follow-up reflection:")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                        
                        Text(aiResponse)
                            .font(.subheadline)
                            .foregroundColor(.textMainHex)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.backgroundHex)
                            .cornerRadius(8)
                    }
                }
                // Edit Check-In button
                Button(action: { showingQuickCheckIn = true }) {
                    Text("Edit Check-In")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.12), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Polished Today Mood Swatch
                if let todaysCheckIn = checkInService.getTodaysCheckIn() {
                    HStack(alignment: .center, spacing: 16) {
                        Text("Today's Mood")
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                        ZStack {
                            Circle()
                                .fill(Color.moodColor(for: todaysCheckIn.moodEmoji))
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.moodColor(for: todaysCheckIn.moodEmoji).opacity(0.25), radius: 12, x: 0, y: 4)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                                )
                                .accessibilityLabel("Today's mood: \(todaysCheckIn.moodEmoji)")
                        }
                        .onTapGesture {
                            // Optionally show a tooltip or haptic
                            HapticManager.shared.lightImpact()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var checkInPromptCard: some View {
        CardView {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentHex)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily reflection")
                            .font(.headline)
                            .foregroundColor(.textMainHex)
                        
                        Text("What made you happy? What can you improve?")
                            .font(.subheadline)
                            .foregroundColor(.mediumGreyHex)
                    }
                    
                    Spacer()
                }
                
                Button(action: {
                    HapticManager.shared.mediumImpact()
                    showingQuickCheckIn = true
                }) {
                    Text("Check In")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.12), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.accentHex)
                
                Text("Your Patterns")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                if !checkInService.getActiveInsights().isEmpty {
                    Button("See All") {
                        // TODO: Navigate to full insights view
                        HapticManager.shared.lightImpact()
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentHex)
                }
            }
            
            let insights = checkInService.getActiveInsights()
            
            if insights.isEmpty {
                emptyInsightsCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(insights.prefix(3)) { insight in
                        InsightCard(insight: insight)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    
                    if insights.count > 3 {
                        Button("View \(insights.count - 3) more insights") {
                            // TODO: Navigate to full insights view
                            HapticManager.shared.lightImpact()
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentHex)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.cardBackgroundHex)
                        .cornerRadius(12)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: insights.count)
            }
        }
    }
    
    private var emptyInsightsCard: some View {
        CardView {
            VStack(spacing: 12) {
                Image(systemName: "lightbulb")
                    .font(.title)
                    .foregroundColor(.mediumGreyHex)
                
                Text("Discovering your patterns")
                    .font(.headline)
                    .foregroundColor(.textMainHex)
                
                Text("Keep checking in daily and we'll start identifying what makes you happy and areas for growth.")
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                
                Button("Add sample data") {
                    HapticManager.shared.mediumImpact()
                    // resetData() // Removed debug call
                }
                .font(.subheadline)
                .foregroundColor(.accentHex)
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.accentHex)
                
                Text("Progress")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textMainHex)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Total check-ins
                progressMetric(
                    title: "Total Reflections",
                    value: "\(checkInService.checkIns.count)",
                    subtitle: "all time",
                    icon: "calendar"
                )
                
                // Best streak
                progressMetric(
                    title: "Best Streak",
                    value: "\(checkInService.calculateUserEngagement().longestStreak)",
                    subtitle: "days",
                    icon: "flame"
                )
            }
        }
    }
    
    private func progressMetric(title: String, value: String, subtitle: String, icon: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.accentHex)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textMainHex)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.textMainHex)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
            }
        }
        .onTapGesture {
            HapticManager.shared.lightImpact()
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.textMainHex)
            
            HStack(spacing: 12) {
                actionButton(
                    title: "History",
                    icon: "clock.arrow.circlepath",
                    action: {
                        HapticManager.shared.mediumImpact()
                        showingHistory = true
                    }
                )
                
                actionButton(
                    title: "Export",
                    icon: "square.and.arrow.up",
                    action: {
                        HapticManager.shared.mediumImpact()
                        showingExportSheet = true
                    }
                )
                
                actionButton(
                    title: "Settings",
                    icon: "gearshape",
                    action: {
                        HapticManager.shared.lightImpact()
                        // TODO: Navigate to settings
                    }
                )
            }
        }
    }
    
    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentHex)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textMainHex)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackgroundHex)
            .cornerRadius(12)
        }
        .scaleEffect(1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                // Tap animation handled by haptic feedback
            }
        }
    }
    
    // MARK: - Helper Properties & Methods
    
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
    
    private var weeklyCheckIns: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return checkInService.checkIns.filter { checkIn in
            checkIn.date >= startOfWeek && checkIn.date <= Date()
        }.count
    }
    
    private func resetData() {
        checkInService.resetToSampleData()
        forceRefresh.toggle()
    }
    
    // MARK: - Export Functions
    
    private func exportAsText() {
        let exportText = generateExportText()
        
        let activityVC = UIActivityViewController(
            activityItems: [exportText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        HapticManager.shared.success()
    }
    
    private func shareInsights() {
        let insights = checkInService.getActiveInsights()
        let insightsText = insights.map { insight in
            "💡 \(insight.description)"
        }.joined(separator: "\n\n")
        
        let shareText = """
        My flect Insights:
        
        \(insightsText)
        
        Generated from my daily reflections with flect
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        HapticManager.shared.success()
    }
    
    private func generateExportText() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let checkInsText = checkInService.checkIns.map { checkIn in
            """
            \(formatter.string(from: checkIn.date)) \(checkIn.moodEmoji)
            Happy: \(checkIn.happyThing)
            Improve: \(checkIn.improveThing)
            \(checkIn.aiResponse ?? "No AI response")
            """
        }.joined(separator: "\n\n---\n\n")
        
        return """
        flect Reflection Export
        Generated: \(formatter.string(from: Date()))
        
        REFLECTIONS:
        \(checkInsText)
        
        INSIGHTS:
        \(checkInService.getActiveInsights().map { "• \($0.description)" }.joined(separator: "\n"))
        """
    }

    // Replace the weekly calendar section with polished color mood dots
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
    }

    private var weeklyMoodDots: some View {
        HStack(spacing: 12) {
            ForEach(weekDates, id: \.self) { date in
                let checkIn = checkInService.checkIns.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
                ZStack {
                    Circle()
                        .fill(Color.moodColor(for: checkIn?.moodEmoji ?? ""))
                        .frame(width: 28, height: 28)
                        .shadow(color: Color.moodColor(for: checkIn?.moodEmoji ?? "").opacity(0.15), radius: 6, x: 0, y: 2)
                        .overlay(
                            Circle().stroke(Color.borderColorHex, lineWidth: 1)
                        )
                        .accessibilityLabel("Mood: \(checkIn?.moodEmoji ?? "None")")
                    if isToday {
                        Circle()
                            .stroke(Color.accentHex, lineWidth: 3)
                            .frame(width: 36, height: 36)
                            .opacity(0.7)
                            .scaleEffect(1.1)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isToday)
                    }
                }
            }
        }
    }
}

#Preview {
    PersonalDashboard()
} 