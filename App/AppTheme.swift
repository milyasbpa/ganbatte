import SwiftUI

enum AppTheme {
    // Brand Backgrounds
    static let background = Color(hex: 0xFAF7F2)
    static let listCardBackground = Color(hex: 0xF4F0E8)
    static let inputBackground = Color(hex: 0xEEEAE1)
    
    // Buttons & Borders
    static let buttonBackground = Color(hex: 0xFFFFFF)
    static let buttonBorder = Color(hex: 0xE6E1D7)
    static let buttonDisabledText = Color(hex: 0xC4BFB8)
    static let cardBorder = Color(hex: 0xECE7DE)
    
    // Text Colors
    static let textPrimary = Color(hex: 0x1E1B18)      // Deep charcoal/black
    static let textSecondary = Color(hex: 0x8A857F)    // Warm neutral gray
    static let textTertiary = Color(hex: 0xABA49D)     // Light mute gray
    
    // Accent Colors
    static let accent = Color(hex: 0xDF6B51)            // Warm terracotta orange
    static let accentLight = Color(hex: 0xF8EDE8)       // Soft peach for selected filter
    
    // Audio Button (Matching card_001.png: #787773 icon with #E6E1D7 border)
    static let audioButtonBg = Color(hex: 0xFFFFFF)
    static let audioButtonBorder = Color(hex: 0xE6E1D7)
    static let audioIcon = Color(hex: 0x787773)
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
