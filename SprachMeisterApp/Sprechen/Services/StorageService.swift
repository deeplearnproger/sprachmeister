//
//  StorageService.swift
//  SprachMeister
//
//  Local storage for practice attempts
//  Created on 20.10.2025
//

import Foundation

/// Manages local persistence of practice attempts
@MainActor
class StorageService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var attempts: [PracticeAttempt] = []

    // MARK: - Private Properties

    private let fileManager = FileManager.default
    private let storageURL: URL

    private var attemptsFileURL: URL {
        storageURL.appendingPathComponent("attempts.json")
    }

    // MARK: - Initialization

    init() {
        // Get documents directory
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageURL = documentsURL.appendingPathComponent("AITalkingApp", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: storageURL, withIntermediateDirectories: true)

        // Load existing attempts
        loadAttempts()
    }

    // MARK: - Public Methods

    /// Save a practice attempt
    func saveAttempt(_ attempt: PracticeAttempt) {
        attempts.append(attempt)
        attempts.sort { $0.createdAt > $1.createdAt }
        persistAttempts()
    }

    /// Delete an attempt
    func deleteAttempt(_ attempt: PracticeAttempt) {
        attempts.removeAll { $0.id == attempt.id }

        // Delete associated audio files
        if let audioURLs = attempt.transcript.entries.compactMap({ $0.audioURL }) as [URL]? {
            for url in audioURLs {
                try? fileManager.removeItem(at: url)
            }
        }

        persistAttempts()
    }

    /// Toggle favorite status
    func toggleFavorite(_ attempt: PracticeAttempt) {
        if let index = attempts.firstIndex(where: { $0.id == attempt.id }) {
            attempts[index].isFavorite.toggle()
            persistAttempts()
        }
    }

    /// Clear all attempts
    func clearAllAttempts() {
        // Delete all audio files
        for attempt in attempts {
            if let audioURLs = attempt.transcript.entries.compactMap({ $0.audioURL }) as [URL]? {
                for url in audioURLs {
                    try? fileManager.removeItem(at: url)
                }
            }
        }

        attempts.removeAll()
        persistAttempts()
    }

    /// Get attempts for specific scenario type
    func getAttempts(for scenarioType: ScenarioType) -> [PracticeAttempt] {
        attempts.filter { $0.scenario.type == scenarioType }
    }

    /// Get favorite attempts
    var favoriteAttempts: [PracticeAttempt] {
        attempts.filter { $0.isFavorite }
    }

    // MARK: - Statistics

    /// Get total practice time
    var totalPracticeTime: TimeInterval {
        attempts.reduce(0) { $0 + $1.metrics.duration }
    }

    /// Get average performance level
    var averagePerformance: PracticeMetrics.PerformanceLevel? {
        guard !attempts.isEmpty else { return nil }

        let scores = attempts.map { attempt -> Double in
            switch attempt.metrics.performanceLevel {
            case .excellent: return 4.0
            case .good: return 3.0
            case .fair: return 2.0
            case .needsImprovement: return 1.0
            }
        }

        let average = scores.reduce(0, +) / Double(scores.count)

        switch average {
        case 3.5...: return .excellent
        case 2.5..<3.5: return .good
        case 1.5..<2.5: return .fair
        default: return .needsImprovement
        }
    }

    // MARK: - Private Methods

    private func loadAttempts() {
        guard fileManager.fileExists(atPath: attemptsFileURL.path) else {
            attempts = []
            return
        }

        do {
            let data = try Data(contentsOf: attemptsFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            attempts = try decoder.decode([PracticeAttempt].self, from: data)
        } catch {
            print("Failed to load attempts: \(error)")
            // Try to delete corrupted file and start fresh
            try? fileManager.removeItem(at: attemptsFileURL)
            attempts = []
        }
    }

    private func persistAttempts() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(attempts)
            try data.write(to: attemptsFileURL)
        } catch {
            print("Failed to save attempts: \(error)")
        }
    }
}
