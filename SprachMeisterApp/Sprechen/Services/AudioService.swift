//
//  AudioService.swift
//  SprachMeister
//
//  Audio recording and playback service
//  Created on 20.10.2025
//

import Foundation
import AVFoundation
import Combine

/// Manages audio recording and playback
@MainActor
class AudioService: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isRecording = false
    @Published private(set) var audioLevel: Float = 0.0
    @Published private(set) var recordingDuration: TimeInterval = 0

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingStartTime: Date?
    private var audioBuffer: [Float] = []

    private let vad = VoiceActivityDetector()
    private var vadTimer: Timer?

    private var recordingURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = ISO8601DateFormatter().string(from: Date())
        return documentsPath.appendingPathComponent("recording_\(timestamp).wav")
    }

    // MARK: - Permissions

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Check if microphone permission is granted
    var hasMicrophonePermission: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    // MARK: - Recording Control

    /// Start recording audio
    func startRecording() throws -> URL {
        guard !isRecording else {
            throw ConversationError.audioRecordingFailed("Already recording")
        }

        guard hasMicrophonePermission else {
            throw ConversationError.microphonePermissionDenied
        }

        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        // Create audio engine
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Create audio file for recording
        let file = try AVAudioFile(
            forWriting: recordingURL,
            settings: inputFormat.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        audioEngine = engine
        audioFile = file

        // Install tap to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            // Write to file
            try? file.write(from: buffer)

            // Process for VAD
            Task { @MainActor in
                self.processAudioBuffer(buffer)
            }
        }

        // Start engine
        try engine.start()

        isRecording = true
        recordingStartTime = Date()
        vad.reset()

        // Start VAD monitoring
        startVADMonitoring()

        return recordingURL
    }

    /// Stop recording audio
    func stopRecording() -> URL? {
        guard isRecording else { return nil }

        vadTimer?.invalidate()
        vadTimer = nil

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        isRecording = false
        recordingStartTime = nil

        let url = audioFile?.url
        audioFile = nil

        // Deactivate audio session to release resources
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        return url
    }

    // MARK: - Private Helpers

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))

        // Update audio level
        let level = samples.map { abs($0) }.max() ?? 0.0
        audioLevel = level

        // Process with VAD
        _ = vad.processAudioBuffer(samples)

        // Update duration
        if let startTime = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(startTime)
        }
    }

    private func startVADMonitoring() {
        vadTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                // Auto-stop if VAD detects long silence
                if self.vad.shouldStopRecording() && self.vad.hasMinimumSpeech() {
                    _ = self.stopRecording()
                }
            }
        }
    }

    // MARK: - Cleanup

    /// Cleanup audio resources (can be called from deinit)
    nonisolated func cleanup() {
        Task { @MainActor in
            _ = self.stopRecording()
        }
    }

    deinit {
        // Properly clean up all audio resources
        vadTimer?.invalidate()
        vadTimer = nil

        if let engine = audioEngine {
            // Always try to remove tap - safe even if not installed
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        audioEngine = nil
        audioFile = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
