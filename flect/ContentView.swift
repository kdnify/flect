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
            // Dev tools access - visible debug button for easier access
            VStack {
                HStack {
                    Button(action: { showingDevTools = true }) {
                        Text("🛠️ DevTools")
                            .font(.caption)
                            .padding(8)
                            .background(Color.yellow.opacity(0.7))
                            .cornerRadius(8)
                    }
                    .padding(.leading, 12)
                    .padding(.top, 8)
                    Spacer()
                }
                Spacer()
            }
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
            userPreferences.hasCompletedOnboarding = true
            userPreferences.savePreferences()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("resetToFreshUser"))) { _ in
            userPreferences.loadPreferences() // Reload after reset
        }
        #if DEBUG
        .sheet(isPresented: $showingDevTools) {
            DevToolsView()
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
