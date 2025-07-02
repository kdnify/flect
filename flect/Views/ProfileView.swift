import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = JournalViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Stats
                    statsSection
                    
                    // Settings
                    settingsSection
                    
                    // Data Management
                    dataManagementSection
                    
                    // About
                    aboutSection
                }
                .padding()
            }
            .background(Color.background)
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button("Done") {
                dismiss()
            }
            .foregroundColor(.mediumGrey)
            
            Spacer()
            
            Text("Profile")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMain)
            
            Spacer()
            
            // Placeholder for balance
            Text("Done")
                .foregroundColor(.clear)
        }
        .padding()
        .background(Color.cardBackground)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var statsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Journal Stats")
                    .font(.headline)
                    .foregroundColor(.textMain)
                
                HStack(spacing: 20) {
                    StatItem(
                        title: "Total Entries",
                        value: "\(viewModel.journalEntries.count)",
                        icon: "book.closed"
                    )
                    
                    StatItem(
                        title: "Pending Tasks",
                        value: "\(viewModel.pendingTasks.count)",
                        icon: "circle"
                    )
                    
                    StatItem(
                        title: "Completed",
                        value: "\(viewModel.completedTasks.count)",
                        icon: "checkmark.circle.fill"
                    )
                }
            }
        }
    }
    
    private var settingsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.textMain)
                
                VStack(spacing: 0) {
                    SettingsRow(
                        title: "Notifications",
                        subtitle: "Daily journal reminders",
                        icon: "bell",
                        action: {}
                    )
                    
                    Divider()
                    
                    SettingsRow(
                        title: "Writing Style",
                        subtitle: "Concise",
                        icon: "pencil",
                        action: {}
                    )
                    
                    Divider()
                    
                    SettingsRow(
                        title: "Theme",
                        subtitle: "Light",
                        icon: "paintbrush",
                        action: {}
                    )
                }
            }
        }
    }
    
    private var dataManagementSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Data Management")
                    .font(.headline)
                    .foregroundColor(.textMain)
                
                VStack(spacing: 0) {
                    SettingsRow(
                        title: "Export Data",
                        subtitle: "Download your journal entries",
                        icon: "square.and.arrow.up",
                        action: {}
                    )
                    
                    Divider()
                    
                    SettingsRow(
                        title: "Clear All Data",
                        subtitle: "Permanently delete everything",
                        icon: "trash",
                        action: {
                            // Show confirmation dialog
                        }
                    )
                }
            }
        }
    }
    
    private var aboutSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("About Flect")
                    .font(.headline)
                    .foregroundColor(.textMain)
                
                VStack(spacing: 0) {
                    SettingsRow(
                        title: "Version",
                        subtitle: "1.0.0",
                        icon: "info.circle",
                        action: {}
                    )
                    
                    Divider()
                    
                    SettingsRow(
                        title: "Privacy Policy",
                        subtitle: "How we protect your data",
                        icon: "hand.raised",
                        action: {}
                    )
                    
                    Divider()
                    
                    SettingsRow(
                        title: "Terms of Service",
                        subtitle: "App usage terms",
                        icon: "doc.text",
                        action: {}
                    )
                }
            }
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accent)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textMain)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.mediumGrey)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.mediumGrey)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.textMain)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.mediumGrey)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.mediumGrey)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
} 