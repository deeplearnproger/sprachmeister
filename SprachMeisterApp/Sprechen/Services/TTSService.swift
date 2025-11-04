//
//  TTSService.swift
//  SprachMeister
//
//  Text-to-Speech service using AVSpeechSynthesizer
//  Created on 20.10.2025
//

import Foundation
import AVFoundation
import Combine

/// Manages text-to-speech synthesis
@MainActor
class TTSService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isSpeaking = false
    @Published private(set) var currentUtterance: String?

    // MARK: - Private Properties

    private let synthesizer = AVSpeechSynthesizer()
    private var continuations: [UUID: CheckedContinuation<Void, Never>] = [:]

    // MARK: - Configuration

    private let germanVoiceIdentifier = "com.apple.ttsbundle.Anna-compact" // German voice
    private let speechRate: Float = 0.5 // Moderate speed for language learners
    private let pitchMultiplier: Float = 1.0

    // MARK: - Initialization

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public Methods

    /// Speak text in German
    /// - Parameter text: Text to speak
    /// - Returns: Async completion when speech finishes
    func speak(_ text: String) async {
        guard !text.isEmpty else { return }

        // Stop any current speech
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // Configure German voice
        if let germanVoice = AVSpeechSynthesisVoice(language: "de-DE") {
            utterance.voice = germanVoice
        } else {
            // Fallback to any German voice
            utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        }

        utterance.rate = speechRate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.volume = 1.0

        isSpeaking = true
        currentUtterance = text

        await withCheckedContinuation { continuation in
            let id = UUID()
            continuations[id] = continuation

            // Store ID in utterance for retrieval in delegate
            objc_setAssociatedObject(
                utterance,
                &AssociatedKeys.continuationID,
                id,
                .OBJC_ASSOCIATION_RETAIN
            )

            synthesizer.speak(utterance)
        }

        isSpeaking = false
        currentUtterance = nil
    }

    /// Stop speaking immediately
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentUtterance = nil

        // Resume all waiting continuations
        continuations.values.forEach { $0.resume() }
        continuations.removeAll()
    }

    /// Check if German voice is available
    var isGermanVoiceAvailable: Bool {
        AVSpeechSynthesisVoice.speechVoices().contains { $0.language.hasPrefix("de") }
    }

    /// Get list of available German voices
    var availableGermanVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("de") }
    }

    // MARK: - Cleanup

    /// Cleanup TTS resources (can be called from deinit)
    nonisolated func cleanup() {
        Task { @MainActor in
            self.stopSpeaking()
        }
    }

    deinit {
        // Stop any ongoing speech to properly clean up resources
        synthesizer.stopSpeaking(at: .immediate)

        // Resume all waiting continuations to prevent memory leaks
        continuations.values.forEach { $0.resume() }
        continuations.removeAll()
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSService: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if let id = objc_getAssociatedObject(utterance, &AssociatedKeys.continuationID) as? UUID {
                continuations[id]?.resume()
                continuations.removeValue(forKey: id)
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if let id = objc_getAssociatedObject(utterance, &AssociatedKeys.continuationID) as? UUID {
                continuations[id]?.resume()
                continuations.removeValue(forKey: id)
            }
        }
    }
}

// MARK: - Associated Keys

private struct AssociatedKeys {
    static var continuationID = "continuationID"
}
