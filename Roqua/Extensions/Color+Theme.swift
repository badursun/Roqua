import SwiftUI

extension Color {
    // MARK: - Dynamic Text Colors
    static var dynamicPrimary: Color {
        Color.primary
    }
    
    static var dynamicSecondary: Color {
        Color.secondary
    }
    
    static var dynamicBackground: Color {
        Color(.systemBackground)
    }
    
    static var dynamicSecondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    // MARK: - Theme-Aware Text Colors
    /// Primary text color that adapts to theme (white in dark, black in light)
    static var adaptiveText: Color {
        Color.primary
    }
    
    /// Secondary text color that adapts to theme
    static var adaptiveSecondaryText: Color {
        Color.secondary
    }
    
    /// Accent text color for highlighted content
    static var adaptiveAccent: Color {
        Color.accentColor
    }
    
    // MARK: - Achievement Colors
    /// Achievement text color (white in dark mode, black in light mode)
    static var achievementText: Color {
        Color.primary
    }
    
    /// Achievement secondary text
    static var achievementSecondaryText: Color {
        Color.secondary
    }
    
    /// Achievement highlight text (for premium/special content)
    static var achievementHighlight: Color {
        Color(.label)
    }
    
    /// Achievement card background gradient colors
    static var achievementCardGradientTop: Color {
        Color(.systemBackground).opacity(0.3)
    }
    
    static var achievementCardGradientBottom: Color {
        Color(.systemBackground).opacity(0.1)
    }
    
    // MARK: - UI Element Colors
    /// Button text color that adapts to theme
    static var buttonText: Color {
        Color.primary
    }
    
    /// Card text color
    static var cardText: Color {
        Color.primary
    }
    
    /// Navigation text color
    static var navText: Color {
        Color.primary
    }
    
    // MARK: - TabView Colors
    /// TabView accent color that adapts to theme
    static var tabAccent: Color {
        Color.accentColor
    }
    
    /// Active tab color (white in dark, black in light)
    static var activeTab: Color {
        Color.primary
    }
} 