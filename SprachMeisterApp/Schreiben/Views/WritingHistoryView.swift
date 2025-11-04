//
//  WritingHistoryView.swift
//  SprachMeister
//
//  Premium history view with Design System
//  Created on 24.10.2025
//

import SwiftUI

/// Premium history view for writing attempts
struct WritingHistoryView: View {

    @ObservedObject var storage: WritingStorageService

    @State private var selectedFilter: WritingTaskType?
    @State private var selectedAttempt: WritingAttempt?
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var attemptToDelete: WritingAttempt?
    @State private var showingDeleteConfirmation = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.spacing.lg) {
                    // MARK: - Statistics Summary
                    if !storage.attempts.isEmpty {
                        DSCard(elevation: .medium) {
                            VStack(alignment: .leading, spacing: Theme.spacing.md) {
                                Label("Ihre Statistik", systemImage: "chart.xyaxis.line")
                                    .font(Theme.typography.titleMedium)
                                    .foregroundStyle(Color.primary)

                                Divider()

                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ],
                                    spacing: Theme.spacing.sm
                                ) {
                                    DSInfoTile(
                                        icon: "checkmark.circle.fill",
                                        value: "\(filteredAttempts.count)",
                                        label: "Versuche",
                                        iconColor: ColorPalette.fallbackSuccess
                                    )

                                    DSInfoTile(
                                        icon: "clock",
                                        value: formatTime(totalPracticeTime),
                                        label: "Gesamtzeit",
                                        iconColor: ColorPalette.fallbackPrimary
                                    )

                                    DSInfoTile(
                                        icon: "star.fill",
                                        value: averageScore.map { String(format: "%.1f", $0) } ?? "—",
                                        label: "Ø Bewertung",
                                        iconColor: ColorPalette.fallbackWarning
                                    )
                                }
                            }
                        }
                    }

                    // MARK: - Filter Picker
                    if !storage.attempts.isEmpty {
                        Picker("Filter", selection: $selectedFilter) {
                            Text("Alle").tag(nil as WritingTaskType?)
                            ForEach(WritingTaskType.allCases) { type in
                                Text(type.rawValue).tag(type as WritingTaskType?)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // MARK: - Attempts List
                    if filteredAttempts.isEmpty {
                        DSEmptyState(
                            icon: "tray",
                            title: "Noch keine Versuche",
                            message: selectedFilter != nil
                                ? "Keine Übungen für diesen Typ gefunden"
                                : "Ihre Übungen werden hier angezeigt",
                            actionTitle: nil,
                            action: nil
                        )
                        .padding(.vertical, Theme.spacing.xxxl)
                    } else {
                        VStack(spacing: Theme.spacing.md) {
                            ForEach(filteredAttempts) { attempt in
                                PremiumAttemptCard(
                                    attempt: attempt,
                                    onTap: {
                                        Theme.haptics.impactLight()
                                        selectedAttempt = attempt
                                    },
                                    onDelete: {
                                        attemptToDelete = attempt
                                        showingDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.spacing.lg)
                .padding(.vertical, Theme.spacing.lg)
            }
            .background(Theme.colors.background)
            .navigationTitle("Verlauf")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Theme.haptics.selection()
                        dismiss()
                    } label: {
                        Text("Fertig")
                            .foregroundStyle(ColorPalette.fallbackPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Theme.haptics.selection()
                            exportAllAttempts()
                        } label: {
                            Label("Alle exportieren", systemImage: "square.and.arrow.up")
                        }
                        .disabled(storage.attempts.isEmpty)

                        Divider()

                        Button(role: .destructive) {
                            storage.clearAllAttempts()
                            Theme.haptics.notifySuccess()
                        } label: {
                            Label("Alle löschen", systemImage: "trash")
                        }
                        .disabled(storage.attempts.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(ColorPalette.fallbackPrimary)
                    }
                }
            }
            .sheet(item: $selectedAttempt) { attempt in
                WritingResultView(attempt: attempt, storage: storage)
            }
            .sheet(isPresented: $showingExportSheet, onDismiss: {
                exportURL = nil
            }) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Versuch löschen?", isPresented: $showingDeleteConfirmation, presenting: attemptToDelete) { attempt in
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    storage.deleteAttempt(attempt)
                    Theme.haptics.notifySuccess()
                }
            } message: { attempt in
                Text("Möchten Sie die Übung \"\(attempt.task.topic)\" wirklich löschen?")
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredAttempts: [WritingAttempt] {
        let attempts = if let filter = selectedFilter {
            storage.attempts.filter { $0.task.type == filter }
        } else {
            storage.attempts
        }
        return attempts.sorted { $0.startedAt > $1.startedAt }
    }

    private var totalPracticeTime: TimeInterval {
        filteredAttempts.reduce(0) { $0 + $1.duration }
    }

    private var averageScore: Double? {
        let scores = filteredAttempts.compactMap { $0.evaluation?.scores.overall }
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    // MARK: - Actions

    private func exportAllAttempts() {
        do {
            let url = try ExportService.exportAttemptsToFile(storage.attempts)
            exportURL = url
            showingExportSheet = true
        } catch {
            print("❌ Export failed: \(error)")
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes))"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Premium Attempt Card

struct PremiumAttemptCard: View {
    let attempt: WritingAttempt
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            DSCard(elevation: .low) {
                HStack(spacing: Theme.spacing.md) {
                    // Score Circle
                    if let score = attempt.evaluation?.scores.overall {
                        ZStack {
                            Circle()
                                .stroke(scoreColor.opacity(0.2), lineWidth: 3)
                                .frame(width: 60, height: 60)

                            Circle()
                                .trim(from: 0, to: score / 5.0)
                                .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 2) {
                                Text(String(format: "%.1f", score))
                                    .font(Theme.typography.titleMedium)
                                    .fontWeight(.bold)
                                    .foregroundStyle(scoreColor)

                                Text("/ 5")
                                    .font(Theme.typography.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    } else {
                        Image(systemName: attempt.task.type.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(ColorPalette.fallbackPrimary)
                            .frame(width: 60, height: 60)
                            .background(ColorPalette.fallbackPrimary.opacity(0.12))
                            .clipShape(Circle())
                    }

                    // Content
                    VStack(alignment: .leading, spacing: Theme.spacing.xs) {
                        // Title with favorite star
                        HStack {
                            Text(attempt.task.topic)
                                .font(Theme.typography.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)

                            if attempt.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(ColorPalette.fallbackWarning)
                            }
                        }

                        // Type chip
                        DSChip(
                            icon: attempt.task.type.icon,
                            text: attempt.task.type.rawValue,
                            style: .info
                        )

                        // Metadata
                        HStack(spacing: Theme.spacing.xs) {
                            Label("\(attempt.metrics.wordCount)", systemImage: "text.word.spacing")
                            Text("•")
                            Label(formatDuration(attempt.duration), systemImage: "clock")
                            Text("•")
                            Text(attempt.formattedDate)
                        }
                        .font(Theme.typography.caption)
                        .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Actions
                    VStack(spacing: Theme.spacing.sm) {
                        Button {
                            Theme.haptics.selection()
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundStyle(ColorPalette.fallbackDanger)
                                .frame(width: 32, height: 32)
                                .background(ColorPalette.fallbackDanger.opacity(0.12))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
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

    private var scoreColor: Color {
        guard let score = attempt.evaluation?.scores.overall else {
            return ColorPalette.fallbackPrimary
        }

        if score >= 4.0 {
            return ColorPalette.fallbackSuccess
        } else if score >= 3.0 {
            return ColorPalette.fallbackWarning
        } else {
            return ColorPalette.fallbackDanger
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

#Preview("With History") {
    WritingHistoryView(storage: {
        let storage = WritingStorageService()
        // Add mock data for preview
        return storage
    }())
}

#Preview("Empty") {
    WritingHistoryView(storage: WritingStorageService())
}
