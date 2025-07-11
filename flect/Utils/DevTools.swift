import SwiftUI

struct DevTools {
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