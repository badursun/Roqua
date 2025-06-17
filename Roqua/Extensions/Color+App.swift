import SwiftUI

// MARK: - App Color System
extension Color {
    // MARK: - Background Colors
    static let appBackground = Color(
        light: Color(hex: "F8F9FA"),
        dark: Color(hex: "130E20")
    )
    
    static let cardBackground = Color(
        light: Color.white,
        dark: Color(hex: "1F2142")
    )
    
    // MARK: - Text Colors
    static let primaryText = Color(
        light: Color(hex: "1A1A1A"),
        dark: Color.white
    )
    
    static let secondaryText = Color(
        light: Color(hex: "6C757D"),
        dark: Color(hex: "8D91A7")
    )
    
    // MARK: - Progress Colors
    static let progressGradientStart = Color(hex: "EB901F")
    static let progressGradientEnd = Color(hex: "FFFF45")
    
    static var progressGradient: LinearGradient {
        LinearGradient(
            colors: [progressGradientStart, progressGradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Achievement Rarity Colors
    static let commonGradient = LinearGradient(
        colors: [Color(hex: "6B7280"), Color(hex: "9CA3AF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let uncommonGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "34D399")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let rareGradient = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "60A5FA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let epicGradient = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "A78BFA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let legendaryGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "FCD34D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Helper Initializers
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Achievement Specific Extensions
extension Color {
    static func rarityGradient(for rarity: String) -> LinearGradient {
        switch rarity.lowercased() {
        case "common":
            return commonGradient
        case "uncommon":
            return uncommonGradient
        case "rare":
            return rareGradient
        case "epic":
            return epicGradient
        case "legendary":
            return legendaryGradient
        default:
            return commonGradient
        }
    }
    
    static func rarityColor(for rarity: String) -> Color {
        switch rarity.lowercased() {
        case "common":
            return Color(hex: "9CA3AF")
        case "uncommon":
            return Color(hex: "34D399")
        case "rare":
            return Color(hex: "60A5FA")
        case "epic":
            return Color(hex: "A78BFA")
        case "legendary":
            return Color(hex: "FCD34D")
        default:
            return Color(hex: "9CA3AF")
        }
    }
} 