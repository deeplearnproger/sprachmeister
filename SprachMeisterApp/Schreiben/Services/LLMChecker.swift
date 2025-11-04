//
//  LLMChecker.swift
//  SprachMeister
//
//  Protocol for checking writing tasks with LLM
//  Created on 23.10.2025
//

import Foundation

/// Protocol for checking writing attempts (LLM or heuristic)
protocol LLMChecker {
    /// Check a writing attempt and return detailed evaluation
    func checkWriting(
        task: WritingTask,
        text: String,
        metrics: WritingMetrics
    ) async throws -> WritingEvaluation

    /// Check if the checker is ready to use
    nonisolated var isAvailable: Bool { get }

    /// Name of the checker for UI display
    nonisolated var checkerName: String { get }
}

/// Errors that can occur during checking
enum LLMCheckerError: LocalizedError {
    case modelNotLoaded
    case modelNotFound(path: String)
    case inferenceError(String)
    case invalidResponse(String)
    case textTooShort(minWords: Int, actual: Int)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "LLM-Modell nicht geladen. Bitte zuerst Modell initialisieren."
        case .modelNotFound(let path):
            return "LLM-Modell nicht gefunden: \(path)"
        case .inferenceError(let message):
            return "Fehler bei der Modellausführung: \(message)"
        case .invalidResponse(let message):
            return "Ungültige Modellantwort: \(message)"
        case .textTooShort(let minWords, let actual):
            return "Text zu kurz: \(actual) Wörter (mindestens \(minWords) erforderlich)"
        }
    }
}
