//
//  ConversationState.swift
//  SprachMeister
//
//  Created on 20.10.2025
//

import Foundation

/// State machine states for conversation orchestration
enum ConversationState: Equatable {
    case idle
    case ready(Scenario)
    case recording
    case transcribing
    case processingNLU
    case generatingResponse
    case speaking(String) // speaking text
    case waitingForUser
    case showingFeedback(PracticeMetrics)
    case error(ConversationError)
    case completed
}

/// Errors that can occur during conversation
enum ConversationError: Error, Equatable {
    case microphonePermissionDenied
    case speechRecognitionPermissionDenied
    case audioRecordingFailed(String)
    case transcriptionFailed(String)
    case ttsUnavailable
    case whisperModelNotLoaded
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .microphonePermissionDenied:
            return "Mikrofon-Zugriff verweigert. Bitte aktivieren Sie ihn in den Einstellungen."
        case .speechRecognitionPermissionDenied:
            return "Spracherkennung verweigert. Bitte aktivieren Sie sie in den Einstellungen."
        case .audioRecordingFailed(let message):
            return "Aufnahmefehler: \(message)"
        case .transcriptionFailed(let message):
            return "Transkriptionsfehler: \(message)"
        case .ttsUnavailable:
            return "Text-zu-Sprache nicht verfügbar."
        case .whisperModelNotLoaded:
            return "Whisper-Modell wird geladen. Bitte warten..."
        case .unknown(let message):
            return "Unbekannter Fehler: \(message)"
        }
    }
}

/// Events that trigger state transitions
enum ConversationEvent {
    case startPractice(Scenario)
    case startRecording
    case stopRecording
    case transcriptionComplete(String, confidence: Double)
    case responseGenerated(String)
    case speechComplete
    case userTurnComplete
    case sessionComplete
    case error(ConversationError)
    case reset
}
