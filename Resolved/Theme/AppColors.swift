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
        scheme == .dark ? .gray : Color(hex: "4b5563")  // Darker gray for better contrast
    }
    
    // MARK: - Borders & Dividers
    
    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color(hex: "e5e5ea")
    }
    
    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color(hex: "e5e5ea")
    }
    
    // MARK: - Accents
    
    static let accent = Color(hex: "e94560")
    static let accentLight = Color(hex: "ff6b6b")
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "e94560"), Color(hex: "ff6b6b")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Success green - darker in light mode for better contrast
    static func success(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "4ade80") : Color(hex: "16a34a")
    }
    
    static func successDark(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "22c55e") : Color(hex: "15803d")
    }
    
    static func successGradient(_ scheme: ColorScheme) -> LinearGradient {
        scheme == .dark
            ? LinearGradient(colors: [Color(hex: "4ade80"), Color(hex: "22c55e")], startPoint: .leading, endPoint: .trailing)
            : LinearGradient(colors: [Color(hex: "22c55e"), Color(hex: "16a34a")], startPoint: .leading, endPoint: .trailing)
    }
    
    // Gold - darker amber in light mode for better contrast
    static func gold(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "ffd700") : Color(hex: "d97706")
    }
    
    static func goldLight(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "ffaa00") : Color(hex: "b45309")
    }
    
    // MARK: - Opacity helpers for light mode contrast
    
    /// Returns appropriate opacity for borders/strokes - higher in light mode
    static func borderOpacity(_ scheme: ColorScheme, base: Double = 0.5) -> Double {
        scheme == .dark ? base : min(base + 0.3, 1.0)
    }
    
    /// Returns appropriate opacity for subtle backgrounds - higher in light mode  
    static func subtleBackgroundOpacity(_ scheme: ColorScheme, base: Double = 0.15) -> Double {
        scheme == .dark ? base : min(base + 0.1, 0.4)
    }
    
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
