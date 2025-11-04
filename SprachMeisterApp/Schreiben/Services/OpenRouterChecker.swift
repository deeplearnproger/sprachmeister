//
//  OpenRouterChecker.swift
//  SprachMeister
//
//  Real LLM checker using OpenRouter API
//  Created on 24.10.2025
//

import Foundation

/// LLM checker using OpenRouter API with real models
@MainActor
class OpenRouterChecker: LLMChecker {

    // MARK: - Properties

    private let apiKey: String
    private var currentModelIndex = 0
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"

    // List of free models to try in order (better models first for JSON output)
    private let freeModels = [
        "mistralai/mistral-7b-instruct:free",
        "google/gemini-2.0-flash-exp:free",
        "qwen/qwen-2-7b-instruct:free",
        "meta-llama/llama-3.2-3b-instruct:free",
        "microsoft/phi-3-mini-128k-instruct:free",
        "nousresearch/hermes-3-llama-3.1-405b:free",
        "huggingfaceh4/zephyr-7b-beta:free",
        "openchat/openchat-7b:free"
    ]

    nonisolated var isAvailable: Bool {
        true // Always available if API key is set
    }

    nonisolated var checkerName: String {
        "LLM OpenRouter (online)"
    }

    // MARK: - Initialization

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - LLMChecker Protocol

    func checkWriting(
        task: WritingTask,
        text: String,
        metrics: WritingMetrics
    ) async throws -> WritingEvaluation {

        print("🌐 OpenRouter checker: Task '\(task.topic)', \(metrics.wordCount) words")

        // Build prompt
        let prompt = buildPrompt(task: task, text: text, metrics: metrics)

        // Try each model in sequence until one works
        var lastError: Error?

        for (index, model) in freeModels.enumerated() {
            print("🤖 Trying model \(index + 1)/\(freeModels.count): \(model)")

            do {
                // Call OpenRouter API with this model
                let responseText = try await callOpenRouterAPI(prompt: prompt, model: model)

                // Parse JSON response
                let evaluation = try parseEvaluationResponse(responseText)

                print("✅ Successfully used model: \(model)")
                currentModelIndex = index // Remember working model for next time

                return evaluation

            } catch let error as LLMCheckerError {
                lastError = error

                // Check if it's a temporary error (rate limit, server error, etc.)
                if case .invalidResponse(let message) = error {
                    let isTemporaryError = message.contains("429") ||
                                          message.contains("rate") ||
                                          message.contains("500") ||
                                          message.contains("503") ||
                                          message.contains("Internal Server Error")

                    if isTemporaryError {
                        print("⚠️ Model \(model) has temporary error, trying next...")
                        continue
                    } else {
                        // Parsing error or other permanent error - still try next model
                        print("⚠️ Model \(model) failed with error, trying next...")
                        continue
                    }
                } else {
                    // Other LLMCheckerError - try next model
                    print("⚠️ Model \(model) failed, trying next...")
                    continue
                }
            } catch {
                lastError = error
                print("❌ Model \(model) failed: \(error.localizedDescription)")
                continue
            }
        }

        // All models failed
        throw lastError ?? LLMCheckerError.modelNotLoaded
    }

    // MARK: - Prompt Building

