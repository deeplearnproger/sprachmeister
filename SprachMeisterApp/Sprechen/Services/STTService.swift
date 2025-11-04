//
//  STTService.swift
//  SprachMeister
//
//  Speech-to-Text service using on-device recognition
//  Created on 20.10.2025
//

import Foundation
import Speech
import AVFoundation

/// Manages speech-to-text transcription
@MainActor
class STTService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isTranscribing = false
    @Published private(set) var isAuthorized = false

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechURLRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Initialization

    init() {
        // Initialize with German locale
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
        checkAuthorization()
    }

    // MARK: - Authorization

    /// Request speech recognition authorization
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.isAuthorized = status == .authorized
                    continuation.resume(returning: self.isAuthorized)
                }
            }
        }
    }

    private func checkAuthorization() {
        isAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: - Transcription

    /// Transcribe audio file to text
    /// - Parameter audioURL: URL of audio file
    /// - Returns: Transcribed text and confidence score
    func transcribe(audioURL: URL) async throws -> (text: String, confidence: Double) {
        guard isAuthorized else {
            throw ConversationError.speechRecognitionPermissionDenied
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw ConversationError.transcriptionFailed("Speech recognizer not available")
        }

        isTranscribing = true
        defer { isTranscribing = false }

        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            request.taskHint = .dictation

            // Prefer on-device recognition
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }

            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                Task { @MainActor in
                    if let error = error {
                        continuation.resume(throwing: ConversationError.transcriptionFailed(error.localizedDescription))
                        return
                    }

                    if let result = result, result.isFinal {
                        let text = result.bestTranscription.formattedString
                        let confidence = self.calculateConfidence(from: result)
                        continuation.resume(returning: (text, confidence))
                    }
                }
            }
        }
    }

    /// Cancel ongoing transcription
    func cancelTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isTranscribing = false
    }

    // MARK: - Helpers

    private func calculateConfidence(from result: SFSpeechRecognitionResult) -> Double {
        let segments = result.bestTranscription.segments

        guard !segments.isEmpty else { return 0.0 }

        let totalConfidence = segments.reduce(0.0) { $0 + Double($1.confidence) }
        return totalConfidence / Double(segments.count)
    }

    /// Check if on-device recognition is supported
    var supportsOnDeviceRecognition: Bool {
        speechRecognizer?.supportsOnDeviceRecognition ?? false
    }

    // MARK: - Cleanup

    /// Cleanup STT resources (can be called from deinit)
    nonisolated func cleanup() {
        Task { @MainActor in
            self.cancelTranscription()
        }
    }

    deinit {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}
