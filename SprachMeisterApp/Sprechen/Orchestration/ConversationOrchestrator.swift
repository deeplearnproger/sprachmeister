//
//  ConversationOrchestrator.swift
//  SprachMeister
//
//  Main orchestrator managing conversation flow
//  Created on 20.10.2025
//

import Foundation
import SwiftUI

/// Orchestrates the entire conversation flow
@MainActor
class ConversationOrchestrator: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var state: ConversationState = .idle
    @Published private(set) var currentScenario: Scenario?
    @Published private(set) var transcript: Transcript?
    @Published private(set) var turnNumber = 0

    // MARK: - Services

    private let audioService = AudioService()
    private let sttService = STTService()
    private let ttsService = TTSService()
    private let responseEngine: ResponseEngine
    private let storageService: StorageService

    // MARK: - Private Properties

    private var transcriptEntries: [TranscriptEntry] = []
    private var currentRecordingURL: URL?

    // MARK: - Initialization

    init(storageService: StorageService) {
        self.storageService = storageService
        self.responseEngine = ResponseEngine()
    }

    // MARK: - Public Methods

    /// Start a practice session with a scenario
    func startPractice(with scenario: Scenario) async {
        // Check permissions
        let micPermission = await audioService.requestMicrophonePermission()
        guard micPermission else {
            state = .error(.microphonePermissionDenied)
            return
        }

        let sttPermission = await sttService.requestAuthorization()
        guard sttPermission else {
            state = .error(.speechRecognitionPermissionDenied)
            return
        }

        // Initialize session
        currentScenario = scenario
        transcriptEntries = []
        turnNumber = 0

        let transcriptID = UUID()
        transcript = Transcript(
            id: transcriptID,
            scenarioID: scenario.id,
            entries: [],
            startTime: Date(),
            endTime: nil
        )

        state = .ready(scenario)

        // Give initial prompt
        await giveInitialPrompt()
    }

    /// Handle user turn (recording and processing)
    func handleUserTurn() async {
        guard case .waitingForUser = state else { return }

        // Start recording
        state = .recording

        do {
            currentRecordingURL = try audioService.startRecording()
        } catch {
            state = .error(.audioRecordingFailed(error.localizedDescription))
            return
        }

        // Wait for recording to complete (via VAD or manual stop)
        // In actual implementation, this would be event-driven
    }

    /// Stop current recording and process
    func stopRecording() async {
        guard state == .recording else { return }

        guard let audioURL = audioService.stopRecording() else {
            state = .error(.audioRecordingFailed("No recording available"))
            return
        }

        currentRecordingURL = audioURL

        // Transcribe
        await transcribeAudio(audioURL)
    }

    /// Process complete conversation and generate feedback
    func completeSession() async {
        guard let scenario = currentScenario,
              var currentTranscript = transcript else {
            return
        }

        // Finalize transcript
        currentTranscript = Transcript(
            id: currentTranscript.id,
            scenarioID: currentTranscript.scenarioID,
            entries: transcriptEntries,
            startTime: currentTranscript.startTime,
            endTime: Date()
        )

        // Generate metrics
        let tempAttempt = PracticeAttempt(
            scenario: scenario,
            transcript: currentTranscript,
            metrics: PracticeMetrics(
                attemptID: UUID(),
                duration: 0,
                totalWords: 0,
                wordsPerMinute: 0,
                fillerWords: PracticeMetrics.FillerWordStats(count: 0, types: [:]),
                lexicalDiversity: 0,
                grammarScore: nil
            )
        )

        let metrics = MetricsAnalyzer.generateMetrics(for: tempAttempt)

        // Create and save attempt
        let attempt = PracticeAttempt(
            scenario: scenario,
            transcript: currentTranscript,
            metrics: metrics
        )

        storageService.saveAttempt(attempt)

        // Show feedback
        state = .showingFeedback(metrics)

        // Give verbal feedback
        let feedbackText = await responseEngine.generateFeedback(
            for: metrics,
            scenario: scenario,
            transcript: currentTranscript
        )
        await ttsService.speak(feedbackText)

        state = .completed
    }

    /// Reset orchestrator
    func reset() {
        _ = audioService.stopRecording()
        ttsService.stopSpeaking()
        sttService.cancelTranscription()

        state = .idle
        currentScenario = nil
        transcript = nil
        transcriptEntries = []
        turnNumber = 0
        currentRecordingURL = nil
    }

    // MARK: - Private Methods

    private func giveInitialPrompt() async {
        guard let scenario = currentScenario else { return }

        let prompt = responseEngine.getInitialPrompt(for: scenario)

        // Add to transcript
        let entry = TranscriptEntry(
            speaker: .examiner,
            text: prompt
        )
        transcriptEntries.append(entry)

        // Speak prompt
        state = .speaking(prompt)
        await ttsService.speak(prompt)

        state = .waitingForUser
    }

    private func transcribeAudio(_ audioURL: URL) async {
        state = .transcribing

        do {
            let (text, confidence) = try await sttService.transcribe(audioURL: audioURL)

            // Add user entry to transcript
            let entry = TranscriptEntry(
                speaker: .user,
                text: text,
                audioURL: audioURL,
                confidence: confidence
            )
            transcriptEntries.append(entry)

            // Process NLU and generate response
            await generateResponse(for: text)

        } catch {
            state = .error(.transcriptionFailed(error.localizedDescription))
        }
    }

    private func generateResponse(for userInput: String) async {
        guard let scenario = currentScenario else { return }

        state = .processingNLU

        turnNumber += 1

        // Check if session should end
        if responseEngine.shouldEndSession(scenario: scenario, turnNumber: turnNumber) {
            await completeSession()
            return
        }

        state = .generatingResponse

        let response = await responseEngine.generateResponse(
            scenario: scenario,
            userInput: userInput,
            turnNumber: turnNumber,
            conversationHistory: transcriptEntries
        )

        // Add examiner response to transcript
        let entry = TranscriptEntry(
            speaker: .examiner,
            text: response
        )
        transcriptEntries.append(entry)

        // Speak response
        state = .speaking(response)
        await ttsService.speak(response)

        state = .waitingForUser
    }

    // MARK: - Computed Properties

    var canStartRecording: Bool {
        if case .waitingForUser = state {
            return true
        }
        return false
    }

    var canStopRecording: Bool {
        state == .recording
    }

    var isProcessing: Bool {
        switch state {
        case .transcribing, .processingNLU, .generatingResponse:
            return true
        default:
            return false
        }
    }

    var entries: [TranscriptEntry] {
        transcriptEntries
    }

    // MARK: - Cleanup

    deinit {
        // Clean up all services and resources using nonisolated cleanup methods
        audioService.cleanup()
        ttsService.cleanup()
        sttService.cleanup()
    }
}
