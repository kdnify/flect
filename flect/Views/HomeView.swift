import SwiftUI

struct HomeView: View {
    @StateObject private var checkInService = CheckInService.shared
    @StateObject private var goalService = GoalService.shared
    @EnvironmentObject var userPreferences: UserPreferencesService
    @State private var showingCheckIn = false
    @State private var showingHistory = false
    @State private var showingMorningInsights = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header with proper safe area
                    headerSection
                        .padding(.top, geometry.safeAreaInsets.top)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                        .background(Color.backgroundHex)
                    
                    // Main content
                    ScrollView {
                        VStack(spacing: 32) {
                            // Morning insights banner (if available)
                            if goalService.shouldShowNextDayAdvice() {
                                morningInsightsBanner
                            }
                            
                            // Today's mood section
                            todaysMoodSection
                            
                            // Yesterday Reflection Section
                            yesterdayReflectionSection
                            
                            // Weekly overview
                            weeklyOverviewSection
                            
                            // Tomorrow Preparation Section
                            tomorrowPreparationSection
                            
                            // Quick stats
                            quickStatsSection
                            
                            // Progress insights
                            progressInsightsSection
                            
                            // 12-Week Goal Progress
                            goalProgressSection
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                }
                .background(Color.backgroundHex)
                .ignoresSafeArea(.all, edges: .top)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCheckIn) {
            DaylioCheckInView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showingMorningInsights) {
            MorningInsightsView()
        }
        .onAppear {
            checkInService.loadTodaysCheckIn()
            // goalService loads data automatically when initialized
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("checkInCompleted"))) { _ in
            checkInService.loadTodaysCheckIn()
            showingCheckIn = false
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("flect")
                        .font(.system(size: 36, weight: .ultraLight, design: .default))
                        .foregroundColor(.textMainHex)
                        .tracking(1.5)
                    
                    Text(userPreferences.getPersonalizedWelcomeMessage())
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.mediumGreyHex)
                        .tracking(0.3)
                }
                
                Spacer()
                
                // Enhanced insights button
                Button(action: { showingHistory = true }) {
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Insights")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textMainHex)
                            
                            if checkInService.checkIns.count > 0 {
                                Text("\(checkInService.checkIns.count) entries")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.mediumGreyHex)
                            }
                        }
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.1), .purple.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                            )
                    }
                }
            }
            
            // Streak indicator (minimal)
            if checkInService.calculateUserEngagement().currentStreak > 0 {
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 20, height: 4)
                    
                    Text("\(checkInService.calculateUserEngagement().currentStreak) day streak")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Morning Insights Banner
    
    private var morningInsightsBanner: some View {
        VStack(spacing: 0) {
            Button(action: {
                showingMorningInsights = true
                HapticManager.shared.mediumImpact()
            }) {
                HStack(spacing: 16) {
                    // Morning icon
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [.orange.opacity(0.3), .yellow.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "sunrise.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                        )
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Morning Insights Available")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textMainHex)
                        
                        Text("Your AI coach has advice based on yesterday")
                            .font(.system(size: 14))
                            .foregroundColor(.mediumGreyHex)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentHex)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.05),
                            Color.yellow.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .yellow.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .shadow(color: .orange.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Today Section
    
    private var todaysMoodSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Today")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.textMainHex)
            if let todaysCheckIn = todaysCheckIn {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today's Mood")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.mediumGreyHex)
                                .textCase(.uppercase)
                            // Show color swatch only, no text
                            Circle()
                                .fill(Color.moodColor(for: todaysCheckIn.moodEmoji))
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.moodColor(for: todaysCheckIn.moodEmoji).opacity(0.25), radius: 8, x: 0, y: 4)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                                .accessibilityLabel("Today's mood color")
                        }
                        Spacer()
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.moodColor(for: todaysCheckIn.moodEmoji))
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.moodColor(for: todaysCheckIn.moodEmoji).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    if !todaysCheckIn.happyThing.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Highlight")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.mediumGreyHex)
                                .textCase(.uppercase)
                            Text(todaysCheckIn.happyThing)
                                .font(.body)
                                .foregroundColor(.textMainHex)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    Button(action: { showingCheckIn = true }) {
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
                }
                .padding(24)
                .background(Color.cardBackgroundHex)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            } else {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How are you feeling?")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.textMainHex)
                            Text("Tap below to start your daily check-in")
                                .font(.subheadline)
                                .foregroundColor(.mediumGreyHex)
                        }
                        Spacer()
                    }
                    Button(action: { showingCheckIn = true }) {
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
                .padding(24)
                .background(Color.cardBackgroundHex)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Yesterday Reflection Section
    
    private var yesterdayReflectionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let yesterdayCheckIn = getYesterdayCheckIn() {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Yesterday")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.textMainHex)
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color.moodColor(for: yesterdayCheckIn.moodEmoji))
                            .frame(width: 20, height: 20)
                            .shadow(color: Color.moodColor(for: yesterdayCheckIn.moodEmoji).opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if !yesterdayCheckIn.happyThing.isEmpty {
                            Text("You highlighted: \"\(yesterdayCheckIn.happyThing)\"")
                                .font(.body)
                                .foregroundColor(.textMainHex)
                                .italic()
                        }
                        
                        Text(generateYesterdayReflectionPrompt(for: yesterdayCheckIn))
                            .font(.subheadline)
                            .foregroundColor(.mediumGreyHex)
                        
                        Button(action: { showingCheckIn = true }) {
                            Text("Reflect on yesterday")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.accentHex)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.accentHex.opacity(0.1))
                                .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(20)
                    .background(Color.cardBackgroundHex)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - Weekly Overview Section
    
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("This Week")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Button("View All") {
                    showingHistory = true
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.accentHex)
            }
            
            if recentCheckIns.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(0..<7) { _ in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.mediumGreyHex.opacity(0.1))
                                .frame(width: 32, height: 32)
                        }
                    }
                    
                    Text("Start tracking to see your weekly pattern")
                        .font(.subheadline)
                        .foregroundColor(.mediumGreyHex)
                }
                .padding(.vertical, 20)
            } else {
                // Weekly progress
                VStack(spacing: 16) {
                    HStack {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.mediumGreyHex)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(last7Days, id: \.self) { date in
                            let checkIn = checkInForDate(date)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(checkIn != nil ? 
                                    LinearGradient(
                                        colors: [Color.moodColor(for: checkIn!.moodEmoji), Color.moodColor(for: checkIn!.moodEmoji).opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) : 
                                    LinearGradient(
                                        colors: [Color.mediumGreyHex.opacity(0.1), Color.mediumGreyHex.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .shadow(color: checkIn != nil ? Color.moodColor(for: checkIn!.moodEmoji).opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }
    
    // MARK: - Tomorrow Preparation Section
    
    private var tomorrowPreparationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Tomorrow")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentHex)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text(generateTomorrowPrompt())
                    .font(.body)
                    .foregroundColor(.textMainHex)
                
                Text(getTomorrowInsight())
                    .font(.subheadline)
                    .foregroundColor(.mediumGreyHex)
                    .italic()
                
                HStack {
                    Button(action: { showingCheckIn = true }) {
                        Text("Set tomorrow's intention")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.8), Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .green.opacity(0.12), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(Color.cardBackgroundHex)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Stats")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.textMainHex)
            
            HStack(spacing: 16) {
                // Average mood
                MinimalStatCard(
                    title: "Average",
                    value: String(format: "%.1f", averageMoodThisWeek),
                    subtitle: "this week",
                    color: averageMoodColor
                )
                
                // Total entries
                MinimalStatCard(
                    title: "Total",
                    value: "\(checkInService.checkIns.count)",
                    subtitle: "check-ins",
                    color: .blue
                )
                
                // Best mood
                MinimalStatCard(
                    title: "Peak",
                    value: bestMoodValue,
                    subtitle: "best day",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Progress Insights Section
    
    private var progressInsightsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Insights")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.textMainHex)
            
            HStack(spacing: 16) {
                // Average mood
                MinimalStatCard(
                    title: "Average",
                    value: String(format: "%.1f", averageMoodThisWeek),
                    subtitle: "this week",
                    color: averageMoodColor
                )
                
                // Total entries
                MinimalStatCard(
                    title: "Total",
                    value: "\(checkInService.checkIns.count)",
                    subtitle: "check-ins",
                    color: .blue
                )
                
                // Best mood
                MinimalStatCard(
                    title: "Peak",
                    value: bestMoodValue,
                    subtitle: "best day",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Goal Progress Section
    
    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("12-Week Goals")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                if goalService.activeGoals.isEmpty {
                    Button(action: {
                        // Show goal onboarding
                    }) {
                        Text("Add Goal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentHex)
                    }
                }
            }
            
            if goalService.activeGoals.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.08))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "target")
                                    .font(.system(size: 32))
                                    .foregroundColor(.mediumGreyHex)
                                
                                Text("Set your first 12-week goal")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textMainHex)
                                
                                Text("Track meaningful progress with AI coaching")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mediumGreyHex)
                            }
                        )
                }
            } else {
                // Active goals
                VStack(spacing: 16) {
                    ForEach(goalService.activeGoals.prefix(3), id: \.id) { goal in
                        GoalProgressCard(goal: goal)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var todaysCheckIn: DailyCheckIn? {
        checkInService.checkIns.first { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
    }
    
    private var recentCheckIns: [DailyCheckIn] {
        let calendar = Calendar.current
        let now = Date()
        return checkInService.checkIns.filter { checkIn in
            calendar.dateInterval(of: .weekOfYear, for: now)?.contains(checkIn.date) ?? false
        }.sorted { $0.date < $1.date }
    }
    
    private var weekDays: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return last7Days.map { formatter.string(from: $0) }
    }
    
    private var last7Days: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { 
            calendar.date(byAdding: .day, value: -6 + $0, to: today)
        }
    }
    
    private func checkInForDate(_ date: Date) -> DailyCheckIn? {
        checkInService.checkIns.first { 
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    private var averageMoodThisWeek: Double {
        guard !recentCheckIns.isEmpty else { return 3.0 }
        let total = recentCheckIns.reduce(0) { sum, checkIn in
            sum + moodValue(from: checkIn.moodEmoji)
        }
        return Double(total) / Double(recentCheckIns.count)
    }
    
    private var averageMoodColor: Color {
        switch averageMoodThisWeek {
        case 4.5...: return .purple
        case 3.5..<4.5: return .green
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }
    
    private var bestMoodValue: String {
        guard let bestCheckIn = checkInService.checkIns.max(by: { 
            moodValue(from: $0.moodEmoji) < moodValue(from: $1.moodEmoji) 
        }) else { return "3.0" }
        return String(format: "%.1f", Double(moodValue(from: bestCheckIn.moodEmoji)))
    }
    
    // MARK: - Helper Functions
    
    private func moodValue(from moodIdentifier: String) -> Int {
        // Handle new mood name system
        switch moodIdentifier {
        case "Rough": return 1
        case "Okay": return 2  
        case "Neutral": return 3
        case "Good": return 4
        case "Great": return 5
        case "Awful": return 1
        case "Bad": return 2
        case "Amazing": return 5
        // Legacy emoji fallback
        case "😢": return 1
        case "😞": return 2
        case "😐": return 3
        case "😊": return 4
        case "😍": return 5
        default: return 3
        }
    }
    
    private func getYesterdayCheckIn() -> DailyCheckIn? {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        return checkInService.checkIns.first { calendar.isDate($0.date, inSameDayAs: yesterday) }
    }
    
    private func generateYesterdayReflectionPrompt(for checkIn: DailyCheckIn) -> String {
        let moodValue = self.moodValue(from: checkIn.moodEmoji)
        let happyThing = checkIn.happyThing.lowercased()
        
        switch moodValue {
        case 1, 2: // Rough/Bad
            if happyThing.contains("work") {
                return "That work day sounds tough. Did you find any small wins? What would help today feel lighter?"
            } else if happyThing.contains("exercise") || happyThing.contains("workout") {
                return "Even on hard days, you moved your body. How did that feel? Did it help at all?"
            } else {
                return "Yesterday was challenging. What's one thing that went better than expected?"
            }
        case 3: // Neutral
            return "Yesterday felt okay. What could tip today toward 'good'? Any small changes you want to try?"
        case 4, 5: // Good/Great
            if happyThing.contains("work") {
                return "That sounds like a solid work day! What made it click? Can you recreate that energy today?"
            } else if happyThing.contains("friend") || happyThing.contains("social") {
                return "Time with people lifted you up. Who brings out your best? Any plans to connect again soon?"
            } else if happyThing.contains("exercise") || happyThing.contains("workout") {
                return "You felt great after moving! Your body loves that. What's your movement plan for today?"
            } else {
                return "You had a good day! What made the difference? How can you carry that momentum forward?"
            }
        default:
            return "How are you feeling about yesterday now? Any insights looking back?"
        }
    }
    
    private func generateTomorrowPrompt() -> String {
        // Use today's mood if available, otherwise look at recent patterns
        let todayMoodValue = todaysCheckIn != nil ? moodValue(from: todaysCheckIn!.moodEmoji) : 3
        let todayHappy = todaysCheckIn?.happyThing.lowercased() ?? ""
        
        // Get recent mood trend
        let recentMoodAverage = recentCheckIns.isEmpty ? 3 : recentCheckIns.map { moodValue(from: $0.moodEmoji) }.reduce(0, +) / recentCheckIns.count
        
        switch todayMoodValue {
        case 4, 5: // Good/Great day today
            if todayHappy.contains("work") {
                return "That work flow was solid! What's one thing you can do tomorrow to keep that energy?"
            } else if todayHappy.contains("friend") || todayHappy.contains("social") {
                return "Time with people lifted you up! Who could you connect with tomorrow?"
            } else if todayHappy.contains("exercise") || todayHappy.contains("workout") {
                return "You felt amazing after moving! What's your movement plan for tomorrow?"
            } else {
                return "You're on a roll! What's one intention that will keep this momentum going?"
            }
        case 3: // Neutral day
            if recentMoodAverage >= 4 {
                return "You've been doing well lately! What small thing could make tomorrow feel more alive?"
            } else {
                return "What's one thing you're looking forward to tomorrow? Even something small counts."
            }
        case 1, 2: // Tough day today
            if recentMoodAverage >= 3 {
                return "Tomorrow's a fresh start. What's one gentle thing you can do for yourself?"
            } else {
                return "You're being so strong. What's one tiny step that could make tomorrow feel lighter?"
            }
        default:
            return "What's one intention you want to set for tomorrow? Trust yourself."
        }
    }
    
    private func getTomorrowInsight() -> String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dayNumber = Calendar.current.component(.day, from: tomorrow)
        
        // Simple pattern-based insights
        let insights = [
            "Small actions create big changes over time.",
            "Tomorrow is a blank canvas. Paint it with intention.",
            "You're building something beautiful, one day at a time.",
            "Your future self will thank you for today's choices.",
            "Progress isn't always visible, but it's always happening.",
            "Tomorrow's potential is limitless when you show up."
        ]
        
        // Return a consistent insight based on the day to create familiarity
        let index = dayNumber % insights.count
        return insights[index]
    }
}

// MARK: - Minimal Stat Card Component

struct MinimalStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.mediumGreyHex)
                .textCase(.uppercase)
            
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.textMainHex)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.mediumGreyHex)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Goal Progress Card Component

struct GoalProgressCard: View {
    let goal: TwelveWeekGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textMainHex)
                    
                    Text(goal.category.rawValue.capitalized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.mediumGreyHex)
                        .textCase(.uppercase)
                }
                
                Spacer()
                
                // Progress percentage
                Text("\(Int(goal.currentProgress * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentHex)
            }
            
            // Progress bar
            ProgressView(value: goal.currentProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentHex))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Next milestone
            if let nextMilestone = goal.milestones.first(where: { !$0.isCompleted }) {
                HStack {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text("Next: \(nextMilestone.title)")
                        .font(.system(size: 14))
                        .foregroundColor(.textMainHex)
                    
                    Spacer()
                    
                    Text("Week \(nextMilestone.targetWeek)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.mediumGreyHex)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentHex.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
} 