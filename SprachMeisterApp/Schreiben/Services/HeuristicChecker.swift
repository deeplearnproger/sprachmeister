//
//  HeuristicChecker.swift
//  SprachMeister
//
//  Fallback checker using heuristic rules (no LLM required)
//  Created on 23.10.2025
//

import Foundation

/// Heuristic-based writing checker (offline fallback)
@MainActor
class HeuristicChecker: LLMChecker {

    // MARK: - LLMChecker Protocol

    nonisolated var isAvailable: Bool {
        true // Always available
    }

    nonisolated var checkerName: String {
        "Heuristik (offline)"
    }

    func checkWriting(
        task: WritingTask,
        text: String,
        metrics: WritingMetrics
    ) async throws -> WritingEvaluation {

        // NOTE: No minimum word count validation - penalty is applied in score calculation
        // This allows users to submit early with lower scores
        print("🔍 Heuristic checker: Task '\(task.topic)', \(metrics.wordCount) words")

        // Run heuristic analyses
        let scores = calculateScores(task: task, text: text, metrics: metrics)
        let errors = detectErrors(text: text)
        let checkpoints = checkSubpoints(task: task, text: text)
        let summary = generateSummary(scores: scores, metrics: metrics, task: task)
        let improvements = generateImprovements(scores: scores, metrics: metrics, errors: errors)

        return WritingEvaluation(
            scores: scores,
            errors: errors,
            checkpoints: checkpoints,
            summary: summary,
            improvements: improvements,
            modelSuggestions: nil,
            improvedVersion: nil, // Heuristic checker doesn't generate improved versions
            positiveAspects: nil,
            negativeAspects: nil
        )
    }

    // MARK: - Score Calculation

    private func calculateScores(task: WritingTask, text: String, metrics: WritingMetrics) -> WritingEvaluation.RubricScores {

        // 1. Aufgabenerfüllung: Based on topic relevance + subpoint coverage + word count
        let coveredPoints = checkSubpoints(task: task, text: text).filter { $0.covered }.count
        let totalSubpoints = max(1, task.subpoints.count)

        // Check topic relevance (КРИТИЧНО!)
        let topicRelevance = checkTopicRelevance(task: task, text: text)

        // Check word count penalty
        let wordCountPenalty = calculateWordCountPenalty(actual: metrics.wordCount, expected: task.type.minWords)

        // Calculate Aufgabe score: topic (40%) + coverage (40%) + word count (20%)
        var aufgabeScore = (topicRelevance * 0.4 + (Double(coveredPoints) / Double(totalSubpoints)) * 0.4 + wordCountPenalty * 0.2) * 5.0
        aufgabeScore = min(5.0, max(0, aufgabeScore))

        // 2. Kohärenz: Based on connectors and structure
        let connectorCount = countConnectors(in: text)
        let prefixLength = min(50, text.count)
        let hasIntro = text.lowercased().contains("ich") && text.prefix(prefixLength).contains("bin")
        let hasConclusion = text.lowercased().contains("meinung") || text.lowercased().contains("zusammenfassend")
        var kohaerenzScore = 2.0
        kohaerenzScore += Double(min(connectorCount, 10)) * 0.2
        if hasIntro { kohaerenzScore += 0.5 }
        if hasConclusion { kohaerenzScore += 0.5 }
        kohaerenzScore = min(5.0, max(0, kohaerenzScore))

        // 3. Wortschatz: Based on TTR and phrase diversity
        let validTTR = max(0, min(1, metrics.typeTokenRatio)) // Clamp TTR between 0 and 1
        var wortschatzScore = validTTR * 5.0
        let phrasesFound = metrics.phrasesUsed.count
        wortschatzScore += Double(min(phrasesFound, 5)) * 0.2
        wortschatzScore = min(5.0, max(0, wortschatzScore))

        // 4. Strukturen: Based on detected errors
        let errorCount = detectErrors(text: text).count
        var strukturenScore = 5.0 - Double(errorCount) * 0.3
        strukturenScore = min(5.0, max(1.0, strukturenScore))

        return WritingEvaluation.RubricScores(
            aufgabenerfuellung: aufgabeScore,
            kohaerenz: kohaerenzScore,
            wortschatz: wortschatzScore,
            strukturen: strukturenScore
        )
    }

