import SwiftUI

enum AppTheme {
    // Brand Backgrounds
    static let background = Color(hex: 0xFAF7F2)
    static let listCardBackground = Color(hex: 0xF4F0E8)
    static let inputBackground = Color(hex: 0xEEEAE1)
    static let buttonBackground = Color(hex: 0xFFFFFF)
    static let cardBorder = Color(hex: 0xECE7DE)
    
    // Text Colors
    static let textPrimary = Color(hex: 0x1E1B18)      // Deep charcoal/black
    static let textSecondary = Color(hex: 0x7E7872)    // Warm neutral gray
    static let textTertiary = Color(hex: 0xABA49D)     // Light mute gray
    
    // Accent Colors
    static let accent = Color(hex: 0xDF6B51)            // Warm terracotta orange
    static let accentLight = Color(hex: 0xF8EDE8)       // Soft peach for selected filter
    
    // Audio Button
    static let audioButtonBg = Color(hex: 0xFFFFFF)
    static let audioIcon = Color(hex: 0x5C544D)
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
