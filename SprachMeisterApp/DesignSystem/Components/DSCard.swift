//
//  DSCard.swift
//  SprachMeister - Design System
//
//  Premium card component with elevation and animations
//  Created on 24.10.2025
//

import SwiftUI

/// Premium card component with consistent styling and elevation
struct DSCard<Content: View>: View {
    let content: Content
    let elevation: Elevation
    let padding: CGFloat

    enum Elevation {
        case none, low, medium, high

        var shadow: ShadowStyle {
            switch self {
            case .none: return Theme.shadows.elevation1
            case .low: return Theme.shadows.elevation2
            case .medium: return Theme.shadows.elevation3
            case .high: return Theme.shadows.elevation4
            }
        }
    }

    init(
        elevation: Elevation = .medium,
        padding: CGFloat = Theme.spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.elevation = elevation
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(Theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radii.xl))
            .shadow(
                color: elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: elevation.shadow.x,
                y: elevation.shadow.y
            )
    }
}

#Preview("Card Examples") {
    VStack(spacing: Theme.spacing.lg) {
        DSCard(elevation: .low) {
            Text("Low Elevation Card")
                .font(Theme.typography.bodyLarge)
        }

        DSCard(elevation: .medium) {
            VStack(alignment: .leading, spacing: Theme.spacing.sm) {
                Text("Medium Elevation")
                    .font(Theme.typography.titleMedium)
                Text("With more content")
                    .font(Theme.typography.bodyMedium)
                    .foregroundStyle(Theme.colors.textSecondary)
            }
        }

        DSCard(elevation: .high) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(ColorPalette.fallbackWarning)
                Text("High Elevation")
                    .font(Theme.typography.titleLarge)
            }
        }
    }
    .padding()
    .background(Theme.colors.background)
}
