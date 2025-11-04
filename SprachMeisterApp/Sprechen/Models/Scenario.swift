//
//  Scenario.swift
//  SprachMeister
//
//  Created on 20.10.2025
//

import Foundation

/// Represents the three Goethe B1 exam speaking parts
enum ScenarioType: String, Codable, CaseIterable, Identifiable {
    case bildbeschreibung = "Bildbeschreibung"
    case miniPraesentaion = "Mini-Präsentation"
    case dialog = "Dialog/Planung"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .bildbeschreibung:
            return "Teil 1: Beschreiben Sie ein Bild und beantworten Sie Fragen dazu."
        case .miniPraesentaion:
            return "Teil 2: Präsentieren Sie ein Thema kurz."
        case .dialog:
            return "Teil 3: Planen Sie gemeinsam etwas."
        }
    }

    var icon: String {
        switch self {
        case .bildbeschreibung:
            return "photo.on.rectangle"
        case .miniPraesentaion:
            return "person.wave.2"
        case .dialog:
            return "bubble.left.and.bubble.right"
        }
    }
}

/// Scenario configuration for practice session
struct Scenario: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ScenarioType
    let topic: String
    let prompts: [String]
    let expectedDuration: TimeInterval // in seconds
    let imageName: String? // Optional image for Bildbeschreibung scenarios

    init(id: UUID = UUID(), type: ScenarioType, topic: String, prompts: [String], expectedDuration: TimeInterval = 180, imageName: String? = nil) {
        self.id = id
        self.type = type
        self.topic = topic
        self.prompts = prompts
        self.expectedDuration = expectedDuration
        self.imageName = imageName
    }
}

// MARK: - Predefined Scenarios
extension Scenario {
    static let defaultScenarios: [Scenario] = [
        // Bildbeschreibung scenarios
        Scenario(
            type: .bildbeschreibung,
            topic: "Familienfoto",
            prompts: [
                "Was sehen Sie auf dem Bild?",
                "Wie fühlen sich die Personen?",
                "Was machen die Personen?"
            ],
            expectedDuration: 120,
            imageName: "family_meal"
        ),
        Scenario(
            type: .bildbeschreibung,
            topic: "Im Park",
            prompts: [
                "Beschreiben Sie die Situation.",
                "Welche Jahreszeit ist es?",
                "Was könnte vorher passiert sein?"
            ],
            expectedDuration: 120
        ),

        // Mini-Präsentation scenarios
        Scenario(
            type: .miniPraesentaion,
            topic: "Mein Lieblingshobby",
            prompts: [
                "Wie oft machen Sie das?",
                "Warum gefällt Ihnen das?",
                "Seit wann machen Sie das?"
            ],
            expectedDuration: 180
        ),
        Scenario(
            type: .miniPraesentaion,
            topic: "Reisen",
            prompts: [
                "Wohin reisen Sie gern?",
                "Mit wem reisen Sie?",
                "Was ist wichtig beim Reisen?"
            ],
            expectedDuration: 180
        ),

        // Dialog/Planung scenarios
        Scenario(
            type: .dialog,
            topic: "Eine Geburtstagsparty planen",
            prompts: [
                "Wann soll die Party sein?",
                "Wen laden wir ein?",
                "Was brauchen wir für die Party?",
                "Wer bringt was mit?"
            ],
            expectedDuration: 240
        ),
        Scenario(
            type: .dialog,
            topic: "Einen Ausflug organisieren",
            prompts: [
                "Wohin möchten Sie fahren?",
                "Wie kommen wir dorthin?",
                "Was nehmen wir mit?",
                "Wie lange bleiben wir?"
            ],
            expectedDuration: 240
        )
    ]
}
