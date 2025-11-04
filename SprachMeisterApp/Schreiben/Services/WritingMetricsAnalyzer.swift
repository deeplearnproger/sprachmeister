//
//  WritingMetricsAnalyzer.swift
//  SprachMeister
//
//  Analyzes written text and generates metrics
//  Created on 23.10.2025
//

import Foundation

/// Analyzes writing attempts and generates metrics
class WritingMetricsAnalyzer {

    // MARK: - Complete Metrics Generation

    /// Generate complete writing metrics from text
    static func generateMetrics(
        attemptID: UUID,
        task: WritingTask,
        text: String,
        writingPace: [WritingMetrics.PaceInterval]
    ) -> WritingMetrics {

        let wordCount = countWords(in: text)
        let sentenceCount = countSentences(in: text)
        let avgSentenceLength = sentenceCount > 0 ? Double(wordCount) / Double(sentenceCount) : 0.0
        let ttr = calculateTypeTokenRatio(in: text)
        let phrasesUsed = detectPhrases(in: text)
        let subpointCoverage = analyzeSubpointCoverage(task: task, text: text)
        let level = estimateLevel(wordCount: wordCount, ttr: ttr, sentenceCount: sentenceCount)

        return WritingMetrics(
            attemptID: attemptID,
            wordCount: wordCount,
            sentenceCount: sentenceCount,
            avgSentenceLength: avgSentenceLength,
            typeTokenRatio: ttr,
            writingPace: writingPace,
            subpointCoverage: subpointCoverage,
            phrasesUsed: phrasesUsed,
            estimatedLevel: level
        )
    }

    // MARK: - Word Counting

    /// Count words in text
    static func countWords(in text: String) -> Int {
        text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .count
    }

    // MARK: - Sentence Counting

    /// Count sentences in text
    static func countSentences(in text: String) -> Int {
        let sentenceEndings = CharacterSet(charactersIn: ".!?")
        let sentences = text.components(separatedBy: sentenceEndings)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return max(1, sentences.count)
    }

    // MARK: - Type-Token Ratio (TTR)

    /// Calculate lexical diversity (Type-Token Ratio)
    /// Returns value between 0.0 and 1.0
    static func calculateTypeTokenRatio(in text: String) -> Double {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 } // Ignore very short words

        guard !words.isEmpty else { return 0.0 }

        let uniqueWords = Set(words)
        let ttr = Double(uniqueWords.count) / Double(words.count)

        // Safety check for NaN
        guard !ttr.isNaN && !ttr.isInfinite else { return 0.0 }

