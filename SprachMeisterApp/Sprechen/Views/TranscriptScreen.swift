//
//  TranscriptScreen.swift
//  SprachMeister
//
//  Transcript viewing screen
//  Created on 20.10.2025
//

import SwiftUI

struct TranscriptScreen: View {

    let transcript: Transcript
    let scenario: Scenario

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    headerSection

                    Divider()

                    // Transcript entries
                    ForEach(transcript.entries) { entry in
                        TranscriptEntryView(entry: entry)
                    }
                }
                .padding()
            }
            .navigationTitle("Transkript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scenario.topic)
                .font(.title2)
                .bold()

            HStack {
                Label(scenario.type.rawValue, systemImage: scenario.type.icon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if let endTime = transcript.endTime {
                    let duration = endTime.timeIntervalSince(transcript.startTime)
                    Label(
                        formatDuration(duration),
                        systemImage: "clock"
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Transcript Entry View

struct TranscriptEntryView: View {
    let entry: TranscriptEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Speaker icon
            Image(systemName: entry.speaker == .user ? "person.circle.fill" : "person.wave.2.fill")
                .font(.title2)
                .foregroundColor(entry.speaker == .user ? .blue : .green)

            VStack(alignment: .leading, spacing: 4) {
                // Speaker label
                Text(entry.speaker.rawValue)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)

                // Text content
                Text(entry.text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                // Metadata
                HStack(spacing: 12) {
                    // Timestamp
                    Text(formatTime(entry.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Confidence score (for user entries)
                    if entry.speaker == .user, let confidence = entry.confidence {
                        Label(
                            String(format: "%.0f%%", confidence * 100),
                            systemImage: "checkmark.circle"
                        )
                        .font(.caption2)
                        .foregroundColor(confidenceColor(confidence))
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(entry.speaker == .user ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    let scenario = Scenario.defaultScenarios[0]
    let entries = [
        TranscriptEntry(speaker: .examiner, text: "Guten Tag! Bitte beschreiben Sie das Bild.", confidence: nil),
        TranscriptEntry(speaker: .user, text: "Auf dem Bild sehe ich eine Familie im Park.", confidence: 0.92),
        TranscriptEntry(speaker: .examiner, text: "Sehr gut! Was machen die Personen?", confidence: nil),
        TranscriptEntry(speaker: .user, text: "Sie spielen zusammen Fußball und haben Spaß.", confidence: 0.88)
    ]

    let transcript = Transcript(
        scenarioID: scenario.id,
        entries: entries,
        startTime: Date().addingTimeInterval(-300),
        endTime: Date()
    )

    return TranscriptScreen(transcript: transcript, scenario: scenario)
}
