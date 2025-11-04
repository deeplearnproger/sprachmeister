//
//  DSToast.swift
//  SprachMeister - Design System
//
//  Toast notifications with auto-dismiss
//  Created on 24.10.2025
//

import SwiftUI

// MARK: - Toast View

struct DSToast: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool

    enum ToastType {
        case success, warning, error, info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return ColorPalette.fallbackSuccess
            case .warning: return ColorPalette.fallbackWarning
            case .error: return ColorPalette.fallbackDanger
            case .info: return ColorPalette.fallbackPrimary
            }
        }
    }

    var body: some View {
        HStack(spacing: Theme.spacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundStyle(type.color)

            Text(message)
                .font(Theme.typography.bodyMedium)
                .foregroundStyle(Color.primary)

            Spacer(minLength: 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.radii.lg)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 16, y: 8)
        )
        .padding(.horizontal)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: DSToast.ToastType
    let duration: Double

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if isShowing {
                DSToast(message: message, type: type, isShowing: $isShowing)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        // Haptic feedback
                        switch type {
                        case .success:
                            Theme.haptics.notifySuccess()
                        case .warning:
                            Theme.haptics.notifyWarning()
                        case .error:
                            Theme.haptics.notifyError()
                        case .info:
                            Theme.haptics.impactLight()
                        }

                        // Auto-dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(Theme.motion.gentle) {
                                isShowing = false
                            }
                        }
                    }
            }
        }
        .animation(Theme.motion.springy, value: isShowing)
    }
}

extension View {
    func toast(
        isShowing: Binding<Bool>,
        message: String,
        type: DSToast.ToastType = .success,
        duration: Double = 2.5
    ) -> some View {
        modifier(ToastModifier(
            isShowing: isShowing,
            message: message,
            type: type,
            duration: duration
        ))
    }
}

// MARK: - Preview

#Preview("Toasts") {
    struct ToastPreview: View {
        @State private var showSuccess = false
        @State private var showWarning = false
        @State private var showError = false
        @State private var showInfo = false

        var body: some View {
            VStack(spacing: Theme.spacing.md) {
                DSPrimaryButton(title: "Success Toast") {
                    showSuccess = true
                }

                DSSecondaryButton(title: "Warning Toast") {
                    showWarning = true
                }

                DSSecondaryButton(title: "Error Toast") {
                    showError = true
                }

                DSSecondaryButton(title: "Info Toast") {
                    showInfo = true
                }
            }
            .padding()
            .toast(isShowing: $showSuccess, message: "Erfolgreich gespeichert!", type: .success)
            .toast(isShowing: $showWarning, message: "Warnung: Text zu kurz", type: .warning)
            .toast(isShowing: $showError, message: "Fehler beim Speichern", type: .error)
            .toast(isShowing: $showInfo, message: "Neue Version verfügbar", type: .info)
        }
    }

    return ToastPreview()
        .background(Theme.colors.background)
}
