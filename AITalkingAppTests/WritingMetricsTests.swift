//
//  WritingMetricsTests.swift
//  SprachMeisterTests
//
//  Unit tests for WritingMetricsAnalyzer
//  Created on 23.10.2025
//

import XCTest
@testable import SprachMeister

final class WritingMetricsTests: XCTestCase {

    // MARK: - Word Counting Tests

    func testWordCount() {
        let text = "Das ist ein Test mit genau zehn Wörtern hier."
        let count = WritingMetricsAnalyzer.countWords(in: text)
        XCTAssertEqual(count, 10, "Should count exactly 10 words")
    }

    func testWordCountWithPunctuation() {
        let text = "Hallo, wie geht es dir? Mir geht's gut!"
        let count = WritingMetricsAnalyzer.countWords(in: text)
        XCTAssertEqual(count, 9, "Should count words ignoring punctuation")
    }

    func testWordCountEmpty() {
        let count = WritingMetricsAnalyzer.countWords(in: "")
        XCTAssertEqual(count, 0, "Empty string should have 0 words")
    }

    // MARK: - Sentence Counting Tests

    func testSentenceCount() {
        let text = "Das ist Satz eins. Das ist Satz zwei! Und das ist Satz drei?"
        let count = WritingMetricsAnalyzer.countSentences(in: text)
        XCTAssertEqual(count, 3, "Should count 3 sentences")
    }

    func testSentenceCountSingle() {
        let text = "Nur ein Satz"
        let count = WritingMetricsAnalyzer.countSentences(in: text)
        XCTAssertEqual(count, 1, "Should count at least 1 sentence even without ending punctuation")
    }

    // MARK: - Type-Token Ratio Tests

    func testTypeTokenRatio() {
        let text = "Ich gehe in die Schule. Die Schule ist groß."
        let ttr = WritingMetricsAnalyzer.calculateTypeTokenRatio(in: text)

        // Unique words: ich, gehe, die, schule, ist, groß (6)
        // Total words: 10
        // TTR should be around 0.6
        XCTAssertGreaterThan(ttr, 0.5, "TTR should be greater than 0.5")
        XCTAssertLessThan(ttr, 0.8, "TTR should be less than 0.8")
    }

    func testTypeTokenRatioAllUnique() {
        let text = "Jedes Wort ist hier unterschiedlich neu"
        let ttr = WritingMetricsAnalyzer.calculateTypeTokenRatio(in: text)
        XCTAssertGreaterThan(ttr, 0.8, "TTR should be high for unique words")
    }

    // MARK: - Phrase Detection Tests

    func testPhraseDetection() {
        let text = "Meiner Meinung nach ist das gut. Außerdem gibt es Vorteile."
        let phrases = WritingMetricsAnalyzer.detectPhrases(in: text)

        XCTAssertTrue(phrases.contains("Meiner Meinung nach"), "Should detect 'Meiner Meinung nach'")
        XCTAssertTrue(phrases.contains("außerdem"), "Should detect 'außerdem'")
        XCTAssertGreaterThan(phrases.count, 0, "Should detect at least one phrase")
    }

    func testPhraseDetectionNone() {
        let text = "Das ist ein einfacher Text ohne Redemittel."
        let phrases = WritingMetricsAnalyzer.detectPhrases(in: text)
        XCTAssertEqual(phrases.count, 0, "Should not detect phrases when none present")
    }

    // MARK: - Subpoint Coverage Tests

    func testSubpointCoverageAllCovered() {
        let task = WritingTask(
            type: .forumPost,
            topic: "Test",
            situation: "Test situation",
            subpoints: [
                "Wie ist Ihre Erfahrung?",
                "Was sind die Vorteile?",
                "Was sind die Nachteile?"
            ]
        )

        let text = """
        Ich habe viel Erfahrung mit diesem Thema. Die Vorteile sind sehr gut.
        Aber es gibt auch einige Nachteile, die man bedenken muss.
        """

        let coverage = WritingMetricsAnalyzer.analyzeSubpointCoverage(task: task, text: text)

        XCTAssertEqual(coverage.count, 3, "Should have coverage for all 3 subpoints")

        let coveredCount = coverage.filter { $0.covered }.count
        XCTAssertEqual(coveredCount, 3, "All subpoints should be covered")
    }

    func testSubpointCoveragePartial() {
        let task = WritingTask(
            type: .forumPost,
            topic: "Test",
            situation: "Test situation",
            subpoints: [
                "Ihre Meinung zum Thema",
                "Die wirtschaftlichen Aspekte",
                "Die kulturellen Unterschiede"
            ]
        )

        let text = "Meiner Meinung nach ist das sehr wichtig für die Kultur."

        let coverage = WritingMetricsAnalyzer.analyzeSubpointCoverage(task: task, text: text)

        let coveredCount = coverage.filter { $0.covered }.count
        XCTAssertGreaterThan(coveredCount, 0, "Should cover at least one subpoint")
        XCTAssertLessThan(coveredCount, 3, "Should not cover all subpoints")
    }

    // MARK: - Level Estimation Tests

    func testLevelEstimationB1() {
        let level = WritingMetricsAnalyzer.estimateLevel(
            wordCount: 150,
            ttr: 0.6,
            sentenceCount: 10
        )
        XCTAssertEqual(level, "B1+" , "Should estimate B1+ for good metrics")
    }

    func testLevelEstimationA2() {
        let level = WritingMetricsAnalyzer.estimateLevel(
            wordCount: 70,
            ttr: 0.35,
            sentenceCount: 15
        )
        XCTAssertEqual(level, "A2", "Should estimate A2 for lower metrics")
    }

    func testLevelEstimationB2() {
        let level = WritingMetricsAnalyzer.estimateLevel(
            wordCount: 200,
            ttr: 0.7,
            sentenceCount: 12
        )
        XCTAssertEqual(level, "B2", "Should estimate B2 for excellent metrics")
    }

    // MARK: - Complete Metrics Generation Test

    func testCompleteMetricsGeneration() {
        let task = WritingTask.defaultTasks[0]
        let text = """
        Meiner Meinung nach sind Hausaufgaben sehr wichtig für Schüler. Sie helfen beim Lernen.
        Außerdem können die Schüler zu Hause üben. Es gibt aber auch Nachteile.
        Manchmal haben Schüler zu viele Hausaufgaben und keine Freizeit mehr.
        """

        let metrics = WritingMetricsAnalyzer.generateMetrics(
            attemptID: UUID(),
            task: task,
            text: text,
            writingPace: []
        )

        XCTAssertGreaterThan(metrics.wordCount, 0, "Should count words")
        XCTAssertGreaterThan(metrics.sentenceCount, 0, "Should count sentences")
        XCTAssertGreaterThan(metrics.typeTokenRatio, 0, "Should calculate TTR")
        XCTAssertGreaterThan(metrics.phrasesUsed.count, 0, "Should detect phrases")
        XCTAssertFalse(metrics.estimatedLevel.isEmpty, "Should estimate level")
    }
}
