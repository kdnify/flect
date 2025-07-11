import SwiftUI
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.isAuthorized = true
                }
            }
        }
    }
    
    func scheduleCheckInReminder(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for your daily check-in!"
        content.body = "Take a moment to reflect on your day and track your progress."
        content.sound = .default
        content.categoryIdentifier = "check_in"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_check_in",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleTaskReminder(taskId: String, title: String, dueDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = title
        content.sound = .default
        content.categoryIdentifier = "task"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "task_\(taskId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleGoalReminder(goalId: String, title: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Goal Check-in"
        content.body = "Time to review your progress on: \(title)"
        content.sound = .default
        content.categoryIdentifier = "goal"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "goal_\(goalId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleWellbeingReminder(suggestion: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Wellbeing Suggestion"
        content.body = suggestion
        content.sound = .default
        content.categoryIdentifier = "wellbeing"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "wellbeing_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
} 