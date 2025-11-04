//
//  ModePickerView.swift
//  SprachMeister
//
//  Premium redesigned home screen with Design System
//  Created on 24.10.2025
//

import SwiftUI

/// Main mode picker (Sprechen vs Schreiben) - Premium Design
struct ModePickerView: View {

    enum PracticeMode: String, CaseIterable, Identifiable, Hashable {
        case sprechen = "Sprechen"
        case schreiben = "Schreiben"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .sprechen: return "mic.fill"
            case .schreiben: return "pencil.and.list.clipboard"
            }
        }

        var subtitle: String {
            switch self {
            case .sprechen:
                return "Dialoge führen und Feedback erhalten"
            case .schreiben:
                return "Texte verfassen und bewerten lassen"
            }
        }

        var color: Color {
            switch self {
            case .sprechen: return ColorPalette.fallbackPrimary
            case .schreiben: return ColorPalette.fallbackSecondary
            }
        }
    }

    @State private var selectedMode: PracticeMode?
    @State private var showComingSoonAlert = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.spacing.xxxl) {
                    // MARK: - Hero Section
                    VStack(spacing: Theme.spacing.md) {
                        // App Icon
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        ColorPalette.fallbackPrimary,
                                        ColorPalette.fallbackPrimary.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, Theme.spacing.xxl)

                        // Title
                        Text("SprachMeister")
                            .font(Theme.typography.displaySmall)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primary)

                        // Subtitle
                        Text("Ihr persönlicher Tutor für die Prüfungsvorbereitung")
                            .font(Theme.typography.bodyMedium)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacing.xl)
                    }

                    // MARK: - Mode Cards
                    VStack(spacing: Theme.spacing.md) {
                        ForEach(PracticeMode.allCases) { mode in
                            ModeTappableCard(mode: mode) {
                                if mode == .sprechen {
                                    showComingSoonAlert = true
                                } else {
                                    selectedMode = mode
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spacing.lg)

                    // MARK: - Privacy Note
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("Alle Daten bleiben auf Ihrem Gerät")
                            .font(Theme.typography.caption)
                    }
                    .foregroundStyle(Color.secondary)
                    .padding(.bottom, Theme.spacing.xl)
                }
            }
            .background(Theme.colors.background)
            .navigationDestination(item: $selectedMode) { mode in
                switch mode {
                case .sprechen:
                    ScenarioPicker()
                case .schreiben:
                    WritingTaskPickerView()
                }
            }
            .alert("In Entwicklung", isPresented: $showComingSoonAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Die Sprechen-Funktion befindet sich derzeit in Entwicklung.\n\nBald verfügbar! Wir arbeiten daran, Ihnen das beste Lernerlebnis zu bieten.")
            }
        }
    }
}

// MARK: - Premium Mode Card with Animations

struct ModeTappableCard: View {
    let mode: ModePickerView.PracticeMode
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            Theme.haptics.selection()
            action()
        }) {
            HStack(spacing: Theme.spacing.lg) {
                // Icon with background
                Image(systemName: mode.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(mode.color)
                    .frame(width: 72, height: 72)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radii.lg)
                            .fill(mode.color.opacity(0.12))
                    )

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.rawValue)
                        .font(Theme.typography.titleLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)

                    Text(mode.subtitle)
                        .font(Theme.typography.bodySmall)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(Theme.spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radii.xl))
            .shadow(
                color: Color.black.opacity(isPressed ? 0.06 : 0.10),
                radius: isPressed ? 6 : 12,
                y: isPressed ? 3 : 6
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.motion.springy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    ModePickerView()
}