    private func buildPrompt(task: WritingTask, text: String, metrics: WritingMetrics) -> String {
        let subpointsText = task.subpoints.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        return """
        Du bist ein erfahrener, sehr genauer Prüfer für das **Goethe-Zertifikat B1 – Schreiben**.
        Deine Aufgabe ist es, den Text des Teilnehmers zu analysieren und eine **faire, aber strenge Bewertung** zu geben.
        Du bewertest nach den offiziellen Goethe-Kriterien (Aufgabenerfüllung, Kohärenz, Wortschatz, Strukturen).

        ---
        🧩 **AUFGABENINFORMATIONEN**
        Teil: \(task.type.rawValue)
        Thema: \(task.topic)
        Situation: \(task.situation)
        Wortanzahl: \(metrics.wordCount) (erwartet: \(task.type.minWords)–\(task.type.maxWords))
        ---
        🔸 **Unterpunkte, die vollständig behandelt werden müssen:**
        \(subpointsText)
        ---

        **1. Aufgabenerfüllung**
        - Passt der Text genau zum Thema und zur Situation?
        - Sind alle Unterpunkte behandelt und ausreichend ausgeführt (mind. 2–3 Sätze pro Punkt)?
        - Fehlende oder unvollständige Unterpunkte → Punktabzug.
        - Wenn das Thema verfehlt ist → maximal 2.0 Punkte.

        **2. Kohärenz und Struktur**
        - Hat der Text klare Gliederung: Einleitung, Hauptteil, Schluss?
        - Sind Konnektoren und Übergänge vorhanden (z. B. außerdem, deshalb, trotzdem)?
        - Weniger als 3 funktionale Konnektoren → max. 3.0 Punkte.

        **3. Wortschatz**
        - Ist der Wortschatz variabel und dem Niveau B1 entsprechend?
        - Gibt es Wiederholungen oder einfache Sätze?
        - Repetitiver Wortschatz → Reduktion auf max. 3.0 Punkte.

        **4. Strukturen**
        - Grammatik, Satzbau, Rechtschreibung, Zeichensetzung.
        - Jede 3–4 Fehler = −0.5 Punkte.
        - Wenn viele Grammatikfehler → max. 2.5 Punkte.

        ---
        ⚠️ Sei sehr genau, aber objektiv:
        - 5.0 = perfekt (sehr selten)
        - 4.0–4.9 = sehr gut (nur kleine Fehler)
        - 3.0–3.9 = gut (mehrere Fehler, aber verständlich)
        - 2.0–2.9 = ausreichend (viele Fehler)
        - 0.0–1.9 = schwach / Thema verfehlt

        ---
        📑 **TEXT DES TEILNEHMERS**
        \(text)
        ---

        ### 🧠 DEINE AUFGABE
        1. Analysiere den Text sehr präzise.
        2. Finde alle Fehler (Rechtschreibung, Grammatik, Syntax, Zeichensetzung).
        3. Prüfe, ob jeder Unterpunkt erfüllt ist.
        4. Bewerte objektiv jede Kategorie (0–5 Punkte).
        5. **Erstelle eine VERBESSERTE VERSION** des Textes auf B1-Niveau (korrigiere alle Fehler, verbessere Struktur und Wortschatz).
        6. Liste **positive Aspekte** (was gut war) und **negative Aspekte** (was verbessert werden muss).

        ---
        📤 **ANTWORTFORMAT (JSON ONLY!)**
        Gib **ausschließlich** gültiges JSON zurück, ohne Einleitung oder Erklärungen.
        Beginne mit `{` und ende mit `}`.

        **Striktes JSON-Schema:**
        {
          "scores": {
            "aufgabe": 0.0–5.0,
            "kohaerenz": 0.0–5.0,
            "wortschatz": 0.0–5.0,
            "strukturen": 0.0–5.0
          },
          "checkpoints": [
            {"subpoint": "Textfrage 1", "covered": true, "evidence": "Beispielsatz"},
            ...
          ],
          "errors": [
            {"type": "orthografie", "sample": "besuhen", "hint": "Richtig: besuchen"},
            {"type": "grammatik", "sample": "Ich gehe ins Museum morgen", "hint": "Verb am Ende: Ich gehe morgen ins Museum"}
          ],
          "summary": "Kurze Gesamtbewertung (2–3 Sätze).",
          "improvements": ["Konkrete Verbesserungen..."],
          "model_suggestions": ["1–2 Beispielsätze auf B1-Niveau."],
          "improved_version": "VOLLSTÄNDIGER verbesserter Text mit allen Korrekturen, besserer Struktur und reichhaltigerem Wortschatz auf B1-Niveau.",
          "positive_aspects": ["Was gut gemacht wurde", "Stärken des Textes"],
          "negative_aspects": ["Was nicht gut war", "Schwächen des Textes"]
        }

        ---
        🔒 WICHTIGE BEWERTUNGSREGELN:
        - Thema verfehlt → aufgabe ≤ 2.0
        - Pro fehlendem Unterpunkt → −1.0 bei aufgabe
        - Pro 3 Fehler → −0.5 bei strukturen
        - Wenig Konnektoren → kohaerenz ≤ 3.0
        - Repetitiver Wortschatz → wortschatz ≤ 3.0
        - Perfekte Texte (5.0) sind extrem selten

        Antworte jetzt mit dem JSON-Ergebnis.
        """
    }

    // MARK: - API Call

    private func callOpenRouterAPI(prompt: String, model: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw LLMCheckerError.invalidResponse("Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/anthropics/claude-code", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("AITalkingApp/1.0", forHTTPHeaderField: "X-Title")

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a German language examiner. You ONLY respond with valid JSON. Never add explanations outside JSON."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2,
            "max_tokens": 2000,
            "response_format": ["type": "json_object"]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("🔄 Sending request to OpenRouter...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMCheckerError.invalidResponse("Invalid response type")
        }

        print("📡 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error: \(errorText)")
            throw LLMCheckerError.invalidResponse("API returned status \(httpResponse.statusCode): \(errorText)")
        }

        // Parse OpenRouter response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMCheckerError.invalidResponse("Could not parse API response")
        }

