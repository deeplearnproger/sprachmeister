//
//  DSProgressBar.swift
//  SprachMeister - Design System
//
//  Accessible progress bars for scores
//  Created on 24.10.2025
//

import SwiftUI

struct DSProgressBar: View {
    let title: String
    let value: Double // 0-5
    let maxValue: Double

    @State private var animatedValue: Double = 0

    init(title: String, value: Double, maxValue: Double = 5.0) {
        self.title = title
        self.value = max(0, min(maxValue, value))
        self.maxValue = maxValue
    }

    private var normalizedValue: Double {
        guard maxValue > 0 else { return 0 }
        let normalized = value / maxValue
        return normalized.isNaN || normalized.isInfinite ? 0 : normalized
    }

    private var color: Color {
        switch value {
        case 4.5...: return ColorPalette.fallbackSuccess
        case 3.5..<4.5: return ColorPalette.fallbackPrimary
        case 2.5..<3.5: return ColorPalette.fallbackWarning
        default: return ColorPalette.fallbackDanger
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing.xs) {
            // Title and score
            HStack {
                Text(title)
                    .font(Theme.typography.titleSmall)
                    .foregroundStyle(Color.primary)

                Spacer()

                Text(String(format: "%.1f / %.0f", value, maxValue))
                    .font(Theme.typography.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: Theme.radii.xs)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 8)

                    // Foreground with animation
                    RoundedRectangle(cornerRadius: Theme.radii.xs)
                        .fill(color)
                        .frame(width: calculateWidth(geometry: geometry), height: 8)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(String(format: "%.1f", value)) von \(String(format: "%.0f", maxValue)) Punkten")
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedValue = normalizedValue
            }
        }
    }

    private func calculateWidth(geometry: GeometryProxy) -> CGFloat {
        let width = geometry.size.width * animatedValue

        // Safety check for NaN/Infinite
        if width.isNaN || width.isInfinite {
            return 0
        }

        return max(0, min(geometry.size.width, width))
    }
}

#Preview("Progress Bars") {
    VStack(spacing: Theme.spacing.lg) {
        DSCard {
            VStack(spacing: Theme.spacing.md) {
                DSProgressBar(title: "Aufgabenerfüllung", value: 4.5)
                DSProgressBar(title: "Kohärenz", value: 3.8)
                DSProgressBar(title: "Wortschatz", value: 3.2)
                DSProgressBar(title: "Strukturen", value: 2.5)
            }
        }
    }
    .padding()
    .background(Theme.colors.background)
}
