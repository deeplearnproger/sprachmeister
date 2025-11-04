//
//  Transcript.swift
//  SprachMeister
//
//  Created on 20.10.2025
//

import Foundation

/// Represents a single turn in the conversation
struct TranscriptEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let speaker: Speaker
    let text: String
    let audioURL: URL? // optional recording reference
    let confidence: Double? // STT confidence score

    enum Speaker: String, Codable {
        case user = "User"
        case examiner = "Prüfer"
    }

    init(id: UUID = UUID(), timestamp: Date = Date(), speaker: Speaker, text: String, audioURL: URL? = nil, confidence: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.speaker = speaker
        self.text = text
        self.audioURL = audioURL
        self.confidence = confidence
    }
}

/// Complete transcript of a practice session
struct Transcript: Identifiable, Codable {
    let id: UUID
    let scenarioID: UUID
    let entries: [TranscriptEntry]
    let startTime: Date
    let endTime: Date?

    init(id: UUID = UUID(), scenarioID: UUID, entries: [TranscriptEntry] = [], startTime: Date = Date(), endTime: Date? = nil) {
        self.id = id
        self.scenarioID = scenarioID
        self.entries = entries
        self.startTime = startTime
        self.endTime = endTime
    }

    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }

    var userEntries: [TranscriptEntry] {
        entries.filter { $0.speaker == .user }
    }

    var examinerEntries: [TranscriptEntry] {
        entries.filter { $0.speaker == .examiner }
    }
}
