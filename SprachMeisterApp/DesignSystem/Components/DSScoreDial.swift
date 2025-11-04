//
//  DSScoreDial.swift
//  SprachMeister - Design System
//
//  Circular score indicator (0-5) with smooth animations
//  Created on 24.10.2025
//

import SwiftUI

struct DSScoreDial: View {
    let score: Double // 0-5
    let title: String
    let subtitle: String?

    @State private var animatedProgress: Double = 0

    init(score: Double, title: String, subtitle: String? = nil) {
        // Clamp score to valid range and check for NaN
        let validScore = score.isNaN || score.isInfinite ? 0 : score
        self.score = max(0, min(5, validScore))
        self.title = title
        self.subtitle = subtitle
    }

    private var normalizedScore: Double {
        let normalized = score / 5.0
        return normalized.isNaN || normalized.isInfinite ? 0 : max(0, min(1, normalized))
    }

    private var color: Color {
        switch score {
        case 4.5...: return ColorPalette.fallbackSuccess
        case 3.5..<4.5: return ColorPalette.fallbackPrimary
        case 2.5..<3.5: return ColorPalette.fallbackWarning
        default: return ColorPalette.fallbackDanger
        }
    }

    private var levelText: String {
        switch score {
        case 4.5...: return "Ausgezeichnet"
        case 3.5..<4.5: return "Gut"
        case 2.5..<3.5: return "Befriedigend"
        case 1.5..<2.5: return "Ausreichend"
        default: return "Unzureichend"
        }
    }

    var body: some View {
        VStack(spacing: Theme.spacing.lg) {
            // Circular progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        Color.gray.opacity(0.15),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)

                // Progress circle with animation
                Circle()
                    .trim(from: 0, to: max(0, min(1, animatedProgress.isNaN ? 0 : animatedProgress)))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                // Score in center
                VStack(spacing: 6) {
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(color)

                    Text("/ 5.0")
                        .font(Theme.typography.caption)
                        .foregroundStyle(Color.gray)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title): \(String(format: "%.1f", score)) von 5 Punkten")
            .accessibilityValue(levelText)

            // Title and level
            VStack(spacing: 4) {
                Text(title)
                    .font(Theme.typography.titleMedium)
                    .foregroundStyle(Color.primary)

                Text(levelText)
                    .font(Theme.typography.labelMedium)
                    .foregroundStyle(color)
                    .padding(.horizontal, Theme.spacing.sm)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.1))
                    .clipShape(Capsule())

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Theme.typography.bodySmall)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedProgress = normalizedScore
            }

            // Haptic feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if score >= 4.0 {
                    Theme.haptics.notifySuccess()
                } else if score >= 2.5 {
                    Theme.haptics.impactMedium()
                } else {
                    Theme.haptics.notifyWarning()
                }
            }
        }
    }
}

#Preview("Score Dials") {
    VStack(spacing: Theme.spacing.xxl) {
        DSScoreDial(
            score: 4.8,
            title: "Gesamtbewertung",
            subtitle: "Sehr gute Leistung!"
        )

        DSScoreDial(
            score: 3.2,
            title: "Aufgabenerfüllung"
        )

        DSScoreDial(
            score: 2.1,
            title: "Strukturen",
            subtitle: "Mehr Übung erforderlich"
        )
    }
    .padding()
    .background(Theme.colors.background)
}
