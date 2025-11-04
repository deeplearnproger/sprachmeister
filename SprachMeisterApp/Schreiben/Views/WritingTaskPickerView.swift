//
//  WritingTaskPickerView.swift
//  SprachMeister
//
//  Premium task picker with Design System
//  Created on 24.10.2025
//

import SwiftUI

/// Premium task picker for writing practice
struct WritingTaskPickerView: View {

    @StateObject private var storage = WritingStorageService()
    @State private var selectedTask: WritingTask?
    @State private var showingHistory = false
    @State private var selectedType: WritingTaskType = .forumPost

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.spacing.lg) {
                // MARK: - Statistics Dashboard
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
                                value: "\(storage.attempts.count)",
                                label: "Versuche",
                                iconColor: ColorPalette.fallbackSuccess
                            )

                            DSInfoTile(
                                icon: "clock",
                                value: formatTime(storage.totalPracticeTime),
                                label: "Gesamtzeit",
                                iconColor: ColorPalette.fallbackPrimary
                            )

                            DSInfoTile(
                                icon: "star.fill",
                                value: storage.averageScore.map { String(format: "%.1f", $0) } ?? "—",
                                label: "Ø Bewertung",
                                iconColor: ColorPalette.fallbackWarning
                            )
                        }
                    }
                }

                // MARK: - Task Type Picker
                Picker("Aufgabentyp", selection: $selectedType) {
                    ForEach(WritingTaskType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.spacing.lg)

                // MARK: - Tasks for selected type
                let tasks = storage.getTasks(for: selectedType)
                if tasks.isEmpty {
                    DSEmptyState(
                        icon: "doc.text.magnifyingglass",
                        title: "Keine Aufgaben verfügbar",
                        message: "Für diesen Aufgabentyp sind momentan keine Übungen verfügbar.",
                        actionTitle: nil,
                        action: nil
                    )
                    .padding(.vertical, Theme.spacing.xxxl)
                } else {
                    VStack(spacing: Theme.spacing.md) {
                        ForEach(tasks) { task in
                            TaskCard(task: task, storage: storage)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.spacing.lg)
            .padding(.vertical, Theme.spacing.lg)
        }
        .background(Theme.colors.background)
        .navigationTitle("Schreiben Üben")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Theme.haptics.selection()
                    showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(ColorPalette.fallbackPrimary)
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            WritingHistoryView(storage: storage)
        }
        .environmentObject(storage)
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

// MARK: - Task Card

struct TaskCard: View {
    let task: WritingTask
    @ObservedObject var storage: WritingStorageService

    @State private var navigateToEditor = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            Theme.haptics.impactLight()
            navigateToEditor = true
        }) {
            DSCard(elevation: .low) {
                VStack(alignment: .leading, spacing: Theme.spacing.md) {
                    // Header
                    HStack {
                        Image(systemName: task.type.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(ColorPalette.fallbackPrimary)
                            .frame(width: 40, height: 40)
                            .background(ColorPalette.fallbackPrimary.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.topic)
                                .font(Theme.typography.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.primary)

                            Text(task.type.rawValue)
                                .font(Theme.typography.caption)
                                .foregroundStyle(Color.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }

                    // Metadata chips
                    HStack(spacing: Theme.spacing.xs) {
                        DSChip(
                            icon: "clock",
                            text: "\(task.timeLimitMinutes) Min",
                            style: .neutral
                        )

                        DSChip(
                            icon: "text.word.spacing",
                            text: "\(task.type.minWords)+ Wörter",
                            style: .neutral
                        )

                        DSChip(
                            icon: "list.bullet",
                            text: "\(task.subpoints.count) Punkte",
                            style: .info
                        )

                        Spacer()
                    }

                    // Attempts count
                    let attempts = storage.attempts.filter { $0.task.id == task.id }
                    if !attempts.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(ColorPalette.fallbackSuccess)

                            Text("\(attempts.count) Versuche")
                                .font(Theme.typography.caption)
                                .foregroundStyle(Color.secondary)
                        }
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
        .navigationDestination(isPresented: $navigateToEditor) {
            WritingEditorView(task: task, storage: storage)
        }
    }
}

#Preview("Task Picker") {
    NavigationStack {
        WritingTaskPickerView()
    }
}
