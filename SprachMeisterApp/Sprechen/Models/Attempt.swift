//
//  Attempt.swift
//  SprachMeister
//
//  Created on 20.10.2025
//

import Foundation

/// Represents a complete practice attempt/session
struct PracticeAttempt: Identifiable, Codable {
    let id: UUID
    let scenario: Scenario
    let transcript: Transcript
    let metrics: PracticeMetrics
    let createdAt: Date
    var isFavorite: Bool

    init(id: UUID = UUID(), scenario: Scenario, transcript: Transcript, metrics: PracticeMetrics, createdAt: Date = Date(), isFavorite: Bool = false) {
        self.id = id
        self.scenario = scenario
        self.transcript = transcript
        self.metrics = metrics
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: createdAt)
    }

    var durationFormatted: String {
        let minutes = Int(metrics.duration) / 60
        let seconds = Int(metrics.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
