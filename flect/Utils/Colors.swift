import SwiftUI

extension Color {
    // MARK: - Adaptive Colors for Dark Mode
    
    // Primary Colors - Adaptive for light/dark mode
    static let primary = Color("Primary")
    static let accent = Color("Accent") 
    static let background = Color("Background")
    
    // Text Colors - Adaptive
    static let textMain = Color("TextMain")
    static let textSecondary = Color("TextSecondary")
    static let mediumGrey = Color("MediumGrey")
    
    // Background Colors - Adaptive
    static let cardBackground = Color("CardBackground")
    static let surfaceBackground = Color("SurfaceBackground")
    
    // Border and Separator Colors - Adaptive
    static let borderColor = Color("BorderColor")
    static let separatorColor = Color("SeparatorColor")
    
    // Status Colors - Consistent across modes but with different opacity
    static let error = Color("ErrorColor")
    static let warning = Color("WarningColor")
    static let success = Color("SuccessColor")
    static let info = Color("InfoColor")
    
    // MARK: - Fallback Hex Colors (for compatibility)
    
    // Primary Colors (corrected hex values from design specs)
    static let primaryHex = Color(hex: "2B564C") // Deep Blue
    static let accentHex = Color(hex: "28564C") // Soft Teal (corrected from 28564C4)
    static let backgroundHex = Color(hex: "FAFAFA") // Off White (corrected from FAFAFFA)
    
    // Text Colors
    static let textMainHex = Color(hex: "111111") // Near Black
    static let mediumGreyHex = Color(hex: "666666") // Medium Grey (corrected from 6666)
    static let softRed = Color.red // Error color
    
    // Additional app colors
    static let cardBackgroundHex = Color.white
    static let borderColorHex = Color.gray.opacity(0.2)
    
    // MARK: - Dynamic Colors for Better Dark Mode Support
    
    /// Adaptive color that automatically adjusts for light/dark mode
    static func adaptiveColor(
        light: String, 
        dark: String, 
        lightOpacity: Double = 1.0, 
        darkOpacity: Double = 1.0
    ) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(Color(hex: dark).opacity(darkOpacity))
            default:
                return UIColor(Color(hex: light).opacity(lightOpacity))
            }
        })
    }
    
    /// Text color that adapts to background
    static var adaptiveText: Color {
        return adaptiveColor(light: "111111", dark: "FFFFFF")
    }
    
    /// Secondary text color
    static var adaptiveTextSecondary: Color {
        return adaptiveColor(light: "666666", dark: "AAAAAA")
    }
    
    /// Background color that adapts
    static var adaptiveBackground: Color {
        return adaptiveColor(light: "FAFAFA", dark: "1C1C1E")
    }
    
    /// Card background that adapts
    static var adaptiveCardBackground: Color {
        return adaptiveColor(light: "FFFFFF", dark: "2C2C2E")
    }
    
    /// Surface color for elevated elements
    static var adaptiveSurface: Color {
        return adaptiveColor(light: "FFFFFF", dark: "3A3A3C")
    }
    
    /// Border color that adapts
    static var adaptiveBorder: Color {
        return adaptiveColor(light: "E5E5E7", dark: "48484A")
    }
    
    /// Primary color optimized for dark mode
    static var adaptivePrimary: Color {
        return adaptiveColor(light: "2B564C", dark: "4A9B8E")
    }
    
    /// Accent color optimized for dark mode  
    static var adaptiveAccent: Color {
        return adaptiveColor(light: "28564C", dark: "4A9B8E")
    }
}

extension Color {
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

// MARK: - Mood Color Mapping

extension Color {
    static func moodColor(for moodName: String) -> Color {
        switch moodName {
        // New system (FirstCheckInView, sample data)
        case "Rough": return Color.red.opacity(0.6)
        case "Okay": return Color.orange.opacity(0.6)
        case "Neutral": return Color.gray.opacity(0.6)
        case "Good": return Color.blue.opacity(0.6)
        case "Great": return Color.green.opacity(0.6)
        
        // DaylioCheckInView system
        case "Awful": return Color.red.opacity(0.6)
        case "Bad": return Color.orange.opacity(0.6)
        case "Amazing": return Color.green.opacity(0.6)
        
        // Legacy emoji fallback (in case any old data exists)
        case "😢", "😞": return Color.red.opacity(0.6)
        case "😐": return Color.gray.opacity(0.6)
        case "😊": return Color.blue.opacity(0.6)
        case "😍", "🤩": return Color.green.opacity(0.6)
        
        default: return Color.gray.opacity(0.2)
        }
    }
} 