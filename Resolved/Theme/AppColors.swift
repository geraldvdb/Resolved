//
//  AppColors.swift
//  Resolved
//
//  Centralized color system with light/dark mode support
//

import SwiftUI

struct AppColors {
    
    // MARK: - Backgrounds
    
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1a1a2e") : Color(hex: "f5f5f7")
    }
    
    static func backgroundGradientStart(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1a1a2e") : Color(hex: "f5f5f7")
    }
    
    static func backgroundGradientEnd(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "16213e") : Color(hex: "e8e8ed")
    }
    
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "16213e") : Color.white
    }
    
    static func cardBackgroundSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "16213e").opacity(0.8) : Color.white.opacity(0.95)
    }
    
    static func inputBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "16213e") : Color(hex: "f0f0f5")
    }
    
    // MARK: - Text
    
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(hex: "1a1a2e")
    }
    
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .gray : Color(hex: "6b7280")
    }
    
    // MARK: - Borders & Dividers
    
    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color(hex: "e5e5ea")
    }
    
    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color(hex: "e5e5ea")
    }
    
    // MARK: - Accents (same in both modes)
    
    static let accent = Color(hex: "e94560")
    static let accentLight = Color(hex: "ff6b6b")
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let success = Color(hex: "4ade80")
    static let successDark = Color(hex: "22c55e")
    static let successGradient = LinearGradient(
        colors: [Color(hex: "4ade80"), Color(hex: "22c55e")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let gold = Color(hex: "ffd700")
    static let goldLight = Color(hex: "ffaa00")
    
    // MARK: - Shadows
    
    static func cardShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    // MARK: - Progress/Grid
    
    static func emptyBlock(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1a1a2e") : Color(hex: "e5e5ea")
    }
    
    static func progressTrack(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1a1a2e") : Color(hex: "e5e5ea")
    }
}

// MARK: - Color Hex Extension

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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