    // MARK: - Subpoint Coverage (ДЕТАЛЬНАЯ ПРОВЕРКА!)

    private func checkSubpoints(task: WritingTask, text: String) -> [WritingEvaluation.CheckpointResult] {
        print("📋 Checking subpoints for task: \(task.topic)")

        let sentences = splitIntoSentences(text)

        return task.subpoints.enumerated().map { index, subpoint in
            print("  Subpoint \(index + 1): \(subpoint)")

            // Детальная проверка каждого подпункта
            let analysis = analyzeSubpointCoverage(subpoint: subpoint, sentences: sentences, text: text)

            print("    ✓ Covered: \(analysis.covered), Evidence: \(analysis.evidence ?? "none")")

            return WritingEvaluation.CheckpointResult(
                subpoint: subpoint,
                covered: analysis.covered,
                evidence: analysis.evidence
            )
        }
    }

    private func analyzeSubpointCoverage(subpoint: String, sentences: [String], text: String) -> (covered: Bool, evidence: String?) {
        let keywords = extractKeywords(from: subpoint)

        // Ищем предложения, которые содержат ключевые слова
        var bestMatch: (score: Int, sentence: String)? = nil

        for sentence in sentences {
            let sentenceLower = sentence.lowercased()
            let matchedKeywords = keywords.filter { sentenceLower.contains($0) }

            if matchedKeywords.count > 0 {
                if bestMatch == nil || matchedKeywords.count > bestMatch!.score {
                    bestMatch = (matchedKeywords.count, sentence)
                }
            }
        }

        // Считаем покрытым, если найдено хотя бы 30% ключевых слов
        let threshold = max(1, keywords.count * 30 / 100)
        let covered = (bestMatch?.score ?? 0) >= threshold

        return (covered, bestMatch?.sentence)
    }

    private func extractKeywords(from subpoint: String) -> [String] {
        let stopWords = ["wie", "was", "warum", "wann", "wo", "wer", "welche", "sind", "ist", "war", "waren", "bei", "ihnen", "ihrer", "ihrem", "die", "der", "das", "den", "dem", "eine", "einer", "einem", "und", "oder", "aber", "doch", "haben", "hat", "wird", "werden"]

        return subpoint
            .lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count > 3 && !stopWords.contains($0) }
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        return text
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Error Detection (РЕАЛЬНЫЕ ОШИБКИ ИЗ ТЕКСТА!)

    private func detectErrors(text: String) -> [WritingError] {
        print("🔍 Analyzing text for errors...")
        var errors: [WritingError] = []

        let sentences = splitIntoSentences(text)

        // 1. Орфографические ошибки (конкретные слова!)
        errors.append(contentsOf: detectSpellingErrors(in: text))

        // 2. Ошибки в написании существительных с большой буквы
        errors.append(contentsOf: detectCaseErrors(in: text))

        // 3. Пунктуация (запятые перед weil, dass, etc.)
        errors.append(contentsOf: detectPunctuationErrors(in: text, sentences: sentences))

        // 4. Морфология (неправильные окончания, артикли)
        errors.append(contentsOf: detectMorphologyErrors(in: text))

        // 5. Синтаксис (порядок слов в придаточных)
        errors.append(contentsOf: detectSyntaxErrors(in: text, sentences: sentences))

        print("  ✓ Found \(errors.count) total errors")
        errors.prefix(5).enumerated().forEach { index, error in
            print("    \(index + 1). [\(error.type.rawValue)] '\(error.sample)' → \(error.hint)")
        }

        // Возвращаем top 10 самых важных ошибок
        return Array(errors.prefix(10))
    }

    private func detectSpellingErrors(in text: String) -> [WritingError] {
        var errors: [WritingError] = []

        let commonMistakes: [String: String] = [
            "besuhen": "besuchen",
            "vieleicht": "vielleicht",
            "nähmlich": "nämlich",
            "standart": "Standard",
            "immer": "immer", // placeholder
            "wiederrum": "wiederum"
        ]

        for (wrong, correct) in commonMistakes {
            if text.lowercased().contains(wrong) {
                errors.append(WritingError(
                    type: .orthografie,
                    sample: wrong,
                    hint: "Richtig: \(correct)"
                ))
            }
        }

        return errors
    }

