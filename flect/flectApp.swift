//
//  flectApp.swift
//  flect
//
//  Created by Khaydien on 02/07/2025.
//

import SwiftUI

@main
struct flectApp: App {
    @State private var showingLaunchScreen = true
    
    init() {
        // Remove any calls to resetToSampleData on app launch
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showingLaunchScreen {
                    LaunchScreen {
                        showingLaunchScreen = false
                    }
                } else {
                    ContentView()
                }
            }
        }
    }
}
