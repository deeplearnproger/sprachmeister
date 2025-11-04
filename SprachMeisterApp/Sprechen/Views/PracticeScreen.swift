//
//  PracticeScreen.swift
//  SprachMeister
//
//  Main practice screen
//  Created on 20.10.2025
//

import SwiftUI

struct PracticeScreen: View {

    let scenario: Scenario

    @StateObject private var orchestrator: ConversationOrchestrator
    @StateObject private var storageService = StorageService()

    @Environment(\.dismiss) private var dismiss

    @State private var showingTranscript = false
    @State private var shouldDismiss = false

    init(scenario: Scenario) {
        self.scenario = scenario
        let storage = StorageService()
        _storageService = StateObject(wrappedValue: storage)
        _orchestrator = StateObject(wrappedValue: ConversationOrchestrator(storageService: storage))
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text(scenario.topic)
                    .font(.title2)
                    .bold()

                Text(scenario.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)

            // Image for Bildbeschreibung scenarios
            if scenario.type == .bildbeschreibung, let imageName = scenario.imageName {
                ScenarioImageView(imageName: imageName)
                    .frame(maxHeight: 250)
                    .padding(.horizontal)
            }

            Spacer()

            // State Display
            stateView

            Spacer()

            // Controls
            controlButtons

            // Transcript Button
            if !orchestrator.entries.isEmpty {
                Button(action: { showingTranscript = true }) {
                    Label("Transkript anzeigen", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(orchestrator.state != .idle && orchestrator.state != .completed)
        .task {
            await orchestrator.startPractice(with: scenario)
        }
        .sheet(isPresented: $showingTranscript) {
            if let transcript = orchestrator.transcript {
                TranscriptScreen(transcript: transcript, scenario: scenario)
            }
        }
        .alert("Fehler", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                shouldDismiss = true
            }
        } message: {
            if case .error(let error) = orchestrator.state {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: shouldDismiss) { _, newValue in
            if newValue {
                // Delay dismiss to avoid presenting from detached view controller
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    dismiss()
                }
            }
        }
    }

    // MARK: - State View

    @ViewBuilder
    private var stateView: some View {
        switch orchestrator.state {
        case .idle:
            ProgressView("Initialisierung...")

        case .ready:
            Text("Bereit zum Start")
                .font(.title3)

        case .recording:
            VStack(spacing: 16) {
                Image(systemName: "waveform")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .symbolEffect(.variableColor.iterative)

                Text("Aufnahme läuft...")
                    .font(.title3)
            }

        case .transcribing:
            VStack(spacing: 16) {
                ProgressView()
                Text("Transkribieren...")
            }

        case .processingNLU, .generatingResponse:
            VStack(spacing: 16) {
                ProgressView()
                Text("Verarbeitung...")
            }

        case .speaking(let text):
            VStack(spacing: 16) {
                Image(systemName: "person.wave.2")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                ScrollView {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }

        case .waitingForUser:
            VStack(spacing: 16) {
                Image(systemName: "mic.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Sie sind dran")
                    .font(.title2)

                Text("Tippen Sie auf Aufnehmen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .showingFeedback(let metrics):
            FeedbackView(metrics: metrics)

        case .error:
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)

        case .completed:
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Sitzung abgeschlossen!")
                    .font(.title2)
            }
        }
    }

    // MARK: - Control Buttons

    @ViewBuilder
    private var controlButtons: some View {
        HStack(spacing: 20) {
            if orchestrator.canStartRecording {
                Button(action: {
                    Task { await orchestrator.handleUserTurn() }
                }) {
                    Label("Aufnehmen", systemImage: "mic.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if orchestrator.canStopRecording {
                Button(action: {
                    Task { await orchestrator.stopRecording() }
                }) {
                    Label("Stop", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
            }

            if orchestrator.state == .completed {
                Button(action: {
                    dismiss()
                }) {
                    Label("Fertig", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: - Error Binding

    private var errorBinding: Binding<Bool> {
        Binding(
            get: {
                if case .error = orchestrator.state {
                    return true
                }
                return false
            },
            set: { _ in }
        )
    }
}

// MARK: - Feedback View

struct FeedbackView: View {
    let metrics: PracticeMetrics

    var body: some View {
        VStack(spacing: 16) {
            Text(metrics.performanceLevel.rawValue)
                .font(.title)
                .bold()
                .foregroundColor(colorForLevel(metrics.performanceLevel))

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                MetricRow(
                    label: "Dauer",
                    value: formatDuration(metrics.duration),
                    icon: "clock"
                )

                MetricRow(
                    label: "Wörter pro Minute",
                    value: String(format: "%.0f", metrics.wordsPerMinute),
                    icon: "speedometer"
                )

                MetricRow(
                    label: "Wortschatz",
                    value: String(format: "%.0f%%", metrics.lexicalDiversity * 100),
                    icon: "book"
                )

                MetricRow(
                    label: "Füllwörter",
                    value: "\(metrics.fillerWords.total)",
                    icon: "exclamationmark.bubble"
                )
            }
        }
        .padding()
    }

    private func colorForLevel(_ level: PracticeMetrics.PerformanceLevel) -> Color {
        switch level {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .needsImprovement: return .red
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .bold()
        }
    }
}

// MARK: - Scenario Image View

struct ScenarioImageView: View {
    let imageName: String

    var body: some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(12)
                .shadow(radius: 4)
        } else {
            // Placeholder if image is not found
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Bild nicht gefunden")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
        }
    }
}

#Preview {
    NavigationStack {
        PracticeScreen(scenario: Scenario.defaultScenarios[0])
    }
}
