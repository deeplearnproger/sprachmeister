//
//  DSChip.swift
//  SprachMeister - Design System
//
//  Small status chips and tags
//  Created on 24.10.2025
//

import SwiftUI

struct DSChip: View {
    let icon: String?
    let text: String
    let style: ChipStyle

    enum ChipStyle {
        case neutral, primary, success, warning, info

        var backgroundColor: Color {
            switch self {
            case .neutral: return Color.gray.opacity(0.12)
            case .primary: return ColorPalette.fallbackPrimary.opacity(0.12)
            case .success: return ColorPalette.fallbackSuccess.opacity(0.12)
            case .warning: return ColorPalette.fallbackWarning.opacity(0.12)
            case .info: return ColorPalette.fallbackPrimary.opacity(0.08)
            }
        }

        var foregroundColor: Color {
            switch self {
            case .neutral: return Color.gray
            case .primary: return ColorPalette.fallbackPrimary
            case .success: return ColorPalette.fallbackSuccess
            case .warning: return ColorPalette.fallbackWarning
            case .info: return ColorPalette.fallbackPrimary
            }
        }
    }

    init(icon: String? = nil, text: String, style: ChipStyle = .neutral) {
        self.icon = icon
        self.text = text
        self.style = style
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .font(Theme.typography.labelSmall)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Theme.spacing.xs)
        .padding(.vertical, 5)
        .background(style.backgroundColor)
        .foregroundStyle(style.foregroundColor)
        .clipShape(Capsule())
    }
}

#Preview("Chips") {
    VStack(spacing: Theme.spacing.md) {
        HStack(spacing: Theme.spacing.xs) {
            DSChip(icon: "checkmark.circle.fill", text: "4 Punkte", style: .success)
            DSChip(icon: "clock", text: "30 Min", style: .neutral)
            DSChip(icon: "text.word.spacing", text: "180 Wörter", style: .info)
        }

        HStack(spacing: Theme.spacing.xs) {
            DSChip(text: "Teil 1", style: .primary)
            DSChip(text: "Forumsbeitrag", style: .neutral)
        }

        HStack(spacing: Theme.spacing.xs) {
            DSChip(icon: "exclamationmark.triangle", text: "Warnung", style: .warning)
            DSChip(icon: "checkmark", text: "Erfolgreich", style: .success)
        }
    }
    .padding()
    .background(Theme.colors.background)
}
