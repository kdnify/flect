//
//  ContentView.swift
//  flect
//
//  Created by Khaydien on 02/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var checkInService = CheckInService.shared
    @StateObject private var goalService = GoalService.shared
    @StateObject private var userPreferences = UserPreferencesService.shared
    @State private var showingGoalOnboarding = false
    
    #if DEBUG
    @State private var showingDevTools = false
    #endif
    
    var body: some View {
        ZStack {
            if userPreferences.hasCompletedOnboarding {
                NavigationView {
                    HomeView()
                        .navigationBarHidden(true)
                }
                .environmentObject(checkInService)
                .environmentObject(goalService)
                .environmentObject(userPreferences)
                .onAppear {
                    // Check if user needs goal onboarding (for existing users)
                    if goalService.isFirstTimeUser && goalService.activeGoals.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showingGoalOnboarding = true
                        }
                    }
                }
                .fullScreenCover(isPresented: $showingGoalOnboarding) {
                    GoalOnboardingView()
                }
            } else {
                WelcomeView()
                    .environmentObject(checkInService)
                    .environmentObject(goalService)
                    .environmentObject(userPreferences)
            }
            
            #if DEBUG
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
            userPreferences.hasCompletedOnboarding = true
            userPreferences.savePreferences()
            
            // Start the user's journey when onboarding is completed
            if userPreferences.journeyStartDate == nil {
                userPreferences.startJourney()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("resetToFreshUser"))) { _ in
            userPreferences.loadPreferences() // Reload after reset
        }
        #if DEBUG
        .sheet(isPresented: $showingDevTools) {
            DevToolsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("showDevTools"))) { _ in
            showingDevTools = true
        }
        #endif
    }
}

#Preview {
    ContentView()
}

// MARK: - Notification Extension

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
