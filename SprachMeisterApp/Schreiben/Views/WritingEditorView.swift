//
//  WritingEditorView.swift
//  SprachMeister
//
//  Premium writing editor with Design System
//  Created on 24.10.2025
//

import SwiftUI

/// Premium writing editor view
struct WritingEditorView: View {

    let task: WritingTask
    @ObservedObject var storage: WritingStorageService

    @StateObject private var timer: WritingTimer
    @StateObject private var paceTracker = WritingPaceTracker(intervalSeconds: 30)

    @State private var text: String = ""
    @State private var isChecking = false
    @State private var showingResult = false
    @State private var currentAttempt: WritingAttempt?
    @State private var showingSubpoints = true
    @State private var showingEarlySubmitConfirmation = false
    @FocusState private var isTextEditorFocused: Bool

    @Environment(\.dismiss) private var dismiss

    init(task: WritingTask, storage: WritingStorageService) {
        self.task = task
        self.storage = storage
        _timer = StateObject(wrappedValue: WritingTimer(timeLimitMinutes: task.timeLimitMinutes))
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header with Timer
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.topic)
                        .font(Theme.typography.titleSmall)
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Text(task.type.rawValue)
                        .font(Theme.typography.caption)
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                // Timer Display
                HStack(spacing: 4) {
                    Image(systemName: timer.isRunning ? (timer.isPaused ? "pause.circle.fill" : "timer") : "clock")
                        .font(.system(size: 16))
                        .foregroundStyle(timerColor)

                    Text(timer.formattedTime)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(timerColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(timerColor.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.horizontal, Theme.spacing.lg)
            .padding(.vertical, Theme.spacing.md)
            .background(Theme.colors.surface)

            Divider()

            // MARK: - Word Counter
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "text.word.spacing")
                        .font(.system(size: 14))
                        .foregroundStyle(wordCountColor)

                    Text("\(wordCount)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(wordCountColor)

                    Text("/ \(task.type.recommendedWords)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                // Subpoints toggle button
                Button {
                    withAnimation(Theme.motion.springy) {
                        showingSubpoints.toggle()
                    }
                } label: {
                    ZStack {
                        Image(systemName: showingSubpoints ? "info.circle.fill" : "info.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(ColorPalette.fallbackPrimary)

                        // Badge indicator when hidden
                        if !showingSubpoints {
                            Circle()
                                .fill(ColorPalette.fallbackWarning)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.spacing.lg)
            .padding(.vertical, Theme.spacing.sm)
            .background(Theme.colors.surface)

            Divider()

            // MARK: - Subpoints Bar
            if showingSubpoints {
                VStack(spacing: Theme.spacing.xs) {
                    HStack {
                        Label("Beantworten Sie diese Punkte", systemImage: "checklist")
                            .font(Theme.typography.labelSmall)
                            .foregroundStyle(ColorPalette.fallbackPrimary)

                        Spacer()

                        Button {
                            withAnimation(Theme.motion.springy) {
                                showingSubpoints = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.secondary)
                        }
                    }

                    ForEach(Array(task.subpoints.enumerated()), id: \.offset) { index, point in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(Theme.typography.bodySmall)
                                .fontWeight(.semibold)
                                .foregroundStyle(ColorPalette.fallbackPrimary)

                            Text(point)
                                .font(Theme.typography.bodySmall)
                                .foregroundStyle(Color.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(Theme.spacing.sm)
                .background(ColorPalette.fallbackPrimary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radii.md))
                .padding(.horizontal, Theme.spacing.lg)
                .padding(.vertical, Theme.spacing.sm)
            }

            // MARK: - Text Editor
            TextEditor(text: $text)
                .font(Theme.typography.bodyMedium)
                .padding(Theme.spacing.md)
                .scrollContentBackground(.hidden)
                .background(Theme.colors.background)
                .focused($isTextEditorFocused)
                .onChange(of: text) { oldValue, newValue in
                    // Start timer when user begins typing
                    if !timer.isRunning && !newValue.isEmpty && oldValue.isEmpty {
                        timer.start()
                        paceTracker.startTracking { text }
                    }
                    // Resume timer if paused and user continues typing
                    else if timer.isPaused && newValue.count > oldValue.count {
                        timer.resume()
                    }
                }
                .onChange(of: isTextEditorFocused) { _, isFocused in
                    // Hide subpoints when keyboard opens (TextEditor is focused)
                    if isFocused && showingSubpoints {
                        withAnimation(Theme.motion.springy) {
                            showingSubpoints = false
                        }
                    }
                }

            Divider()

            // MARK: - Action Buttons
            HStack(spacing: Theme.spacing.sm) {
                // Pause/Resume button
                if timer.isRunning {
                    DSSecondaryButton(
                        title: timer.isPaused ? "Fortsetzen" : "Pause",
                        icon: timer.isPaused ? "play.fill" : "pause.fill"
                    ) {
                        if timer.isPaused {
                            timer.resume()
                        } else {
                            timer.pause()
                        }
                    }
                }

                // Submit button
                DSPrimaryButton(
                    title: canCheck ? "Prüfen" : "Vorzeitig abgeben",
                    icon: isChecking ? nil : "checkmark.circle.fill",
                    isLoading: isChecking
                ) {
                    // Show confirmation if submitting early
                    if !canCheck {
                        showingEarlySubmitConfirmation = true
                    } else {
                        checkWriting()
                    }
                }
                .disabled(isChecking || text.isEmpty)
            }
            .padding(Theme.spacing.lg)
            .background(Theme.colors.surface)
        }
        .navigationTitle(task.type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(timer.isRunning && !timer.isPaused)
        .alert("Vorzeitig abgeben?", isPresented: $showingEarlySubmitConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Jetzt abgeben", role: .destructive) {
                checkWriting()
            }
        } message: {
            Text("Sie haben noch nicht genug geschrieben (\(wordCount) von \(task.type.minWords) Wörtern).\n\nMöchten Sie Ihren Text trotzdem abgeben? Dies wird als Versuch gezählt.")
        }
        .sheet(isPresented: $showingResult) {
            if let attempt = currentAttempt {
                WritingResultView(attempt: attempt, storage: storage) {
                    // Dismiss the editor to return to task picker
                    dismiss()
                }
            }
        }
        .onDisappear {
            timer.stop()
            paceTracker.stopTracking()
        }
    }

    // MARK: - Computed Properties

    private var wordCount: Int {
        WritingMetricsAnalyzer.countWords(in: text)
    }

    private var canCheck: Bool {
        wordCount >= task.type.minWords * 70 / 100
    }

    private var timerColor: Color {
        if !timer.isRunning {
            return Color.secondary
        } else if let remaining = timer.remainingTime, remaining < 300 { // Less than 5 minutes
            return ColorPalette.fallbackDanger
        } else if let remaining = timer.remainingTime, remaining < 600 { // Less than 10 minutes
            return ColorPalette.fallbackWarning
        } else {
            return ColorPalette.fallbackSuccess
        }
    }

    private var wordCountColor: Color {
        if wordCount < task.type.minWords {
            return ColorPalette.fallbackDanger
        } else if wordCount > task.type.maxWords {
            return ColorPalette.fallbackWarning
        } else {
            return ColorPalette.fallbackSuccess
        }
    }

    // MARK: - Actions

    private func checkWriting() {
        guard !text.isEmpty else { return }

        isChecking = true
        timer.stop()
        paceTracker.stopTracking()

        Task {
            do {
                let metrics = WritingMetricsAnalyzer.generateMetrics(
                    attemptID: UUID(),
                    task: task,
                    text: text,
                    writingPace: paceTracker.getPaceIntervals()
                )

                let checker = OpenRouterChecker(apiKey: Config.openRouterAPIKey)
                let evaluation = try await checker.checkWriting(task: task, text: text, metrics: metrics)

                let attempt = WritingAttempt(
                    task: task,
                    text: text,
                    duration: timer.elapsedTime,
                    metrics: metrics,
                    evaluation: evaluation
                )

                storage.saveAttempt(attempt)

                await MainActor.run {
                    currentAttempt = attempt
                    isChecking = false
                    showingResult = true
                }
            } catch {
                print("❌ Check error: \(error)")

                let metrics = WritingMetricsAnalyzer.generateMetrics(
                    attemptID: UUID(),
                    task: task,
                    text: text,
                    writingPace: paceTracker.getPaceIntervals()
                )

                let attempt = WritingAttempt(
                    task: task,
                    text: text,
                    duration: timer.elapsedTime,
                    metrics: metrics,
                    evaluation: nil
                )

                storage.saveAttempt(attempt)

                await MainActor.run {
                    currentAttempt = attempt
                    isChecking = false
                    showingResult = true
                }
            }
        }
    }
}

#Preview("Writing Editor") {
    NavigationStack {
        WritingEditorView(
            task: WritingTask(
                type: .email,
                topic: "Einladung ablehnen",
                situation: "Test situation",
                subpoints: ["Punkt 1", "Punkt 2", "Punkt 3"],
                hints: nil,
                timeLimitMinutes: 25
            ),
            storage: WritingStorageService()
        )
    }
}
