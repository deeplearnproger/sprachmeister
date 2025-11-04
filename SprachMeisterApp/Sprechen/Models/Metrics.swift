//
//  Metrics.swift
//  SprachMeister
//
//  Created on 20.10.2025
//

import Foundation

/// Feedback metrics for a practice session
struct PracticeMetrics: Codable, Equatable {
    let attemptID: UUID
    let duration: TimeInterval
    let totalWords: Int
    let wordsPerMinute: Double
    let fillerWords: FillerWordStats
    let lexicalDiversity: Double // 0.0 to 1.0
    let grammarScore: GrammarScore?

    struct FillerWordStats: Codable, Equatable {
        let count: Int
        let types: [String: Int] // e.g., ["äh": 5, "ähm": 3]

        var total: Int {
            types.values.reduce(0, +)
        }
    }

    struct GrammarScore: Codable, Equatable {
        let articleErrors: Int // der/die/das mistakes
        let verbPositionErrors: Int // main clause verb position
        let tenseConsistency: Double // 0.0 to 1.0

        var overallScore: Double {
            let errorCount = Double(articleErrors + verbPositionErrors)
            let penaltyFactor = max(0, 1.0 - (errorCount * 0.05))
            return (penaltyFactor + tenseConsistency) / 2.0
        }
    }

    /// Performance level based on metrics
    var performanceLevel: PerformanceLevel {
        let wpmScore = wordsPerMinute >= 100 ? 1.0 : wordsPerMinute / 100.0
        let diversityScore = lexicalDiversity
        let fillerPenalty = min(1.0, Double(fillerWords.total) * 0.02)

        let overallScore = (wpmScore + diversityScore - fillerPenalty) / 2.0

        switch overallScore {
        case 0.8...:
            return .excellent
        case 0.6..<0.8:
            return .good
        case 0.4..<0.6:
            return .fair
        default:
            return .needsImprovement
        }
    }

    enum PerformanceLevel: String, Codable {
        case excellent = "Ausgezeichnet"
        case good = "Gut"
        case fair = "Befriedigend"
        case needsImprovement = "Verbesserungsbedarf"

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "orange"
            case .needsImprovement: return "red"
            }
        }
    }
}
