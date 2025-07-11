//
//  flectApp.swift
//  flect
//
//  Created by Khaydien on 02/07/2025.
//

import SwiftUI
import UserNotifications

@main
struct flectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var notificationService: NotificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationService)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Configure notification categories and actions
        configureNotificationCategories()
        
        return true
    }
    
    private func configureNotificationCategories() {
        // Check-in actions
        let checkInAction = UNNotificationAction(
            identifier: "check_in_now",
            title: "Check In Now",
            options: .foreground
        )
        let checkInCategory = UNNotificationCategory(
            identifier: "check_in",
            actions: [checkInAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Task actions
        let completeTaskAction = UNNotificationAction(
            identifier: "complete_task",
            title: "Mark as Complete",
            options: .foreground
        )
        let postponeTaskAction = UNNotificationAction(
            identifier: "postpone_task",
            title: "Postpone",
            options: .foreground
        )
        let taskCategory = UNNotificationCategory(
            identifier: "task",
            actions: [completeTaskAction, postponeTaskAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Goal actions
        let updateGoalAction = UNNotificationAction(
            identifier: "update_goal",
            title: "Update Progress",
            options: .foreground
        )
        let goalCategory = UNNotificationCategory(
            identifier: "goal",
            actions: [updateGoalAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Wellbeing actions
        let wellbeingAction = UNNotificationAction(
            identifier: "view_suggestion",
            title: "View Suggestion",
            options: .foreground
        )
        let wellbeingCategory = UNNotificationCategory(
            identifier: "wellbeing",
            actions: [wellbeingAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            checkInCategory,
            taskCategory,
            goalCategory,
            wellbeingCategory
        ])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        let actionIdentifier = response.actionIdentifier
        
        switch (categoryIdentifier, actionIdentifier) {
        case ("check_in", "check_in_now"):
            NotificationCenter.default.post(name: Notification.Name("ShowCheckIn"), object: nil)
            
        case ("task", "complete_task"):
            if let taskId = response.notification.request.identifier.split(separator: "_").last {
                NotificationCenter.default.post(
                    name: Notification.Name("CompleteTask"),
                    object: nil,
                    userInfo: ["taskId": String(taskId)]
                )
            }
            
        case ("task", "postpone_task"):
            if let taskId = response.notification.request.identifier.split(separator: "_").last {
                NotificationCenter.default.post(
                    name: Notification.Name("PostponeTask"),
                    object: nil,
                    userInfo: ["taskId": String(taskId)]
                )
            }
            
        case ("goal", "update_goal"):
            if let goalId = response.notification.request.identifier.split(separator: "_").last {
                NotificationCenter.default.post(
                    name: Notification.Name("UpdateGoal"),
                    object: nil,
                    userInfo: ["goalId": String(goalId)]
                )
            }
            
        case ("wellbeing", "view_suggestion"):
            NotificationCenter.default.post(name: Notification.Name("ShowWellbeingSuggestion"), object: nil)
            
        default:
            break
        }
        
        completionHandler()
    }
}
