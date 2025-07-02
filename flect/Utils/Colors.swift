import SwiftUI

extension Color {
    // Primary Colors (corrected hex values from design specs)
    static let primary = Color(hex: "2B564C") // Deep Blue
    static let accent = Color(hex: "28564C") // Soft Teal (corrected from 28564C4)
    static let background = Color(hex: "FAFAFA") // Off White (corrected from FAFAFFA)
    
    // Text Colors
    static let textMain = Color(hex: "111111") // Near Black
    static let mediumGrey = Color(hex: "666666") // Medium Grey (corrected from 6666)
    static let softRed = Color.red // Error color
    
    // Additional app colors
    static let cardBackground = Color.white
    static let borderColor = Color.gray.opacity(0.2)
    static let error = Color.red
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