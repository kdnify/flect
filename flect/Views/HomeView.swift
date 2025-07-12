import SwiftUI

struct HomeView: View {
    @StateObject private var checkInService = CheckInService.shared
    @StateObject private var goalService = GoalService.shared
    @EnvironmentObject var userPreferences: UserPreferencesService
    @State private var showingCheckIn = false
    @State private var showingHistory = false
    @State private var showingMorningInsights = false
    @State private var showingSprintPlanning = false
    @State private var showingSprintTracking = false
    @State private var showingTaskManagement = false
    @State private var showingAIChat = false
    
    #if DEBUG
    @State private var showDevTools = false
    #endif
    
    // 1. Add state for dock icon animation
    @State private var dockBounce: [Int: Bool] = [0: false, 1: false, 2: false, 3: false]
    
    @State private var showPostSubmission = false
    @State private var postSubmissionBrainDump: DailyBrainDump? = nil
    @State private var postSubmissionMood: MoodLevel? = nil
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        // Header with proper safe area
                        headerSection
                            .padding(.top, geometry.safeAreaInsets.top)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 6)
                            .background(Color.backgroundHex)
                        // Main content
                        ScrollView {
                            VStack(spacing: 32) {
                                if goalService.shouldShowNextDayAdvice() {
                                    morningInsightsBanner
                                }
                                todaysMoodSection
                                yesterdayReflectionSection
                                weeklyOverviewSection
                                tomorrowPreparationSection
                                momentumSection
                                progressInsightsSection
                                goalProgressSection
                                Spacer(minLength: 120) // Ensure dock never overlaps content
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }
                    }
                    .background(Color.backgroundHex)
                    .ignoresSafeArea(.all, edges: .top)
                    // Floating bottom dock
                    bottomDock
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCheckIn, onDismiss: {
            // No-op, handled by notification
        }) {
            MultiStepCheckInView(onCheckInComplete: { brainDump, mood in
                postSubmissionBrainDump = brainDump
                postSubmissionMood = mood
                showPostSubmission = true
            })
        }
        .sheet(isPresented: $showPostSubmission, onDismiss: {
            postSubmissionBrainDump = nil
            postSubmissionMood = nil
        }) {
            if let brainDump = postSubmissionBrainDump, let mood = postSubmissionMood {
                PostSubmissionView(dailyBrainDump: brainDump, selectedMood: mood)
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showingMorningInsights) {
            MorningInsightsView()
        }
        .sheet(isPresented: $showingSprintPlanning) {
            Text("Sprint Planning - Coming Soon!")
                .font(.title)
                .foregroundColor(.textMainHex)
        }
        .sheet(isPresented: $showingSprintTracking) {
            Text("Sprint Tracking - Coming Soon!")
                .font(.title)
                .foregroundColor(.textMainHex)
        }
        .sheet(isPresented: $showingTaskManagement) {
            TaskManagementView()
        }
        .sheet(isPresented: $showingAIChat) {
            if let chatSession = goalService.createAccountabilityChatSession() {
                AIChatView(chatSession: chatSession)
            }
        }
        .onAppear {
            checkInService.loadTodaysCheckIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("checkInCompleted"))) { _ in
            checkInService.loadTodaysCheckIn()
            showingCheckIn = false
        }
    }

    // MARK: - Bottom Dock
    private var bottomDock: some View {
        HStack(spacing: 32) {
            ForEach(0..<4) { idx in
                let iconData: (String, String, Color, () -> Void) = [
                    ("brain.head.profile", "Insights", .blue, { showingHistory = true }),
                    ("checklist", "Tasks", .orange, { showingTaskManagement = true }),
                    ("message.circle", "Coach", .purple, { showingAIChat = true }),
                    ("target", "Plan", .green, { showingSprintPlanning = true })
                ][idx]
                Button(action: {
                    dockBounce[idx] = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dockBounce[idx] = false }
                    iconData.3()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: iconData.0)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(iconData.2)
                            .scaleEffect(dockBounce[idx] == true ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: dockBounce[idx])
                        Text(iconData.1)
                            .font(.caption2)
                            .foregroundColor(.textMainHex)
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(BlurView(style: .systemMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.bottom, 36) // Increased bottom padding
        .padding(.horizontal, 16)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("flect")
                        .font(.system(size: 42, weight: .light, design: .default))
                        .fontWeight(.semibold)
                        .foregroundColor(.textMainHex)
                        .tracking(1.5)
                        .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
                        .onTapGesture(count: 3) {
                            #if DEBUG
                            NotificationCenter.default.post(name: Notification.Name("showDevTools"), object: nil)
                            #endif
                        }
                    Text(userPreferences.getPersonalizedWelcomeMessage())
                        .font(.system(size: 13, weight: .light, design: .default))
                        .italic()
                        .foregroundColor(.mediumGreyHex.opacity(0.7))
                        .tracking(0.3)
                }
                Spacer()
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
                .padding(.bottom, 12) // Add extra bottom padding
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
                .font(.system(size: 26, weight: .bold, design: .default))
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
                                .fill(Color.moodColor(for: todaysCheckIn.moodName))
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.moodColor(for: todaysCheckIn.moodName).opacity(0.25), radius: 8, x: 0, y: 4)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                                .accessibilityLabel("Today's mood color")
                        }
                        Spacer()
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.moodColor(for: todaysCheckIn.moodName))
                            .frame(width: 60, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.moodColor(for: todaysCheckIn.moodName).opacity(0.3), radius: 8, x: 0, y: 4)
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
                    // Entry is locked after submission to encourage thoughtful reflection
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Entry submitted")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textMainHex)
                            
                            Text("Locked to preserve authentic reflection")
                                .font(.system(size: 12))
                                .foregroundColor(.mediumGreyHex)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
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
                    Button(action: { 
                        // Only allow check-in if no entry exists for today
                        if !checkInService.hasCheckedInToday() {
                            showingCheckIn = true 
                        }
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
                            .fill(Color.moodColor(for: yesterdayCheckIn.moodName))
                            .frame(width: 20, height: 20)
                            .shadow(color: Color.moodColor(for: yesterdayCheckIn.moodName).opacity(0.2), radius: 4, x: 0, y: 2)
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
                        
                        Button(action: { 
                            // Only allow if no entry exists for today - keep entries authentic and one-time
                            if !checkInService.hasCheckedInToday() {
                                showingCheckIn = true 
                            }
                        }) {
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
                Text("Week \(currentWeekNumber)")
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Button("View All") {
                    showingHistory = true
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.accentHex)
            }
            
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { offset in
                    let calendar = Calendar.current
                    let day = calendar.date(byAdding: .day, value: -6 + offset, to: calendar.startOfDay(for: now))!
                    let checkIn = checkInService.checkIns.first { calendar.isDate($0.date, inSameDayAs: day) }
                    VStack(spacing: 2) {
                        Circle()
                            .fill(Color.moodColor(for: checkIn?.moodName ?? ""))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().stroke(Color.borderColorHex, lineWidth: 1)
                            )
                        #if DEBUG
                        Text("\(calendar.component(.day, from: day))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        #endif
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            #if DEBUG
            VStack(alignment: .leading, spacing: 2) {
                Text("Check-in Dates:")
                    .font(.caption2)
                    .foregroundColor(.orange)
                ForEach(checkInService.checkIns, id: \.id) { checkIn in
                    Text("\(checkIn.date)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            #endif
        }
    }
    
    // MARK: - Tomorrow Preparation Section
    
    private var tomorrowPreparationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Tomorrow")
                    .font(.system(size: 22, weight: .semibold, design: .default))
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
                    Button(action: { 
                        // Only allow if no entry exists for today - one thoughtful entry per day
                        if !checkInService.hasCheckedInToday() {
                            showingCheckIn = true 
                        }
                    }) {
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
    
    // MARK: - Momentum Section (Replaces Quick Stats)
    
    private var momentumSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Your Journey")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                if checkInService.calculateUserEngagement().currentStreak > 1 {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // Streak & Momentum
                if checkInService.calculateUserEngagement().currentStreak > 0 {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(checkInService.calculateUserEngagement().currentStreak)")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.orange)
                            Text("day streak")
                                .font(.subheadline)
                                .foregroundColor(.mediumGreyHex)
                            Text("Week \(currentWeekNumber)")
                                .font(.caption)
                                .foregroundColor(.mediumGreyHex)
                        }
                        
                        Spacer()
                        
                        // Personality-driven insight
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(userPreferences.getPersonalizedMessage(for: .encouragement))
                                .font(.subheadline)
                                .foregroundColor(.textMainHex)
                                .multilineTextAlignment(.trailing)
                            
                            if let personalityType = userPreferences.personalityProfile?.primaryType {
                                Text("\(personalityType.emoji) \(personalityType.title)")
                                    .font(.caption)
                                    .foregroundColor(.mediumGreyHex)
                            }
                        }
                    }
                } else if checkInService.checkIns.count > 0 {
                    // No current streak but has entries
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ready for a new streak?")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textMainHex)
                        
                        Text("Your last check-in was \(daysSinceLastCheckIn) day\(daysSinceLastCheckIn == 1 ? "" : "s") ago")
                            .font(.subheadline)
                            .foregroundColor(.mediumGreyHex)
                    }
                } else {
                    // First time user
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to your journey")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textMainHex)
                        
                        Text("Start building your reflection habit")
                            .font(.subheadline)
                            .foregroundColor(.mediumGreyHex)
                    }
                }
                
                // Debug information for testing
                #if DEBUG
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Info:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Text("Streak: \(checkInService.calculateUserEngagement().currentStreak) days")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                    
                    Text("Total entries: \(checkInService.checkIns.count)")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                    
                    let streakDates = checkInService.getCurrentStreakDates()
                    Text("Streak dates: \(streakDates.map { Calendar.current.component(.day, from: $0) })")
                        .font(.caption)
                        .foregroundColor(.mediumGreyHex)
                }
                .padding(.top, 8)
                #endif
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.05),
                        Color.blue.opacity(0.03)
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
                            colors: [Color.orange.opacity(0.2), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
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
        return formatter.string(from: now) // Use simulated date
    }
    
    private var todaysCheckIn: DailyCheckIn? {
        checkInService.checkIns.first { Calendar.current.isDate($0.date, inSameDayAs: now) }
    }
    
    private var currentWeekNumber: Int {
        let journeyDay = userPreferences.journeyDay
        return max(1, (journeyDay - 1) / 7 + 1)
    }
    
    private var recentCheckIns: [DailyCheckIn] {
        let calendar = Calendar.current
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
        // Show last 7 days in chronological order (6 days ago to today)
        return (0..<7).compactMap { 
            calendar.date(byAdding: .day, value: -6 + $0, to: now)
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
            sum + moodValue(from: checkIn.moodName)
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
            moodValue(from: $0.moodName) < moodValue(from: $1.moodName) 
        }) else { return "3.0" }
        return String(format: "%.1f", Double(moodValue(from: bestCheckIn.moodName)))
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
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        return checkInService.checkIns.first { calendar.isDate($0.date, inSameDayAs: yesterday) }
    }
    
    private var daysSinceLastCheckIn: Int {
        guard let lastCheckIn = checkInService.checkIns.sorted(by: { $0.date > $1.date }).first else {
            return 0
        }
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: lastCheckIn.date, to: now).day ?? 0
        return daysSince
    }
    
    private func generateYesterdayReflectionPrompt(for checkIn: DailyCheckIn) -> String {
        let moodValue = self.moodValue(from: checkIn.moodName)
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
        let todayMoodValue = todaysCheckIn != nil ? moodValue(from: todaysCheckIn!.moodName) : 3
        let todayHappy = todaysCheckIn?.happyThing.lowercased() ?? ""
        
        // Get recent mood trend
        let recentMoodAverage = recentCheckIns.isEmpty ? 3 : recentCheckIns.map { moodValue(from: $0.moodName) }.reduce(0, +) / recentCheckIns.count
        
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
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
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
    
    // MARK: - Calendar Day View Helpers
    
    private func calendarDayColor(for state: CalendarDayState) -> LinearGradient {
        switch state {
        case .hasCheckIn(let mood):
            return LinearGradient(
                colors: [Color.moodColor(for: mood), Color.moodColor(for: mood).opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .streakGap:
            return LinearGradient(
                colors: [Color.orange.opacity(0.6), Color.orange.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .noCheckIn:
            return LinearGradient(
                colors: [Color.mediumGreyHex.opacity(0.1), Color.mediumGreyHex.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func calendarDayShadowColor(for state: CalendarDayState) -> Color {
        switch state {
        case .hasCheckIn(let mood):
            return Color.moodColor(for: mood).opacity(0.2)
        case .streakGap:
            return Color.orange.opacity(0.2)
        case .noCheckIn:
            return .clear
        }
    }
    
    private func calendarDayOverlay(for state: CalendarDayState) -> some View {
        switch state {
        case .hasCheckIn:
            return AnyView(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        case .streakGap:
            return AnyView(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                    .overlay(
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                    )
            )
        case .noCheckIn:
            return AnyView(EmptyView())
        }
    }
    
    private var now: Date {
        #if DEBUG
        return DevTools.currentAppDate ?? Date()
        #else
        return Date()
        #endif
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

struct GoalProgressSummaryCard: View {
    let progress: GoalProgressData
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progress.goalTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textMainHex)
                    Text(progress.goalCategory)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.mediumGreyHex)
                        .textCase(.uppercase)
                }
                Spacer()
                Text("\(progress.progressPercentage)%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentHex)
            }
            ProgressView(value: Double(progress.progressPercentage) / 100.0, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentHex))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            if progress.milestoneCompleted {
                HStack {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("Milestone completed this week!")
                        .font(.system(size: 14))
                        .foregroundColor(.textMainHex)
                    Spacer()
                }
            }
            Text("+\(progress.weeklyProgress)% this week")
                .font(.caption)
                .foregroundColor(.green)
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

// BlurView for background effect
import UIKit
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
} 