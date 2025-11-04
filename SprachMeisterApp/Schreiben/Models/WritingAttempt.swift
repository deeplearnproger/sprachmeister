//
//  WritingAttempt.swift
//  SprachMeister
//
//  Model for storing writing practice attempts
//  Created on 23.10.2025
//

import Foundation

/// Represents a complete writing practice attempt
struct WritingAttempt: Identifiable, Codable {
    let id: UUID
    let task: WritingTask
    let text: String
    let startedAt: Date
    let duration: TimeInterval // in seconds
    let metrics: WritingMetrics
    let evaluation: WritingEvaluation?
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        task: WritingTask,
        text: String,
        startedAt: Date = Date(),
        duration: TimeInterval,
        metrics: WritingMetrics,
        evaluation: WritingEvaluation? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.task = task
        self.text = text
        self.startedAt = startedAt
        self.duration = duration
        self.metrics = metrics
        self.evaluation = evaluation
        self.isFavorite = isFavorite
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: startedAt)
    }

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var wordsPerMinute: Double {
        guard duration > 0 else { return 0 }
        let wpm = Double(metrics.wordCount) / (duration / 60.0)
        return wpm.isNaN || wpm.isInfinite ? 0 : wpm
    }
}

/// Writing metrics and text analysis
struct WritingMetrics: Codable, Equatable {
    let attemptID: UUID
    let wordCount: Int
    let sentenceCount: Int
    let avgSentenceLength: Double
    let typeTokenRatio: Double // Lexical diversity (0.0 to 1.0)
    let writingPace: [PaceInterval] // Words per minute over time
    let subpointCoverage: [SubpointCoverage]
    let phrasesUsed: [String] // Detected Konnektoren/Redemittel
    let estimatedLevel: String // e.g. "A2", "B1", "B2"

    struct PaceInterval: Codable, Equatable {
        let intervalStart: TimeInterval // seconds from start
        let wordsWritten: Int
        let wordsPerMinute: Double
    }

    struct SubpointCoverage: Codable, Equatable {
        let subpoint: String
        let covered: Bool
        let confidence: Double // 0.0 to 1.0
        let evidence: String? // Text excerpt showing coverage
    }
}

/// LLM or heuristic evaluation of writing quality
struct WritingEvaluation: Codable, Equatable {
    let scores: RubricScores
    let errors: [WritingError]
    let checkpoints: [CheckpointResult]
    let summary: String // Brief feedback in German
    let improvements: [String] // Suggestions
    let modelSuggestions: [String]? // Optional example sentences
    let improvedVersion: String? // Model's improved version of user's text
    let positiveAspects: [String]? // What was good
    let negativeAspects: [String]? // What needs improvement

    struct RubricScores: Codable, Equatable {
        let aufgabenerfuellung: Double // 0-5: Task completion
        let kohaerenz: Double // 0-5: Coherence & structure
        let wortschatz: Double // 0-5: Vocabulary range
        let strukturen: Double // 0-5: Grammar & orthography

        var overall: Double {
            (aufgabenerfuellung + kohaerenz + wortschatz + strukturen) / 4.0
        }

        var level: EvaluationLevel {
            switch overall {
            case 4.5...: return .excellent
            case 3.5..<4.5: return .good
            case 2.5..<3.5: return .satisfactory
            case 1.5..<2.5: return .needsWork
            default: return .insufficient
            }
        }
    }

    enum EvaluationLevel: String, Codable {
        case excellent = "Ausgezeichnet (A)"
        case good = "Gut (B)"
        case satisfactory = "Befriedigend (C)"
        case needsWork = "Ausreichend (D)"
        case insufficient = "Nicht ausreichend (E)"

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .satisfactory: return "orange"
            case .needsWork: return "red"
            case .insufficient: return "red"
            }
        }
    }

    struct CheckpointResult: Codable, Equatable {
        let subpoint: String
        let covered: Bool
        let evidence: String?
    }
}

/// Detected writing errors
struct WritingError: Codable, Equatable, Identifiable {
    let id: UUID
    let type: ErrorType
    let sample: String // Excerpt showing the error
    let hint: String // Correction suggestion

    init(id: UUID = UUID(), type: ErrorType, sample: String, hint: String) {
        self.id = id
        self.type = type
        self.sample = sample
        self.hint = hint
    }

    enum ErrorType: String, Codable {
        case orthografie = "Rechtschreibung"
        case morphologie = "Grammatik (Morphologie)"
        case syntax = "Satzbau"
        case zeichensetzung = "Zeichensetzung"
        case register = "Register/Stil"
        case kohaerenz = "Logik/Zusammenhang"

        var icon: String {
            switch self {
            case .orthografie: return "textformat.abc"
            case .morphologie: return "character.textbox"
            case .syntax: return "list.bullet.indent"
            case .zeichensetzung: return "exclamationmark.circle"
            case .register: return "person.text.rectangle"
            case .kohaerenz: return "arrow.triangle.branch"
            }
        }
    }
}
