//
//  WritingStorageService.swift
//  SprachMeister
//
//  Local storage for writing practice attempts
//  Created on 23.10.2025
//

import Foundation

/// Manages local persistence of writing attempts
@MainActor
class WritingStorageService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var attempts: [WritingAttempt] = []
    @Published private(set) var tasks: [WritingTask] = []

    // MARK: - Private Properties

    private let fileManager = FileManager.default
    private let storageURL: URL

    private var attemptsFileURL: URL {
        storageURL.appendingPathComponent("writing_attempts.json")
    }

    // MARK: - Initialization

    init() {
        // Get documents directory
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageURL = documentsURL.appendingPathComponent("SprachMeister", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)

        // Migrate old data from AITalkingApp folder if exists
        migrateOldDataIfNeeded(documentsURL: documentsURL)

        // Load existing attempts
        loadAttempts()

        // Load tasks from seed data
        loadTasks()
    }

    // MARK: - Task Management

    private func loadTasks() {
        tasks = WritingTask.loadTasks()
        print("📝 Loaded \(tasks.count) writing tasks")
    }

    func getTasks(for type: WritingTaskType) -> [WritingTask] {
        tasks.filter { $0.type == type }
    }

    // MARK: - Attempt Management

    /// Save a writing attempt
    func saveAttempt(_ attempt: WritingAttempt) {
        attempts.append(attempt)
        attempts.sort { $0.startedAt > $1.startedAt }
        persistAttempts()
        print("💾 Saved writing attempt: \(attempt.id)")
    }

    /// Update an existing attempt (e.g., to add evaluation)
    func updateAttempt(_ attempt: WritingAttempt) {
        if let index = attempts.firstIndex(where: { $0.id == attempt.id }) {
            attempts[index] = attempt
            persistAttempts()
            print("💾 Updated writing attempt: \(attempt.id)")
        }
    }

    /// Delete an attempt
    func deleteAttempt(_ attempt: WritingAttempt) {
        attempts.removeAll { $0.id == attempt.id }
        persistAttempts()
        print("🗑️ Deleted writing attempt: \(attempt.id)")
    }

    /// Toggle favorite status
    func toggleFavorite(_ attempt: WritingAttempt) {
        if let index = attempts.firstIndex(where: { $0.id == attempt.id }) {
            attempts[index].isFavorite.toggle()
            persistAttempts()
        }
    }

    /// Clear all attempts
    func clearAllAttempts() {
        attempts.removeAll()
        persistAttempts()
        print("🗑️ Cleared all writing attempts")
    }

    /// Get attempts for specific task type
    func getAttempts(for taskType: WritingTaskType) -> [WritingAttempt] {
        attempts.filter { $0.task.type == taskType }
    }

    /// Get favorite attempts
    var favoriteAttempts: [WritingAttempt] {
        attempts.filter { $0.isFavorite }
    }

    // MARK: - Statistics

    /// Get total practice time
    var totalPracticeTime: TimeInterval {
        attempts.reduce(0) { $0 + $1.duration }
    }

    /// Get average score
    var averageScore: Double? {
        let scoresWithEvaluation = attempts.compactMap { $0.evaluation?.scores.overall }
        guard !scoresWithEvaluation.isEmpty else { return nil }
        return scoresWithEvaluation.reduce(0, +) / Double(scoresWithEvaluation.count)
    }

    /// Get average word count
    var averageWordCount: Double {
        guard !attempts.isEmpty else { return 0 }
        let total = attempts.reduce(0) { $0 + $1.metrics.wordCount }
        return Double(total) / Double(attempts.count)
    }

    /// Get statistics by task type
    func getStatistics(for taskType: WritingTaskType) -> Statistics {
        let filtered = getAttempts(for: taskType)

        let totalAttempts = filtered.count
        let totalTime = filtered.reduce(0) { $0 + $1.duration }

        let scoresWithEvaluation = filtered.compactMap { $0.evaluation?.scores.overall }
        let avgScore = scoresWithEvaluation.isEmpty
            ? nil
            : scoresWithEvaluation.reduce(0, +) / Double(scoresWithEvaluation.count)

        let totalWords = filtered.reduce(0) { $0 + $1.metrics.wordCount }
        let avgWordCount = totalAttempts > 0 ? Double(totalWords) / Double(totalAttempts) : 0

        return Statistics(
            totalAttempts: totalAttempts,
            totalTime: totalTime,
            averageScore: avgScore,
            averageWordCount: avgWordCount
        )
    }

    struct Statistics {
        let totalAttempts: Int
        let totalTime: TimeInterval
        let averageScore: Double?
        let averageWordCount: Double
    }

    // MARK: - Private Methods

    /// Migrate old data from AITalkingApp folder to SprachMeister folder
    private func migrateOldDataIfNeeded(documentsURL: URL) {
        let oldStorageURL = documentsURL.appendingPathComponent("AITalkingApp", isDirectory: true)
        let oldAttemptsFile = oldStorageURL.appendingPathComponent("writing_attempts.json")

        // Check if old data exists and new data doesn't
        guard fileManager.fileExists(atPath: oldAttemptsFile.path),
              !fileManager.fileExists(atPath: attemptsFileURL.path) else {
            return
        }

        // Copy old data to new location
        do {
            try fileManager.copyItem(at: oldAttemptsFile, to: attemptsFileURL)
            print("✅ Migrated writing attempts from AITalkingApp to SprachMeister")

            // Optionally delete old folder
            try? fileManager.removeItem(at: oldStorageURL)
        } catch {
            print("⚠️ Failed to migrate old data: \(error)")
        }
    }

    private func loadAttempts() {
        guard fileManager.fileExists(atPath: attemptsFileURL.path) else {
            attempts = []
            return
        }

        do {
            let data = try Data(contentsOf: attemptsFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            attempts = try decoder.decode([WritingAttempt].self, from: data)
            print("📂 Loaded \(attempts.count) writing attempts")
        } catch {
            print("⚠️ Failed to load writing attempts: \(error)")
            // Try to delete corrupted file and start fresh
            try? fileManager.removeItem(at: attemptsFileURL)
            attempts = []
        }
    }

    private func persistAttempts() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(attempts)
            try data.write(to: attemptsFileURL)
        } catch {
            print("⚠️ Failed to save writing attempts: \(error)")
        }
    }
}
