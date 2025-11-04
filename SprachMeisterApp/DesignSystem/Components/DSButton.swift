//
//  DSButton.swift
//  SprachMeister - Design System
//
//  Premium button components with haptics and animations
//  Created on 24.10.2025
//

import SwiftUI

// MARK: - Primary Button

struct DSPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard !isDisabled && !isLoading else { return }
            Theme.haptics.impactLight()
            action()
        }) {
            HStack(spacing: Theme.spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(Theme.typography.labelLarge)
                    }
                    Text(title)
                        .font(Theme.typography.labelLarge)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isDisabled
                    ? Color.gray.opacity(0.3)
                    : ColorPalette.fallbackPrimary
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radii.lg))
            .shadow(
                color: isDisabled ? .clear : Color.black.opacity(0.1),
                radius: 8,
                y: 4
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(Theme.motion.springy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDisabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Secondary Button

struct DSSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @State private var isPressed = false

    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            Theme.haptics.selection()
            action()
        }) {
            HStack(spacing: Theme.spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(Theme.typography.labelLarge)
                }
                Text(title)
                    .font(Theme.typography.labelLarge)
            }
            .foregroundStyle(ColorPalette.fallbackPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(ColorPalette.fallbackPrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radii.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radii.lg)
                    .stroke(ColorPalette.fallbackPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(Theme.motion.springy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Icon Button

struct DSIconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: {
            Theme.haptics.selection()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45))
                .foregroundStyle(ColorPalette.fallbackPrimary)
                .frame(width: size, height: size)
                .background(ColorPalette.fallbackPrimary.opacity(0.1))
                .clipShape(Circle())
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(Theme.motion.springy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: Theme.spacing.lg) {
        DSPrimaryButton(title: "Prüfen", icon: "checkmark.circle.fill") {
            print("Primary tapped")
        }

        DSPrimaryButton(title: "Wird geladen...", isLoading: true) {
            print("Loading")
        }

        DSPrimaryButton(title: "Deaktiviert", isDisabled: true) {
            print("Disabled")
        }

        DSSecondaryButton(title: "Abbrechen", icon: "xmark") {
            print("Secondary tapped")
        }

        HStack(spacing: Theme.spacing.md) {
            DSIconButton(icon: "star.fill") {
                print("Star")
            }
            DSIconButton(icon: "square.and.arrow.up") {
                print("Share")
            }
            DSIconButton(icon: "trash") {
                print("Delete")
            }
        }
    }
    .padding()
    .background(Theme.colors.background)
}
