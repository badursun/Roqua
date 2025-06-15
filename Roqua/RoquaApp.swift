//
//  RoquaApp.swift
//  Roqua
//
//  Created by Anthony Burak DURSUN on 15.06.2025.
//

import SwiftUI

@main
struct RoquaApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .statusBarHidden()
            } else {
                OnboardingView()
                    .statusBarHidden()
                    .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
                        hasCompletedOnboarding = true
                    }
            }
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
