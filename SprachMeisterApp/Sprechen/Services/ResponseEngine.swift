//
//  ResponseEngine.swift
//  SprachMeister
//
//  Template-based German response generation
//  Created on 20.10.2025
//

import Foundation

/// Generates examiner responses based on scenario context
class ResponseEngine {

    // MARK: - Initialization

    init() {
        // Template-based response generation only
    }

    // MARK: - Response Generation

    /// Generate examiner response based on scenario and user input
    func generateResponse(
        scenario: Scenario,
        userInput: String,
        turnNumber: Int,
        conversationHistory: [TranscriptEntry]
    ) async -> String {
        // Template-based response generation
        return generateTemplateResponse(
            scenario: scenario,
            userInput: userInput,
            turnNumber: turnNumber,
            conversationHistory: conversationHistory
        )
    }

    // MARK: - Template-Based Generation

    private func generateTemplateResponse(
        scenario: Scenario,
        userInput: String,
        turnNumber: Int,
        conversationHistory: [TranscriptEntry]
    ) -> String {
        switch scenario.type {
        case .bildbeschreibung:
            return generateBildbeschreibungResponse(userInput: userInput, turnNumber: turnNumber)

        case .miniPraesentaion:
            return generatePraesentationResponse(userInput: userInput, turnNumber: turnNumber)

        case .dialog:
            return generateDialogResponse(userInput: userInput, turnNumber: turnNumber, topic: scenario.topic)
        }
    }

    /// Get initial examiner prompt for scenario
    func getInitialPrompt(for scenario: Scenario) -> String {
        switch scenario.type {
        case .bildbeschreibung:
            return "Guten Tag! Heute schauen wir uns ein Bild an. Bitte beschreiben Sie, was Sie auf dem Bild sehen."

        case .miniPraesentaion:
            return "Hallo! Heute präsentieren Sie ein Thema: \(scenario.topic). Bitte beginnen Sie mit Ihrer Präsentation."

        case .dialog:
            return "Guten Tag! Heute planen wir zusammen etwas: \(scenario.topic). Haben Sie schon Ideen dazu?"
        }
    }

    // MARK: - Bildbeschreibung Responses

    private func generateBildbeschreibungResponse(userInput: String, turnNumber: Int) -> String {
        let responses: [[String]] = [
            // Turn 1: Initial description
            [
                "Sehr gut! Was können Sie noch über die Personen sagen?",
                "Interessant! Welche Details sehen Sie noch?",
                "Gut beobachtet! Was passiert im Hintergrund?"
            ],
            // Turn 2: Details
            [
                "Wie fühlen sich die Personen auf dem Bild, denken Sie?",
                "Was könnten die Personen gerade machen?",
                "Welche Atmosphäre herrscht auf dem Bild?"
            ],
            // Turn 3: Interpretation
            [
                "Sehr gut erklärt! Was könnte vor dieser Situation passiert sein?",
                "Interessante Perspektive! Und was passiert vielleicht danach?",
                "Das haben Sie gut beschrieben. Vielen Dank!"
            ]
        ]

        return selectRandomResponse(from: responses, turnNumber: turnNumber)
    }

    // MARK: - Mini-Präsentation Responses

    private func generatePraesentationResponse(userInput: String, turnNumber: Int) -> String {
        let responses: [[String]] = [
            // Turn 1: After introduction
            [
                "Sehr interessant! Können Sie mehr darüber erzählen?",
                "Das klingt spannend! Wie oft machen Sie das?",
                "Gut! Seit wann interessieren Sie sich dafür?"
            ],
            // Turn 2: Follow-up
            [
                "Verstehe. Was gefällt Ihnen daran besonders?",
                "Aha! Gibt es auch Nachteile?",
                "Interessant! Was würden Sie anderen empfehlen?"
            ],
            // Turn 3: Conclusion
            [
                "Das haben Sie sehr gut präsentiert. Vielen Dank!",
                "Ausgezeichnet erklärt! Danke für Ihre Präsentation.",
                "Sehr informativ! Vielen Dank für Ihre Zeit."
            ]
        ]

        return selectRandomResponse(from: responses, turnNumber: turnNumber)
    }