        // TTR for written German at B1 level typically 0.4-0.7
        return min(1.0, ttr)
    }

    // MARK: - Phrase Detection

    /// Detect common B1 phrases/connectors (Redemittel)
    static func detectPhrases(in text: String) -> [String] {
        let textLower = text.lowercased()
        var foundPhrases: [String] = []

        for phrase in commonB1Phrases {
            if textLower.contains(phrase.lowercased()) {
                foundPhrases.append(phrase)
            }
        }

        return foundPhrases
    }

    // Common B1 phrases and connectors
    private static let commonB1Phrases: [String] = [
        // Meinung
        "Meiner Meinung nach",
        "Ich bin der Meinung",
        "Ich denke, dass",
        "Ich glaube, dass",
        "Ich finde, dass",

        // Konnektoren
        "außerdem",
        "jedoch",
        "trotzdem",
        "deshalb",
        "deswegen",
        "darum",
        "dennoch",

        // Struktur
        "einerseits",
        "andererseits",
        "zum einen",
        "zum anderen",
        "zunächst",
        "zuerst",
        "dann",
        "danach",
        "schließlich",
        "zuletzt",

        // Beispiele
        "zum Beispiel",
        "beispielsweise",

        // Kontrast
        "im Gegensatz zu",
        "im Vergleich zu",
        "dagegen",

        // Zusammenfassung
        "zusammenfassend",
        "abschließend",
        "alles in allem",

        // E-Mail Formeln
        "Liebe Grüße",
        "Viele Grüße",
        "Mit freundlichen Grüßen",
        "Vielen Dank",
        "Es tut mir leid",
        "Ich möchte",
        "Ich würde gerne",
        "Könnten Sie",
        "Würden Sie"
    ]

    // MARK: - Subpoint Coverage Analysis

    /// Analyze how well text covers task subpoints
    static func analyzeSubpointCoverage(
        task: WritingTask,
        text: String
    ) -> [WritingMetrics.SubpointCoverage] {

        let textLower = text.lowercased()

        return task.subpoints.map { subpoint in
            let keywords = extractKeywords(from: subpoint)
            let matchCount = keywords.filter { textLower.contains($0.lowercased()) }.count
            let confidence = Double(matchCount) / max(1.0, Double(keywords.count))
            let covered = confidence >= 0.4 // At least 40% of keywords found

            let evidence = covered ? findEvidence(for: subpoint, keywords: keywords, in: text) : nil

            return WritingMetrics.SubpointCoverage(
                subpoint: subpoint,
                covered: covered,
                confidence: confidence,
                evidence: evidence
            )
        }
    }

    private static func extractKeywords(from subpoint: String) -> [String] {
        // Remove common question words and extract meaningful terms
        let stopWords: Set<String> = [
            "wie", "was", "warum", "wann", "wo", "wer", "welche", "welcher", "welches",
            "sind", "ist", "war", "waren", "hat", "haben", "bei", "ihnen", "ihrer",
            "ihrem", "die", "der", "das", "ein", "eine", "einen", "und", "oder"
        ]

        return subpoint
            .lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count > 3 && !stopWords.contains($0) }
    }

    private static func findEvidence(for subpoint: String, keywords: [String], in text: String) -> String? {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Find first sentence containing keywords
        for sentence in sentences {
            let sentenceLower = sentence.lowercased()
            for keyword in keywords {
                if sentenceLower.contains(keyword.lowercased()) {
                    // Truncate if too long
                    return sentence.count > 80
                        ? String(sentence.prefix(80)) + "..."
                        : sentence
                }
            }
        }

        return nil
    }

    // MARK: - Level Estimation

    /// Estimate CEFR level based on metrics
    static func estimateLevel(wordCount: Int, ttr: Double, sentenceCount: Int) -> String {
        var score = 0.0

        // Word count contribution
        if wordCount >= 120 {
            score += 1.0
        } else if wordCount >= 80 {
            score += 0.5
        }

        // TTR contribution
        if ttr >= 0.6 {
            score += 1.5
        } else if ttr >= 0.5 {
            score += 1.0
        } else if ttr >= 0.4 {
            score += 0.5
        }

        // Sentence variety contribution
        let avgSentenceLength = Double(wordCount) / max(1.0, Double(sentenceCount))
        if avgSentenceLength >= 12 && avgSentenceLength <= 20 {
            score += 1.0
        } else if avgSentenceLength >= 8 {
            score += 0.5
        }

        // Map score to level
        switch score {
        case 3.0...:
            return "B2"
        case 2.0..<3.0:
            return "B1+"
        case 1.5..<2.0:
            return "B1"
        case 1.0..<1.5:
            return "A2+"
        default:
            return "A2"
        }
    }

    // MARK: - Writing Pace Calculation

    /// Calculate writing pace over time intervals
    static func calculateWritingPace(
        snapshots: [(timestamp: TimeInterval, text: String)]
    ) -> [WritingMetrics.PaceInterval] {

        guard snapshots.count > 1 else { return [] }

        var paceIntervals: [WritingMetrics.PaceInterval] = []
        var previousWordCount = 0

        for (index, snapshot) in snapshots.enumerated() {
            let currentWordCount = countWords(in: snapshot.text)
            let wordsWritten = currentWordCount - previousWordCount

            // Calculate WPM for this interval
            let intervalDuration: Double
            if index == 0 {
                intervalDuration = snapshot.timestamp
            } else {
                intervalDuration = snapshot.timestamp - snapshots[index - 1].timestamp
            }

            let wpm = intervalDuration > 0
                ? Double(wordsWritten) / (intervalDuration / 60.0)
                : 0.0

            paceIntervals.append(WritingMetrics.PaceInterval(
                intervalStart: snapshot.timestamp,
                wordsWritten: wordsWritten,
                wordsPerMinute: wpm
            ))

            previousWordCount = currentWordCount
        }

        return paceIntervals
    }
}
