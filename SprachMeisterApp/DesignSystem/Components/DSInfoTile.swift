//
//  DSInfoTile.swift
//  SprachMeister - Design System
//
//  Info tiles for displaying metrics (icon + value + label)
//  Created on 24.10.2025
//

import SwiftUI

struct DSInfoTile: View {
    let icon: String
    let value: String
    let label: String
    let iconColor: Color

    init(
        icon: String,
        value: String,
        label: String,
        iconColor: Color = ColorPalette.fallbackPrimary
    ) {
        self.icon = icon
        self.value = value
        self.label = label
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(spacing: Theme.spacing.xs) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)
                .frame(height: 32)

            // Value
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)

            // Label
            Text(label)
                .font(Theme.typography.caption)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacing.md)
        .padding(.horizontal, Theme.spacing.sm)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radii.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview("Info Tiles") {
    VStack(spacing: Theme.spacing.lg) {
        // Grid of metrics
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: Theme.spacing.sm
        ) {
            DSInfoTile(
                icon: "text.word.spacing",
                value: "180",
                label: "Wörter",
                iconColor: ColorPalette.fallbackPrimary
            )

            DSInfoTile(
                icon: "textformat.size",
                value: "12",
                label: "Sätze",
                iconColor: ColorPalette.fallbackSecondary
            )

            DSInfoTile(
                icon: "clock",
                value: "25:30",
                label: "Dauer",
                iconColor: ColorPalette.fallbackWarning
            )

            DSInfoTile(
                icon: "speedometer",
                value: "7.1",
                label: "Wörter/Min",
                iconColor: .blue
            )

            DSInfoTile(
                icon: "chart.bar",
                value: "0.68",
                label: "TTR",
                iconColor: .purple
            )

            DSInfoTile(
                icon: "graduationcap",
                value: "B1",
                label: "Niveau",
                iconColor: ColorPalette.fallbackSuccess
            )
        }
    }
    .padding()
    .background(Theme.colors.background)
}
