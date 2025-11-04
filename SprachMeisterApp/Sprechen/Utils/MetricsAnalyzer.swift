//
//  MetricsAnalyzer.swift
//  SprachMeister
//
//  Created on 20.10.2025
//

import Foundation

/// Analyzes transcripts and generates feedback metrics
class MetricsAnalyzer {

    // MARK: - Filler Words Detection

    private static let germanFillerWords: Set<String> = [
        "äh", "ähm", "ehm", "öhm", "hm", "mhm",
        "also", "ja", "naja", "halt", "irgendwie",
        "sozusagen", "gewissermaßen", "quasi"
    ]

    /// Analyzes filler words in text
    static func analyzeFillerWords(in text: String) -> PracticeMetrics.FillerWordStats {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        var fillerCounts: [String: Int] = [:]

        for word in words {
            if germanFillerWords.contains(word) {
                fillerCounts[word, default: 0] += 1
            }
        }

        return PracticeMetrics.FillerWordStats(
            count: fillerCounts.values.reduce(0, +),
            types: fillerCounts
        )
    }

    // MARK: - Lexical Diversity

    /// Calculates lexical diversity (Type-Token Ratio)
    /// Returns value between 0.0 and 1.0
    static func calculateLexicalDiversity(in text: String) -> Double {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !germanFillerWords.contains($0) }

        guard !words.isEmpty else { return 0.0 }

        let uniqueWords = Set(words)
        let diversity = Double(uniqueWords.count) / Double(words.count)

        // Normalize to reasonable range (typical TTR is 0.4-0.8 for fluent speech)
        return min(1.0, diversity * 1.5)
    }

    // MARK: - Words Per Minute

    /// Calculates speaking rate (WPM)
    static func calculateWordsPerMinute(wordCount: Int, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0.0 }
        let minutes = duration / 60.0
        return Double(wordCount) / minutes
    }

    // MARK: - Word Counting

    /// Counts words in text (excluding fillers)
    static func countWords(in text: String, excludingFillers: Bool = false) -> Int {
        let words = text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        if excludingFillers {
            return words.filter { !germanFillerWords.contains($0.lowercased()) }.count
        }

        return words.count
    }

    // MARK: - Grammar Analysis (Lightweight)

    /// Performs basic grammar pattern analysis
    static func analyzeGrammar(in text: String) -> PracticeMetrics.GrammarScore {
        let articleErrors = detectArticleErrors(in: text)
        let verbPositionErrors = detectVerbPositionErrors(in: text)
        let tenseConsistency = analyzeTenseConsistency(in: text)

        return PracticeMetrics.GrammarScore(
            articleErrors: articleErrors,
            verbPositionErrors: verbPositionErrors,
            tenseConsistency: tenseConsistency
        )
    }

    // MARK: - Private Grammar Helpers

    /// Detects potential article errors (der/die/das patterns)
    private static func detectArticleErrors(in text: String) -> Int {
        var errorCount = 0
        let lowercased = text.lowercased()

        // Simple heuristic: look for "der" + feminine noun patterns (incomplete)
        // This is a placeholder - real implementation would need NLP
        let suspiciousPatterns = [
            "der frau", "der mutter", "der tochter", // should be "die"
            "die mann", "die vater", "die sohn",     // should be "der"
            "das junge", "das alte",                 // likely wrong
        ]

        for pattern in suspiciousPatterns {
            let matches = lowercased.components(separatedBy: pattern).count - 1
            errorCount += matches
        }

        return errorCount
    }

    /// Detects verb position errors in main clauses
    private static func detectVerbPositionErrors(in text: String) -> Int {
        // Simplified: In German main clauses, verb should be in position 2
        // This is a basic heuristic and not comprehensive
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var errorCount = 0

        for sentence in sentences {
            let words = sentence.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }

            // Skip very short sentences
            guard words.count >= 3 else { continue }

            // Check if position 2 contains a verb (very basic check)
            if words.count > 1 {
                let secondWord = words[1].lowercased()
                // Common non-verb words that shouldn't be in position 2 after subject
                let nonVerbs = ["der", "die", "das", "ein", "eine", "sehr", "auch"]
                if nonVerbs.contains(secondWord) {
                    errorCount += 1
                }
            }
        }

        return min(errorCount, 5) // cap at 5 to avoid over-penalizing
    }

    /// Analyzes tense consistency
    private static func analyzeTenseConsistency(in text: String) -> Double {
        let lowercased = text.lowercased()

        // Count past tense markers
        let pastMarkers = ["habe", "hatte", "bin", "war", "wurde"]
        let pastCount = pastMarkers.reduce(0) { count, marker in
            count + (lowercased.components(separatedBy: marker).count - 1)
        }

        // Count present tense markers
        let presentMarkers = ["ist", "sind", "hat", "macht", "geht"]
        let presentCount = presentMarkers.reduce(0) { count, marker in
            count + (lowercased.components(separatedBy: marker).count - 1)
        }

        let totalMarkers = pastCount + presentCount
        guard totalMarkers > 0 else { return 1.0 }

        // If one tense dominates (>70%), consider it consistent
        let dominantTenseRatio = Double(max(pastCount, presentCount)) / Double(totalMarkers)

        return dominantTenseRatio
    }

    // MARK: - Complete Metrics Generation

    /// Generates complete metrics from transcript
    static func generateMetrics(for attempt: PracticeAttempt) -> PracticeMetrics {
        let userText = attempt.transcript.userEntries
            .map { $0.text }
            .joined(separator: " ")

        let duration = attempt.transcript.duration
        let totalWords = countWords(in: userText)
        let wpm = calculateWordsPerMinute(wordCount: totalWords, duration: duration)
        let fillerWords = analyzeFillerWords(in: userText)
        let lexicalDiversity = calculateLexicalDiversity(in: userText)
        let grammarScore = analyzeGrammar(in: userText)

        return PracticeMetrics(
            attemptID: attempt.id,
            duration: duration,
            totalWords: totalWords,
            wordsPerMinute: wpm,
            fillerWords: fillerWords,
            lexicalDiversity: lexicalDiversity,
            grammarScore: grammarScore
        )
    }
}
