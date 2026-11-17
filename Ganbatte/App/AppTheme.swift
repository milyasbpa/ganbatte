import SwiftUI

enum AppTheme {
    // Brand Colors
    static let background = Color(hex: 0xFAF7F2)
    static let cardBackground = Color(hex: 0xFFFFFF)
    static let cardBorder = Color(hex: 0xECE7DE)
    static let inputBackground = Color(hex: 0xEFEBE3)
    
    // Text Colors
    static let textPrimary = Color(hex: 0x2A2521)
    static let textSecondary = Color(hex: 0x827A73)
    static let textTertiary = Color(hex: 0xADA59D)
    
    // Accent Colors
    static let accent = Color(hex: 0xD6633E)
    static let accentLight = Color(hex: 0xF7EDE8)
    
    // Card Button
    static let audioButtonBg = Color(hex: 0xF7F4EE)
    static let audioIcon = Color(hex: 0x484039)
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
