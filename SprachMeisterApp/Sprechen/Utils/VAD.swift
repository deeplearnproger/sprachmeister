//
//  VAD.swift
//  SprachMeister
//
//  Voice Activity Detection utility
//  Created on 20.10.2025
//

import Foundation
import Accelerate

/// Simple Voice Activity Detection based on energy threshold
class VoiceActivityDetector {

    // MARK: - Configuration

    struct Config {
        /// Energy threshold for detecting speech (dB)
        var energyThreshold: Float = -35.0

        /// Minimum silence duration to stop recording (seconds)
        var silenceDuration: TimeInterval = 2.0

        /// Minimum speech duration before considering it valid (seconds)
        var minimumSpeechDuration: TimeInterval = 0.5

        /// Window size for energy calculation (samples)
        var windowSize: Int = 4096
    }

    // MARK: - Properties

    private let config: Config
    private var lastSpeechTime: Date?
    private var speechStartTime: Date?
    private var isSpeaking = false

    // MARK: - Initialization

    init(config: Config = Config()) {
        self.config = config
    }

    // MARK: - Public Methods

    /// Process audio buffer and detect voice activity
    /// Returns true if speech is detected, false if silence
    func processAudioBuffer(_ buffer: [Float]) -> Bool {
        let energy = calculateEnergy(buffer)
        let isSpeechDetected = energy > config.energyThreshold

        let now = Date()

        if isSpeechDetected {
            lastSpeechTime = now
            if !isSpeaking {
                speechStartTime = now
                isSpeaking = true
            }
        }

        return isSpeaking
    }

    /// Check if silence duration threshold has been exceeded
    func shouldStopRecording() -> Bool {
        guard let lastSpeech = lastSpeechTime else { return false }

        let silenceDuration = Date().timeIntervalSince(lastSpeech)
        return silenceDuration >= config.silenceDuration && isSpeaking
    }

    /// Check if minimum speech duration has been met
    func hasMinimumSpeech() -> Bool {
        guard let startTime = speechStartTime else { return false }
        let duration = Date().timeIntervalSince(startTime)
        return duration >= config.minimumSpeechDuration
    }

    /// Reset detector state
    func reset() {
        lastSpeechTime = nil
        speechStartTime = nil
        isSpeaking = false
    }

    // MARK: - Private Methods

    /// Calculate RMS energy in dB
    private func calculateEnergy(_ buffer: [Float]) -> Float {
        guard !buffer.isEmpty else { return -100.0 }

        var rms: Float = 0.0
        vDSP_rmsqv(buffer, 1, &rms, vDSP_Length(buffer.count))

        // Convert to dB
        let db = 20 * log10(max(rms, 1e-10))
        return db
    }
}