    // MARK: - Dialog/Planung Responses

    private func generateDialogResponse(userInput: String, turnNumber: Int, topic: String) -> String {
        let responses: [[String]] = [
            // Turn 1: Initial planning
            [
                "Gute Idee! Und wann soll das stattfinden?",
                "Das klingt gut! Was brauchen wir dafür?",
                "Einverstanden! Wen sollen wir einladen?"
            ],
            // Turn 2: Details
            [
                "Ja, das passt. Und wo machen wir das?",
                "Prima! Wer bringt was mit?",
                "Gut überlegt! Wie organisieren wir das?"
            ],
            // Turn 3: More details
            [
                "Sehr praktisch! Was noch?",
                "Das ist wichtig. Haben wir noch etwas vergessen?",
                "Guter Punkt! Und wie viel kostet das ungefähr?"
            ],
            // Turn 4: Conclusion
            [
                "Perfekt! Dann ist alles geplant. Vielen Dank!",
                "Ausgezeichnet! Ich denke, wir haben alles besprochen.",
                "Sehr gut organisiert! Vielen Dank für die Planung."
            ]
        ]

        return selectRandomResponse(from: responses, turnNumber: turnNumber)
    }

    // MARK: - Feedback Responses

    /// Generate encouraging feedback based on performance
    func generateFeedback(for metrics: PracticeMetrics, scenario: Scenario? = nil, transcript: Transcript? = nil) async -> String {
        // Template-based feedback generation
        return generateTemplateFeedback(for: metrics)
    }

    /// Generate template-based feedback
    private func generateTemplateFeedback(for metrics: PracticeMetrics) -> String {
        let level = metrics.performanceLevel

        var feedback = "Ihre Leistung: \(level.rawValue)\n\n"

        // WPM feedback
        if metrics.wordsPerMinute < 80 {
            feedback += "• Versuchen Sie, etwas flüssiger zu sprechen.\n"
        } else if metrics.wordsPerMinute > 150 {
            feedback += "• Sprechen Sie etwas langsamer für bessere Verständlichkeit.\n"
        } else {
            feedback += "• Ihr Sprechtempo ist gut!\n"
        }

        // Filler words feedback
        if metrics.fillerWords.total > 10 {
            feedback += "• Reduzieren Sie Füllwörter wie 'äh', 'ähm'.\n"
        } else if metrics.fillerWords.total < 5 {
            feedback += "• Sehr wenige Füllwörter - ausgezeichnet!\n"
        }

        // Lexical diversity
        if metrics.lexicalDiversity > 0.7 {
            feedback += "• Großer Wortschatz - sehr gut!\n"
        } else if metrics.lexicalDiversity < 0.4 {
            feedback += "• Verwenden Sie mehr verschiedene Wörter.\n"
        }

        // Grammar
        if let grammar = metrics.grammarScore {
            if grammar.overallScore > 0.7 {
                feedback += "• Grammatik ist gut!\n"
            } else {
                feedback += "• Achten Sie auf Artikel (der/die/das) und Verbposition.\n"
            }
        }

        return feedback
    }

    // MARK: - Helpers

    private func selectRandomResponse(from responses: [[String]], turnNumber: Int) -> String {
        let index = min(turnNumber, responses.count - 1)
        let options = responses[index]
        return options.randomElement() ?? "Können Sie mehr dazu sagen?"
    }

    /// Check if session should end based on turn count
    func shouldEndSession(scenario: Scenario, turnNumber: Int) -> Bool {
        switch scenario.type {
        case .bildbeschreibung:
            return turnNumber >= 3
        case .miniPraesentaion:
            return turnNumber >= 3
        case .dialog:
            return turnNumber >= 4
        }
    }
}
