//
//  Theme.swift
//  SprachMeister - Design System
//
//  Central source of truth for all design tokens
//  Created on 24.10.2025
//

import SwiftUI

/// Central theme manager - single source of truth for all design tokens
struct Theme {

    // MARK: - Colors

    static let colors = ColorPalette()

    // MARK: - Typography

    static let typography = Typography()

    // MARK: - Spacing

    static let spacing = Spacing()

    // MARK: - Radii

    static let radii = Radii()

    // MARK: - Shadows

    static let shadows = Shadows()

    // MARK: - Motion

    static let motion = Motion()

    // MARK: - Haptics

    static let haptics = Haptics()
}

// MARK: - Color Palette

struct ColorPalette {
    // Using system colors for Light/Dark mode support

    // Neutrals - System colors
    let background = Color(UIColor.systemBackground)
    let surface = Color(UIColor.secondarySystemBackground)
    let surfaceElevated = Color(UIColor.tertiarySystemBackground)
    let border = Color(UIColor.separator)
    let divider = Color(UIColor.separator)

    // Text - System colors
    let textPrimary = Color(UIColor.label)
    let textSecondary = Color(UIColor.secondaryLabel)
    let textTertiary = Color(UIColor.tertiaryLabel)
    let textDisabled = Color(UIColor.quaternaryLabel)

    // Brand colors - using fallbacks directly since Assets not configured
    static let fallbackPrimary = Color(hex: "#3B82F6")      // Blue
    static let fallbackSecondary = Color(hex: "#22C55E")    // Green
    static let fallbackSuccess = Color(hex: "#10B981")      // Emerald
    static let fallbackWarning = Color(hex: "#F59E0B")      // Amber
    static let fallbackDanger = Color(hex: "#EF4444")       // Red
}

// MARK: - Typography

struct Typography {
    // Display
    let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
    let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
    let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)

    // Headline
    let headlineLarge = Font.system(size: 32, weight: .semibold, design: .default)
    let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)
    let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)

    // Title
    let titleLarge = Font.system(size: 22, weight: .medium, design: .default)
    let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
    let titleSmall = Font.system(size: 14, weight: .medium, design: .default)

    // Body
    let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    // Label
    let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // Caption
    let caption = Font.system(size: 12, weight: .regular, design: .default)
    let captionEmphasized = Font.system(size: 12, weight: .semibold, design: .default)
}

// MARK: - Spacing

struct Spacing {
    let xxs: CGFloat = 4
    let xs: CGFloat = 8
    let sm: CGFloat = 12
    let md: CGFloat = 16
    let lg: CGFloat = 20
    let xl: CGFloat = 24
    let xxl: CGFloat = 32
    let xxxl: CGFloat = 48
}

// MARK: - Radii

struct Radii {
    let xs: CGFloat = 4
    let sm: CGFloat = 8
    let md: CGFloat = 12
    let lg: CGFloat = 16
    let xl: CGFloat = 20
    let xxl: CGFloat = 24
    let full: CGFloat = 9999
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Shadows

struct Shadows {
    let elevation1 = ShadowStyle(
        color: Color.black.opacity(0.05),
        radius: 2,
        x: 0,
        y: 1
    )

    let elevation2 = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 4,
        x: 0,
        y: 2
    )

    let elevation3 = ShadowStyle(
        color: Color.black.opacity(0.10),
        radius: 8,
        x: 0,
        y: 4
    )

    let elevation4 = ShadowStyle(
        color: Color.black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 8
    )
}

// MARK: - Motion

struct Motion {
    // Durations
    let instant: Double = 0.1
    let fast: Double = 0.2
    let normal: Double = 0.3
    let slow: Double = 0.5

    // Springs
    let springy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    let bouncy = Animation.spring(response: 0.35, dampingFraction: 0.6)
    let smooth = Animation.easeInOut(duration: 0.3)
    let gentle = Animation.easeOut(duration: 0.4)
}

// MARK: - Haptics

struct Haptics {
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    func impactLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func impactMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func impactHeavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func notifySuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func notifyWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    func notifyError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Color Extension (Hex Support)

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
            (a, r, g, b) = (255, 0, 0, 0)
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