    private func detectCaseErrors(in text: String) -> [WritingError] {
        var errors: [WritingError] = []

        // Common nouns that should be capitalized
        let nouns = ["schule", "universität", "arbeit", "familie", "freund", "haus", "stadt", "land", "zeit", "tag"]

        for noun in nouns {
            // Check if word appears lowercase in middle of sentence
            let pattern = "\\s\(noun)\\s"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                errors.append(WritingError(
                    type: .orthografie,
                    sample: noun,
                    hint: "Nomen groß schreiben: \(noun.capitalized)"
                ))
            }
        }

        return Array(errors.prefix(3)) // Limit case errors
    }

    private func detectPunctuationErrors(in text: String, sentences: [String]) -> [WritingError] {
        var errors: [WritingError] = []

        // Check for missing commas before "weil", "dass", "obwohl"
        let conjunctions = ["weil", "dass", "obwohl", "wenn"]

        for conj in conjunctions {
            let pattern = "[^ ,]\(conj)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let sample = String(text[range])
                errors.append(WritingError(
                    type: .zeichensetzung,
                    sample: sample,
                    hint: "Komma vor '\(conj)' fehlt"
                ))
            }
        }

        return Array(errors.prefix(3))
    }

    private func detectMorphologyErrors(in text: String) -> [WritingError] {
        var errors: [WritingError] = []

        // 1. Common article errors (der/die/das confusion)
        let articleErrors: [(pattern: String, wrong: String, hint: String)] = [
            ("\\bder Restaurant\\b", "der Restaurant", "Richtig: das Restaurant (neutrum)"),
            ("\\bdie Mann\\b", "die Mann", "Richtig: der Mann (maskulinum)"),
            ("\\bdas Frau\\b", "das Frau", "Richtig: die Frau (femininum)"),
            ("\\bin der Arbeit\\b", "in der Arbeit", "Richtig: bei der Arbeit oder in die Arbeit (Akkusativ)"),
            ("\\bzu Haus\\b", "zu Haus", "Richtig: nach Hause oder zu Hause")
        ]

        for error in articleErrors {
            if let regex = try? NSRegularExpression(pattern: error.pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let sample = String(text[range])
                errors.append(WritingError(
                    type: .morphologie,
                    sample: sample,
                    hint: error.hint
                ))
            }
        }

        // 2. Adjective ending errors (common B1 mistakes)
        let adjErrors: [(pattern: String, wrong: String, hint: String)] = [
            ("\\bein gute\\b", "ein gute", "Adjektivendung fehlt: ein guter (maskulinum) / eine gute (femininum)"),
            ("\\bder schnell\\b", "der schnell", "Adjektivendung fehlt: der schnelle"),
            ("\\beine schön\\b", "eine schön", "Adjektivendung fehlt: eine schöne")
        ]

        for error in adjErrors {
            if let regex = try? NSRegularExpression(pattern: error.pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let sample = String(text[range])
                errors.append(WritingError(
                    type: .morphologie,
                    sample: sample,
                    hint: error.hint
                ))
            }
        }

        // 3. Verb conjugation errors
        let verbErrors: [(pattern: String, wrong: String, hint: String)] = [
            ("\\bich hast\\b", "ich hast", "Richtig: ich habe (1. Person Singular)"),
            ("\\ber habe\\b", "er habe", "Richtig: er hat (3. Person Singular)"),
            ("\\bdu hat\\b", "du hat", "Richtig: du hast (2. Person Singular)"),
            ("\\bwir ist\\b", "wir ist", "Richtig: wir sind (1. Person Plural)")
        ]

        for error in verbErrors {
            if let regex = try? NSRegularExpression(pattern: error.pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let sample = String(text[range])
                errors.append(WritingError(
                    type: .morphologie,
                    sample: sample,
                    hint: error.hint
                ))
            }
        }

        return Array(errors.prefix(5))
    }

    private func detectSyntaxErrors(in text: String, sentences: [String]) -> [WritingError] {
        var errors: [WritingError] = []

        // Analyze each sentence for word order issues
        for sentence in sentences {
            let sentenceLower = sentence.lowercased()

            // 1. Verb position in subordinate clauses (after weil, dass, etc.)
            // Pattern: conjunction + ... + verb too early (not at end)
            let subordinateConjunctions = ["weil", "dass", "obwohl", "wenn", "ob", "als"]

            for conj in subordinateConjunctions {
                // Look for: "weil ich bin" instead of "weil ich ... bin"
                // Simple check: if conjugated verb appears right after pronoun in subordinate clause
                let patterns = [
                    "\\b\(conj)\\s+(ich|du|er|sie|es|wir|ihr)\\s+(bin|bist|ist|sind|seid|hat|habe|hast|haben|habt|kann|kannst|können|könnt|muss|musst|müssen|müsst)\\s+",
                    "\\b\(conj)\\s+(ich|du|er|sie|es|wir|ihr)\\s+(arbeite|arbeitest|arbeitet|arbeiten|arbeitet)\\s+"
                ]

                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                       let match = regex.firstMatch(in: sentenceLower, range: NSRange(sentenceLower.startIndex..., in: sentenceLower)),
                       let range = Range(match.range, in: sentenceLower) {
                        let sample = String(sentenceLower[range]).trimmingCharacters(in: .whitespaces)

                        // Check if this is actually wrong (verb should be at end)
                        // Skip if sentence is very short (might be fragment)
                        if sentence.count > 20 {
                            errors.append(WritingError(
                                type: .syntax,
                                sample: sample,
                                hint: "In Nebensätzen steht das Verb am Ende: '\(conj) ich ... [verb]'"
                            ))
                        }
                    }
                }
            }

            // 2. Main clause verb position (V2 - verb in second position)
            // Check if sentence starts with time/place expression but verb is not second
            let v2Triggers = ["gestern", "heute", "morgen", "dann", "danach", "dort", "hier", "jetzt", "manchmal", "oft", "immer"]

            for trigger in v2Triggers {
                // Pattern: trigger + subject + ... + verb (should be: trigger + verb + subject)
                let pattern = "^\\s*\(trigger)\\s+(ich|du|er|sie|es|wir|ihr|man)\\s+[a-zäöüß]+\\s+(bin|bist|ist|sind|habe|hast|hat|haben|kann|kannst|können|muss|musst|müssen)"

                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   regex.firstMatch(in: sentenceLower, range: NSRange(sentenceLower.startIndex..., in: sentenceLower)) != nil {

                    // Extract first 40 chars as sample
                    let sampleEnd = sentenceLower.index(sentenceLower.startIndex, offsetBy: min(40, sentenceLower.count))
                    let sample = String(sentenceLower[..<sampleEnd])

                    errors.append(WritingError(
                        type: .syntax,
                        sample: sample,
                        hint: "Nach '\(trigger)' steht das Verb an 2. Position: '\(trigger) + Verb + Subjekt'"
                    ))
                }
            }
        }

        return Array(errors.prefix(5))
    }

    // MARK: - Topic Relevance Check

    /// Проверяет соответствие текста теме задания
    /// Возвращает значение от 0.0 (полностью не по теме) до 1.0 (полностью по теме)
    private func checkTopicRelevance(task: WritingTask, text: String) -> Double {
        let textLower = text.lowercased()

        // Extract keywords from topic and situation
        let topicKeywords = extractTopicKeywords(from: task.topic + " " + task.situation)

        // Check how many topic keywords appear in text
        let matchedKeywords = topicKeywords.filter { keyword in
            textLower.contains(keyword.lowercased())
        }

        let relevanceRatio = topicKeywords.isEmpty ? 1.0 : Double(matchedKeywords.count) / Double(topicKeywords.count)

        // If less than 20% keywords match => probably wrong topic!
        if relevanceRatio < 0.2 {
            print("⚠️ WARNUNG: Text scheint NICHT zum Thema '\(task.topic)' zu passen! Nur \(matchedKeywords.count)/\(topicKeywords.count) Schlüsselwörter gefunden.")
        }

        return relevanceRatio
    }

    private func extractTopicKeywords(from text: String) -> [String] {
        let stopWords = ["und", "oder", "aber", "die", "der", "das", "ein", "eine", "in", "im", "an", "am", "zu", "zum", "zur", "von", "vom", "mit", "für", "auf", "über", "bei", "sie", "ist", "sind", "hat", "haben", "wird", "werden", "ihr", "ihre", "sein", "seine"]

        return text
            .lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count > 3 && !stopWords.contains($0) }
    }

    // MARK: - Word Count Penalty

    /// Calculates penalty for insufficient word count
    /// Returns 1.0 if word count is OK, less if too short
    private func calculateWordCountPenalty(actual: Int, expected: Int) -> Double {
        if actual >= expected {
            return 1.0 // No penalty
        } else if actual >= expected * 70 / 100 {
            return 0.8 // 20% penalty for 70-99% words
        } else if actual >= expected * 50 / 100 {
            return 0.5 // 50% penalty for 50-69% words
        } else {
            return 0.2 // 80% penalty for <50% words
        }
    }

    // MARK: - Connector Counting

    private func countConnectors(in text: String) -> Int {
        let connectors = [
            "außerdem", "jedoch", "deshalb", "deswegen", "trotzdem", "dennoch",
            "erstens", "zweitens", "drittens", "einerseits", "andererseits",
            "zuerst", "dann", "danach", "schließlich", "zuletzt",
            "zum beispiel", "beispielsweise", "meiner meinung nach"
        ]

        let textLower = text.lowercased()
        return connectors.filter { textLower.contains($0) }.count
    }

    // MARK: - Feedback Generation

    private func generateSummary(scores: WritingEvaluation.RubricScores, metrics: WritingMetrics, task: WritingTask) -> String {
        let level = scores.level.rawValue
        let wordCount = metrics.wordCount
        let minWords = task.type.minWords

        var summary = "Ihr Text wurde mit \(level) bewertet. "

        // Word count feedback
        if wordCount < minWords {
            let missing = minWords - wordCount
            summary += "⚠️ Der Text ist zu kurz (fehlen \(missing) Wörter). "
        } else if wordCount < minWords * 80 / 100 {
            summary += "Der Text ist etwas zu kurz. "
        }

        // Task fulfillment feedback with emphasis on topic relevance
        if scores.aufgabenerfuellung >= 4.0 {
            summary += "Sie haben die Aufgabe sehr gut erfüllt."
        } else if scores.aufgabenerfuellung >= 3.0 {
            summary += "Die meisten Punkte wurden behandelt."
        } else if scores.aufgabenerfuellung >= 1.5 {
            summary += "⚠️ Einige wichtige Punkte fehlen oder der Text passt nicht ganz zum Thema."
        } else {
            summary += "❌ ACHTUNG: Der Text entspricht NICHT der Aufgabe oder dem Thema!"
        }

        return summary
    }

    private func generateImprovements(scores: WritingEvaluation.RubricScores, metrics: WritingMetrics, errors: [WritingError]) -> [String] {
        var improvements: [String] = []

        // КРИТИЧНО: Если задание не выполнено - это главное!
        if scores.aufgabenerfuellung < 1.5 {
            improvements.append("❗️WICHTIG: Schreiben Sie zum gegebenen Thema! Ihr Text behandelt ein anderes Thema.")
        } else if scores.aufgabenerfuellung < 3.0 {
            improvements.append("Gehen Sie auf alle Punkte der Aufgabe ein")
        }

        if scores.kohaerenz < 3.5 {
            improvements.append("Mehr Konnektoren verwenden (z.B. 'außerdem', 'jedoch', 'deshalb')")
        }

        if scores.wortschatz < 3.5 {
            improvements.append("Versuchen Sie, abwechslungsreichere Vokabeln zu verwenden")
        }

        if errors.filter({ $0.type == .orthografie }).count > 2 {
            improvements.append("Auf Rechtschreibung achten, besonders bei langen Wörtern")
        }

        if errors.filter({ $0.type == .zeichensetzung }).count > 2 {
            improvements.append("Kommas vor Nebensätzen (weil, dass, wenn) nicht vergessen")
        }

        if metrics.typeTokenRatio < 0.5 {
            improvements.append("Vermeiden Sie zu viele Wortwiederholungen")
        }

        if improvements.isEmpty {
            improvements.append("Sehr gute Arbeit! Weiter so!")
        }

        return Array(improvements.prefix(5))
    }
}
