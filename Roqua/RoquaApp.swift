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
    @StateObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var systemColorScheme
    
    private var appColorScheme: ColorScheme? {
        switch settings.colorScheme {
        case 1: return .light
        case 2: return .dark
        default: return nil // System default
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .statusBarHidden()
                    .preferredColorScheme(appColorScheme)
            } else {
                OnboardingView()
                    .statusBarHidden()
                    .preferredColorScheme(appColorScheme)
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