        print("✅ Received response, length: \(content.count) chars")
        print("📝 Response preview: \(String(content.prefix(200)))")

        return content
    }

    // MARK: - Response Parsing

    private func parseEvaluationResponse(_ responseText: String) throws -> WritingEvaluation {
        // Extract JSON from response (might contain markdown formatting)
        var jsonText = responseText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks if present (```json ... ```)
        if jsonText.contains("```") {
            // Find JSON between code blocks
            if let startRange = jsonText.range(of: "```json"),
               let endRange = jsonText.range(of: "```", range: startRange.upperBound..<jsonText.endIndex) {
                jsonText = String(jsonText[startRange.upperBound..<endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let startRange = jsonText.range(of: "```"),
                      let endRange = jsonText.range(of: "```", range: startRange.upperBound..<jsonText.endIndex) {
                jsonText = String(jsonText[startRange.upperBound..<endRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // If still has extra text, try to find JSON object
        if !jsonText.hasPrefix("{") {
            if let jsonStart = jsonText.range(of: "{") {
                jsonText = String(jsonText[jsonStart.lowerBound...])
            }
        }

        // Fix common JSON errors from LLMs
        // Fix missing comma after "summary" field: "text"\n  "improvements"
        jsonText = jsonText.replacingOccurrences(
            of: #""\n  "improvements""#,
            with: #"",\n  "improvements""#,
            options: .regularExpression
        )
        jsonText = jsonText.replacingOccurrences(
            of: #""\s+"improvements""#,
            with: #"", "improvements""#,
            options: .regularExpression
        )

        // Try to parse as-is first
        guard let data = jsonText.data(using: .utf8) else {
            throw LLMCheckerError.invalidResponse("Could not encode response as UTF-8")
        }

        let decoder = JSONDecoder()

        struct LLMResponse: Codable {
            let scores: Scores
            let checkpoints: [Checkpoint]
            let errors: [ErrorItem]
            let summary: String
            let improvements: [String]
            let model_suggestions: [String]?
            let improved_version: String?
            let positive_aspects: [String]?
            let negative_aspects: [String]?

            struct Scores: Codable {
                let aufgabe: Double
                let kohaerenz: Double
                let wortschatz: Double
                let strukturen: Double
            }

            struct Checkpoint: Codable {
                let subpoint: String
                let covered: Bool
                let evidence: String?
            }

            struct ErrorItem: Codable {
                let type: String
                let sample: String
                let hint: String
            }
        }

        do {
            let response = try decoder.decode(LLMResponse.self, from: data)

            print("📊 Scores received:")
            print("  Aufgabe: \(response.scores.aufgabe)")
            print("  Kohärenz: \(response.scores.kohaerenz)")
            print("  Wortschatz: \(response.scores.wortschatz)")
            print("  Strukturen: \(response.scores.strukturen)")

            // Convert to WritingEvaluation
            let rubricScores = WritingEvaluation.RubricScores(
                aufgabenerfuellung: response.scores.aufgabe,
                kohaerenz: response.scores.kohaerenz,
                wortschatz: response.scores.wortschatz,
                strukturen: response.scores.strukturen
            )

            let errors = response.errors.compactMap { errorItem -> WritingError? in
                guard let errorType = WritingError.ErrorType(rawValue: errorItem.type) else {
                    return nil
                }
                return WritingError(type: errorType, sample: errorItem.sample, hint: errorItem.hint)
            }

            let checkpoints = response.checkpoints.map { checkpoint in
                WritingEvaluation.CheckpointResult(
                    subpoint: checkpoint.subpoint,
                    covered: checkpoint.covered,
                    evidence: checkpoint.evidence
                )
            }

            return WritingEvaluation(
                scores: rubricScores,
                errors: errors,
                checkpoints: checkpoints,
                summary: response.summary,
                improvements: response.improvements,
                modelSuggestions: response.model_suggestions,
                improvedVersion: response.improved_version,
                positiveAspects: response.positive_aspects,
                negativeAspects: response.negative_aspects
            )

        } catch {
            print("❌ JSON parsing failed: \(error)")
            print("📄 JSON text: \(jsonText)")
            throw LLMCheckerError.invalidResponse("JSON parsing failed: \(error.localizedDescription)")
        }
    }
}
