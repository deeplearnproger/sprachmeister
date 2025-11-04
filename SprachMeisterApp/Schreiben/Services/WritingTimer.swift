//
//  WritingTimer.swift
//  SprachMeister
//
//  Timer service for writing practice sessions
//  Created on 23.10.2025
//

import Foundation
import Combine

/// Timer for writing practice sessions with pause/resume support
@MainActor
class WritingTimer: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false

    // MARK: - Private Properties

    private var startDate: Date?
    private var pausedTime: TimeInterval = 0
    private var timer: Timer?
    private let timeLimitSeconds: TimeInterval?

    // Callback when time limit reached
    var onTimeLimitReached: (() -> Void)?

    // MARK: - Initialization

    init(timeLimitMinutes: Int? = nil) {
        self.timeLimitSeconds = timeLimitMinutes.map { TimeInterval($0 * 60) }
    }

    // MARK: - Public Methods

    /// Start the timer
    func start() {
        guard !isRunning else { return }

        startDate = Date()
        isRunning = true
        isPaused = false

        // Update timer every 0.5 seconds for smooth UI
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }

        print("⏱️ Timer started")
    }

    /// Pause the timer
    func pause() {
        guard isRunning, !isPaused else { return }

        isPaused = true
        pausedTime = elapsedTime

        timer?.invalidate()
        timer = nil

        print("⏸️ Timer paused at \(formattedTime)")
    }

    /// Resume the timer after pause
    func resume() {
        guard isPaused else { return }

        startDate = Date().addingTimeInterval(-pausedTime)
        isPaused = false

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }

        print("▶️ Timer resumed")
    }

    /// Stop the timer and return final time
    @discardableResult
    func stop() -> TimeInterval {
        timer?.invalidate()
        timer = nil

        isRunning = false
        isPaused = false

        let finalTime = elapsedTime
        print("⏹️ Timer stopped at \(formattedTime)")

        return finalTime
    }

    /// Reset the timer
    func reset() {
        stop()
        elapsedTime = 0
        pausedTime = 0
        startDate = nil
        print("🔄 Timer reset")
    }

    // MARK: - Private Methods

    private func updateElapsedTime() {
        guard let startDate = startDate, !isPaused else { return }

        elapsedTime = Date().timeIntervalSince(startDate)

        // Check if time limit reached
        if let limit = timeLimitSeconds, elapsedTime >= limit {
            stop()
            onTimeLimitReached?()
        }
    }

    // MARK: - Computed Properties

    /// Formatted time string (MM:SS)
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Formatted time with hours if needed (HH:MM:SS)
    var formattedTimeExtended: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Remaining time (if time limit set)
    var remainingTime: TimeInterval? {
        guard let limit = timeLimitSeconds else { return nil }
        return max(0, limit - elapsedTime)
    }

    /// Formatted remaining time
    var formattedRemainingTime: String? {
        guard let remaining = remainingTime else { return nil }

        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Progress (0.0 to 1.0) if time limit set
    var progress: Double? {
        guard let limit = timeLimitSeconds, limit > 0 else { return nil }
        let progress = elapsedTime / limit
        // Safety check for NaN
        guard !progress.isNaN && !progress.isInfinite else { return 0 }
        return min(1.0, max(0, progress))
    }

    /// Check if warning threshold reached (e.g., 5 minutes remaining)
    func isWarningThreshold(minutesRemaining: Int) -> Bool {
        guard let remaining = remainingTime else { return false }
        return remaining <= TimeInterval(minutesRemaining * 60) && remaining > 0
    }
}

// MARK: - Text Snapshot for Pace Analysis

/// Helper to capture text snapshots for pace analysis
@MainActor
class WritingPaceTracker: ObservableObject {

    struct Snapshot {
        let timestamp: TimeInterval
        let text: String
        let wordCount: Int
    }

    @Published private(set) var snapshots: [Snapshot] = []

    private let intervalSeconds: TimeInterval
    private var timer: Timer?
    private var textProvider: (() -> String)?

    init(intervalSeconds: TimeInterval = 30) {
        self.intervalSeconds = intervalSeconds
    }

    /// Start tracking with text provider closure
    func startTracking(textProvider: @escaping () -> String) {
        self.textProvider = textProvider
        snapshots = []

        // Capture initial snapshot
        captureSnapshot(at: 0)

        // Schedule periodic snapshots
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.captureSnapshot()
            }
        }
    }

    /// Stop tracking
    func stopTracking() {
        timer?.invalidate()
        timer = nil
    }

    /// Capture a snapshot
    func captureSnapshot(at timestamp: TimeInterval? = nil) {
        guard let text = textProvider?() else { return }

        let timestamp = timestamp ?? (snapshots.last?.timestamp ?? 0) + intervalSeconds
        let wordCount = WritingMetricsAnalyzer.countWords(in: text)

        snapshots.append(Snapshot(
            timestamp: timestamp,
            text: text,
            wordCount: wordCount
        ))
    }

    /// Get pace intervals for metrics
    func getPaceIntervals() -> [WritingMetrics.PaceInterval] {
        guard snapshots.count > 1 else { return [] }

        var intervals: [WritingMetrics.PaceInterval] = []
        var previousWordCount = 0

        for (index, snapshot) in snapshots.enumerated() {
            let wordsWritten = snapshot.wordCount - previousWordCount
            let intervalDuration = index == 0 ? snapshot.timestamp : intervalSeconds
            var wpm = intervalDuration > 0
                ? Double(wordsWritten) / (intervalDuration / 60.0)
                : 0.0

            // Safety check for NaN
            if wpm.isNaN || wpm.isInfinite {
                wpm = 0.0
            }

            intervals.append(WritingMetrics.PaceInterval(
                intervalStart: snapshot.timestamp,
                wordsWritten: wordsWritten,
                wordsPerMinute: wpm
            ))

            previousWordCount = snapshot.wordCount
        }

        return intervals
    }
}
