//
//  DSEmptyState.swift
//  SprachMeister - Design System
//
//  Empty state views with illustration and CTA
//  Created on 24.10.2025
//

import SwiftUI

struct DSEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Theme.spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            ColorPalette.fallbackPrimary,
                            ColorPalette.fallbackPrimary.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, Theme.spacing.md)

            // Title
            Text(title)
                .font(Theme.typography.headlineSmall)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(Theme.typography.bodyMedium)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacing.xxl)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                DSPrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 280)
                    .padding(.top, Theme.spacing.md)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview("Empty States") {
    TabView {
        DSEmptyState(
            icon: "doc.text.magnifyingglass",
            title: "Keine Versuche gefunden",
            message: "Sie haben noch keine Schreibübungen abgeschlossen. Beginnen Sie jetzt!",
            actionTitle: "Übung starten",
            action: { print("Start practice") }
        )
        .background(Theme.colors.background)

        DSEmptyState(
            icon: "folder",
            title: "Verlauf ist leer",
            message: "Ihre abgeschlossenen Übungen werden hier angezeigt.",
            actionTitle: nil,
            action: nil
        )
        .background(Theme.colors.background)

        DSEmptyState(
            icon: "magnifyingglass",
            title: "Keine Ergebnisse",
            message: "Versuchen Sie es mit anderen Suchbegriffen.",
            actionTitle: "Suche zurücksetzen",
            action: { print("Reset search") }
        )
        .background(Theme.colors.background)
    }
    .tabViewStyle(.page)
}
