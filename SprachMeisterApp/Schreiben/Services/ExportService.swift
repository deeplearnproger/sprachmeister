//
//  ExportService.swift
//  SprachMeister
//
//  Service for exporting writing attempts to JSON
//  Created on 23.10.2025
//

import Foundation
import UIKit

/// Service for exporting writing attempts and analytics
class ExportService {

    // MARK: - Export Formats

    enum ExportFormat {
        case json
        case prettyJSON
    }

    // MARK: - Export Errors

    enum ExportError: LocalizedError {
        case encodingFailed(String)
        case fileCreationFailed(String)
        case sharingFailed(String)

        var errorDescription: String? {
            switch self {
            case .encodingFailed(let message):
                return "Fehler beim Kodieren: \(message)"
            case .fileCreationFailed(let message):
                return "Fehler beim Erstellen der Datei: \(message)"
            case .sharingFailed(let message):
                return "Fehler beim Teilen: \(message)"
            }
        }
    }

    // MARK: - Single Attempt Export

    /// Export a single writing attempt to JSON
    static func exportAttempt(
        _ attempt: WritingAttempt,
        format: ExportFormat = .prettyJSON
    ) throws -> Data {

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if format == .prettyJSON {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }

        do {
            return try encoder.encode(attempt)
        } catch {
            throw ExportError.encodingFailed(error.localizedDescription)
        }
    }

    /// Export attempt to file URL
    static func exportAttemptToFile(
        _ attempt: WritingAttempt,
        format: ExportFormat = .prettyJSON
    ) throws -> URL {

        let data = try exportAttempt(attempt, format: format)

        // Create filename with date and task type
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        let dateString = formatter.string(from: attempt.startedAt)
        let filename = "Schreiben_\(attempt.task.type.rawValue)_\(dateString).json"

        // Get temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            throw ExportError.fileCreationFailed(error.localizedDescription)
        }
    }

    // MARK: - Multiple Attempts Export

    /// Export multiple attempts to JSON
    static func exportAttempts(
        _ attempts: [WritingAttempt],
        format: ExportFormat = .prettyJSON
    ) throws -> Data {

        struct AttemptCollection: Codable {
            let exportDate: Date
            let totalAttempts: Int
            let attempts: [WritingAttempt]
        }

        let collection = AttemptCollection(
            exportDate: Date(),
            totalAttempts: attempts.count,
            attempts: attempts
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if format == .prettyJSON {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }

        do {
            return try encoder.encode(collection)
        } catch {
            throw ExportError.encodingFailed(error.localizedDescription)
        }
    }

    /// Export attempts to file URL
    static func exportAttemptsToFile(
        _ attempts: [WritingAttempt],
        format: ExportFormat = .prettyJSON
    ) throws -> URL {

        let data = try exportAttempts(attempts, format: format)

        // Create filename
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        let dateString = formatter.string(from: Date())
        let filename = "Schreiben_Export_\(dateString).json"

        // Get temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            throw ExportError.fileCreationFailed(error.localizedDescription)
        }
    }

    // MARK: - Analytics Export

    /// Export detailed analytics report
    static func exportAnalytics(
        attempts: [WritingAttempt]
    ) throws -> Data {

        struct AnalyticsReport: Codable {
            let exportDate: Date
            let totalAttempts: Int
            let teil1Attempts: Int
            let teil2Attempts: Int
            let averageScore: Double?
            let averageWordCount: Double
            let averageDuration: Double
            let mostCommonErrors: [String: Int]
            let phrasesUsageStats: [String: Int]
            let attempts: [WritingAttempt]
        }

        // Calculate statistics
        let teil1Count = attempts.filter { $0.task.type == .forumPost }.count
        let teil2Count = attempts.filter { $0.task.type == .email }.count

        let scoresWithEvaluation = attempts.compactMap { $0.evaluation?.scores.overall }
        let averageScore = scoresWithEvaluation.isEmpty
            ? nil
            : scoresWithEvaluation.reduce(0, +) / Double(scoresWithEvaluation.count)

        let averageWordCount = attempts.isEmpty
            ? 0
            : Double(attempts.reduce(0) { $0 + $1.metrics.wordCount }) / Double(attempts.count)

        let averageDuration = attempts.isEmpty
            ? 0
            : attempts.reduce(0) { $0 + $1.duration } / Double(attempts.count)

        // Aggregate errors
        var errorTypeCounts: [String: Int] = [:]
        for attempt in attempts {
            if let errors = attempt.evaluation?.errors {
                for error in errors {
                    errorTypeCounts[error.type.rawValue, default: 0] += 1
                }
            }
        }

        // Aggregate phrases
        var phraseUsageCounts: [String: Int] = [:]
        for attempt in attempts {
            for phrase in attempt.metrics.phrasesUsed {
                phraseUsageCounts[phrase, default: 0] += 1
            }
        }

        let report = AnalyticsReport(
            exportDate: Date(),
            totalAttempts: attempts.count,
            teil1Attempts: teil1Count,
            teil2Attempts: teil2Count,
            averageScore: averageScore,
            averageWordCount: averageWordCount,
            averageDuration: averageDuration,
            mostCommonErrors: errorTypeCounts,
            phrasesUsageStats: phraseUsageCounts,
            attempts: attempts
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            return try encoder.encode(report)
        } catch {
            throw ExportError.encodingFailed(error.localizedDescription)
        }
    }

    /// Export analytics to file
    static func exportAnalyticsToFile(
        attempts: [WritingAttempt]
    ) throws -> URL {

        let data = try exportAnalytics(attempts: attempts)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        let dateString = formatter.string(from: Date())
        let filename = "Schreiben_Analytics_\(dateString).json"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            throw ExportError.fileCreationFailed(error.localizedDescription)
        }
    }

    // MARK: - Share Sheet Helper

    /// Create activity view controller for sharing exported file
    static func createShareSheet(for url: URL) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        activityVC.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .postToFlickr,
            .postToVimeo
        ]

        return activityVC
    }
}
