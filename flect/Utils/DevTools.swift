import Foundation
import SwiftUI

struct DevTools {
    static let shared = DevTools()
    private let moods = ["Rough", "Okay", "Neutral", "Good", "Great"]
    #if DEBUG
    static var currentAppDate: Date? = nil
    #endif
    
    /// Advances the app's current date by one day (does NOT create a check-in).
    @MainActor
    func skipDayAhead() {
        #if DEBUG
        let calendar = Calendar.current
        let today = DevTools.currentAppDate ?? calendar.startOfDay(for: Date())
        let nextDay = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        DevTools.currentAppDate = nextDay
        #endif
    }
    
    /// Creates a check-in for the current simulated day (start of day).
    @MainActor
    func addDevCheckInForToday() {
        #if DEBUG
        let calendar = Calendar.current
        let today = DevTools.currentAppDate ?? calendar.startOfDay(for: Date())
        let checkInService = CheckInService.shared
        let mood = moods[(checkInService.checkIns.count) % moods.count]
        let happyThing = "DevTools happy thing for \(mood)"
        let improveThing = "DevTools improve thing for \(mood)"
        let checkIn = DailyCheckIn(
            date: calendar.startOfDay(for: today),
            happyThing: happyThing,
            improveThing: improveThing,
            moodName: mood,
            completionState: .completed
        )
        checkInService.saveCheckIn(checkIn)
        #endif
    }
    
    /// Deletes the check-in for the current simulated day (if any).
    @MainActor
    static func deleteTodayCheckIn() async {
        #if DEBUG
        let calendar = Calendar.current
        let today = DevTools.currentAppDate ?? calendar.startOfDay(for: Date())
        let checkInService = CheckInService.shared
        if let idx = checkInService.checkIns.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            checkInService.checkIns.remove(at: idx)
            checkInService.saveCheckIns()
        }
        #endif
    }
    
    @MainActor
    static func resetToFreshUser() {
        // Reset all services to fresh state
        CheckInService.shared.resetToFreshState()
        GoalService.shared.resetToFreshState()
        UserPreferencesService.shared.resetPreferences()
        
        // Post notification to refresh the app state
        NotificationCenter.default.post(name: Notification.Name("resetToFreshUser"), object: nil)
        
        print("🔄 COMPLETE RESET TO FRESH USER")
        print("   ✅ User preferences reset")
    }
    
    @MainActor
    static func resetToSampleData() {
        // Keep onboarding as completed for sample data
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Reset services to sample data
        CheckInService.shared.resetToSampleData()
        GoalService.shared.resetToSampleData()
        
        print("🎯 RESET TO SAMPLE DATA")
        print("   ✅ Onboarding completed")
        print("   ✅ Sample check-ins loaded")
        print("   ✅ Sample goals loaded")
        print("   ✅ Ready for existing user experience")
    }
}

#if DEBUG
struct DevToolsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var checkInService = CheckInService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("🛠️ Development Tools")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Reset app state for testing different user journeys")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    Button("🆕 Reset to Fresh User") {
                        DevTools.resetToFreshUser()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("🎯 Reset to Sample Data") {
                        DevTools.resetToSampleData()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Divider()
                    Button("Test Data") {
                        checkInService.loadSampleDataForTesting()
                        HapticManager.shared.lightImpact()
                    }
                    Button("Skip Day Ahead") {
                        DevTools.shared.skipDayAhead()
                        HapticManager.shared.mediumImpact()
                    }
                    Button("Delete Today's Check-In") {
                        Task { await DevTools.deleteTodayCheckIn() }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Fresh User:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Complete day-1 onboarding experience")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Sample Data:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    Text("Existing user with 30 days of data")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Dev Tools")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#endif 