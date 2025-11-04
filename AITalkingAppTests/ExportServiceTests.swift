//
//  ExportServiceTests.swift
//  SprachMeisterTests
//
//  Unit tests for ExportService
//  Created on 23.10.2025
//

import XCTest
@testable import SprachMeister

final class ExportServiceTests: XCTestCase {

    var testAttempt: WritingAttempt!

    override func setUp() {
        super.setUp()

        let task = WritingTask(
            type: .forumPost,
            topic: "Test Topic",
            situation: "Test situation",
            subpoints: ["Point 1", "Point 2"]
        )

        let metrics = WritingMetrics(
            attemptID: UUID(),
            wordCount: 150,
            sentenceCount: 8,
            avgSentenceLength: 18.75,
            typeTokenRatio: 0.65,
            writingPace: [],
            subpointCoverage: [],
            phrasesUsed: ["Meiner Meinung nach"],
            estimatedLevel: "B1"
        )

        testAttempt = WritingAttempt(
            task: task,
            text: "This is a test text.",
            duration: 300,
            metrics: metrics
        )
    }

    // MARK: - JSON Export Tests

    func testExportAttemptToJSON() throws {
        let data = try ExportService.exportAttempt(testAttempt)

        XCTAssertGreaterThan(data.count, 0, "Exported data should not be empty")

        // Verify it's valid JSON
        let decoded = try JSONDecoder().decode(WritingAttempt.self, from: data)
        XCTAssertEqual(decoded.id, testAttempt.id, "Decoded ID should match original")
        XCTAssertEqual(decoded.text, testAttempt.text, "Decoded text should match original")
    }

    func testExportAttemptToPrettyJSON() throws {
        let data = try ExportService.exportAttempt(testAttempt, format: .prettyJSON)

        XCTAssertGreaterThan(data.count, 0, "Exported data should not be empty")

        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(jsonString, "Should convert to string")
        XCTAssertTrue(jsonString!.contains("\n"), "Pretty JSON should contain newlines")
    }

    func testExportAttemptToFile() throws {
        let url = try ExportService.exportAttemptToFile(testAttempt)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "File should exist")
        XCTAssertTrue(url.lastPathComponent.contains("Schreiben"), "Filename should contain 'Schreiben'")
        XCTAssertEqual(url.pathExtension, "json", "File extension should be .json")

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Multiple Attempts Export Tests

    func testExportMultipleAttempts() throws {
        let attempts = [testAttempt, testAttempt] // Two identical attempts for testing

        let data = try ExportService.exportAttempts(attempts)

        XCTAssertGreaterThan(data.count, 0, "Exported data should not be empty")

        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json, "Should be valid JSON")
        XCTAssertEqual(json?["totalAttempts"] as? Int, 2, "Should have correct count")
    }

    // MARK: - Analytics Export Tests

    func testExportAnalytics() throws {
        let attempts = [testAttempt]

        let data = try ExportService.exportAnalytics(attempts: attempts)

        XCTAssertGreaterThan(data.count, 0, "Exported data should not be empty")

        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json, "Should be valid JSON")
        XCTAssertNotNil(json?["totalAttempts"], "Should contain totalAttempts")
        XCTAssertNotNil(json?["averageWordCount"], "Should contain averageWordCount")
    }

    func testExportAnalyticsToFile() throws {
        let attempts = [testAttempt]

        let url = try ExportService.exportAnalyticsToFile(attempts: attempts)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "File should exist")
        XCTAssertTrue(url.lastPathComponent.contains("Analytics"), "Filename should contain 'Analytics'")

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }
}
