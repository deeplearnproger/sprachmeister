//
//  WritingResultView.swift
//  SprachMeister
//
//  Premium results view with Design System
//  Created on 24.10.2025
//

import SwiftUI

/// Premium results view after checking writing
struct WritingResultView: View {

    let attempt: WritingAttempt
    @ObservedObject var storage: WritingStorageService
    var onDismissAll: (() -> Void)? = nil

    @State private var showingTextReview = false
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showToast = false
    @State private var toastMessage = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.spacing.lg) {

                    // MARK: - Overall Score Dial
                    if let evaluation = attempt.evaluation {
                        DSScoreDial(
                            score: evaluation.scores.overall,
                            title: "Gesamtbewertung"
                        )
                        .padding(.top, Theme.spacing.lg)
                        .padding(.bottom, Theme.spacing.md)

                        // MARK: - Summary
                        if !evaluation.summary.isEmpty {
                            DSCard {
                                VStack(alignment: .leading, spacing: Theme.spacing.sm) {
                                    Label("Zusammenfassung", systemImage: "text.alignleft")
                                        .font(Theme.typography.titleMedium)
                                        .foregroundStyle(Color.primary)

                                    Text(evaluation.summary)
                                        .font(Theme.typography.bodyMedium)
                                        .foregroundStyle(Color.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        // MARK: - Rubric Scores (4 criteria)
                        DSCard {
                            VStack(alignment: .leading, spacing: Theme.spacing.md) {
                                Label("Bewertungskriterien", systemImage: "chart.bar.fill")
                                    .font(Theme.typography.titleMedium)
                                    .foregroundStyle(Color.primary)

                                Divider()

                                DSProgressBar(
                                    title: "Aufgabenerfüllung",
                                    value: evaluation.scores.aufgabenerfuellung
                                )

                                DSProgressBar(
                                    title: "Kohärenz",
                                    value: evaluation.scores.kohaerenz
                                )

                                DSProgressBar(
                                    title: "Wortschatz",
                                    value: evaluation.scores.wortschatz
                                )

                                DSProgressBar(
                                    title: "Strukturen",
                                    value: evaluation.scores.strukturen
                                )
                            }
                        }

                        // MARK: - Metrics Grid
                        DSCard {
                            VStack(alignment: .leading, spacing: Theme.spacing.md) {
                                Label("Textstatistiken", systemImage: "chart.xyaxis.line")
                                    .font(Theme.typography.titleMedium)
                                    .foregroundStyle(Color.primary)

                                Divider()

                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ],
                                    spacing: Theme.spacing.sm
                                ) {
                                    DSInfoTile(
                                        icon: "text.word.spacing",
                                        value: "\(attempt.metrics.wordCount)",
                                        label: "Wörter",
                                        iconColor: ColorPalette.fallbackPrimary
                                    )

                                    DSInfoTile(
                                        icon: "textformat.size",
                                        value: "\(attempt.metrics.sentenceCount)",
                                        label: "Sätze",
                                        iconColor: ColorPalette.fallbackSecondary
                                    )

                                    DSInfoTile(
                                        icon: "clock",
                                        value: attempt.durationFormatted,
                                        label: "Dauer",
                                        iconColor: ColorPalette.fallbackWarning
                                    )

                                    DSInfoTile(
                                        icon: "speedometer",
                                        value: String(format: "%.1f", attempt.wordsPerMinute),
                                        label: "Wörter/Min",
                                        iconColor: ColorPalette.fallbackPrimary
                                    )

                                    DSInfoTile(
                                        icon: "chart.bar",
                                        value: String(format: "%.2f", attempt.metrics.typeTokenRatio),
                                        label: "TTR",
                                        iconColor: ColorPalette.fallbackSecondary
                                    )

                                    DSInfoTile(
                                        icon: "graduationcap",
                                        value: attempt.metrics.estimatedLevel,
                                        label: "Niveau",
                                        iconColor: ColorPalette.fallbackSuccess
                                    )
                                }
                            }
                        }

                        // MARK: - Checkpoints (Subpoints)
                        if !evaluation.checkpoints.isEmpty {
                            DSCard {
                                VStack(alignment: .leading, spacing: Theme.spacing.md) {
                                    Label("Inhaltspunkte", systemImage: "checklist")
                                        .font(Theme.typography.titleMedium)
                                        .foregroundStyle(Color.primary)

                                    Divider()

                                    ForEach(Array(evaluation.checkpoints.enumerated()), id: \.offset) { index, checkpoint in
                                        HStack(alignment: .top, spacing: Theme.spacing.sm) {
                                            Image(systemName: checkpoint.covered ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(checkpoint.covered ? ColorPalette.fallbackSuccess : ColorPalette.fallbackDanger)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(checkpoint.subpoint)
                                                    .font(Theme.typography.bodyMedium)
                                                    .foregroundStyle(Color.primary)

                                                if let evidence = checkpoint.evidence, !evidence.isEmpty {
                                                    Text("→ \"\(evidence)\"")
                                                        .font(Theme.typography.bodySmall)
                                                        .foregroundStyle(Color.secondary)
                                                        .italic()
                                                }
                                            }

                                            Spacer()
                                        }

                                        if index < evaluation.checkpoints.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: - Positive Aspects
                        if let positiveAspects = evaluation.positiveAspects, !positiveAspects.isEmpty {
                            DSCard {
                                VStack(alignment: .leading, spacing: Theme.spacing.md) {
                                    Label("Was gut war", systemImage: "hand.thumbsup.fill")
                                        .font(Theme.typography.titleMedium)
                                        .foregroundStyle(ColorPalette.fallbackSuccess)

                                    Divider()

                                    ForEach(Array(positiveAspects.enumerated()), id: \.offset) { index, aspect in
                                        HStack(alignment: .top, spacing: Theme.spacing.sm) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(ColorPalette.fallbackSuccess)

                                            Text(aspect)
                                                .font(Theme.typography.bodyMedium)
                                                .foregroundStyle(Color.primary)
                                                .fixedSize(horizontal: false, vertical: true)

                                            Spacer(minLength: 0)
                                        }

                                        if index < positiveAspects.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: - Negative Aspects
                        if let negativeAspects = evaluation.negativeAspects, !negativeAspects.isEmpty {
                            DSCard {
                                VStack(alignment: .leading, spacing: Theme.spacing.md) {
                                    Label("Was verbessert werden muss", systemImage: "exclamationmark.triangle.fill")
                                        .font(Theme.typography.titleMedium)
                                        .foregroundStyle(ColorPalette.fallbackWarning)

                                    Divider()

                                    ForEach(Array(negativeAspects.enumerated()), id: \.offset) { index, aspect in
                                        HStack(alignment: .top, spacing: Theme.spacing.sm) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(ColorPalette.fallbackWarning)

                                            Text(aspect)
                                                .font(Theme.typography.bodyMedium)
                                                .foregroundStyle(Color.primary)
                                                .fixedSize(horizontal: false, vertical: true)

                                            Spacer(minLength: 0)
                                        }

                                        if index < negativeAspects.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: - Improved Version
                        if let improvedVersion = evaluation.improvedVersion, !improvedVersion.isEmpty {
                            ImprovedVersionCard(
                                originalText: attempt.text,
                                improvedText: improvedVersion
                            )
                        }

                        // MARK: - Errors
                        if !evaluation.errors.isEmpty {
                            DSCard {
                                VStack(alignment: .leading, spacing: Theme.spacing.md) {
                                    Label("Fehler (\(evaluation.errors.count))", systemImage: "exclamationmark.bubble.fill")
                                        .font(Theme.typography.titleMedium)
                                        .foregroundStyle(ColorPalette.fallbackDanger)

                                    Divider()

                                    ForEach(Array(evaluation.errors.enumerated()), id: \.offset) { index, error in
                                        ErrorRowDS(error: error)

                                        if index < evaluation.errors.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: - Improvements
                        if !evaluation.improvements.isEmpty {
                            DSCard {
                                VStack(alignment: .leading, spacing: Theme.spacing.md) {
                                    Label("Verbesserungsvorschläge", systemImage: "lightbulb.fill")
                                        .font(Theme.typography.titleMedium)
                                        .foregroundStyle(ColorPalette.fallbackWarning)

                                    Divider()

                                    ForEach(Array(evaluation.improvements.enumerated()), id: \.offset) { index, improvement in
                                        HStack(alignment: .top, spacing: Theme.spacing.sm) {
                                            Image(systemName: "arrow.up.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(ColorPalette.fallbackWarning)

                                            Text(improvement)
                                                .font(Theme.typography.bodyMedium)
                                                .foregroundStyle(Color.primary)
                                                .fixedSize(horizontal: false, vertical: true)

                                            Spacer(minLength: 0)
                                        }

                                        if index < evaluation.improvements.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: - Model Suggestions (if available)
                        if let suggestions = evaluation.modelSuggestions, !suggestions.isEmpty {
                            DSCard {
                                VStack(alignment: .leading, spacing: Theme.spacing.md) {
                                    Label("Beispielsätze", systemImage: "sparkles")
                                        .font(Theme.typography.titleMedium)
                                        .foregroundStyle(ColorPalette.fallbackPrimary)

                                    Divider()

                                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                                        Text("→ \"\(suggestion)\"")
                                            .font(Theme.typography.bodyMedium)
                                            .foregroundStyle(Color.secondary)
                                            .italic()
                                            .fixedSize(horizontal: false, vertical: true)

                                        if index < suggestions.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - Your Original Text
                    DSCard {
                        VStack(alignment: .leading, spacing: Theme.spacing.md) {
                            Label("Ihr Text", systemImage: "doc.text")
                                .font(Theme.typography.titleMedium)
                                .foregroundStyle(Color.primary)

                            Divider()

                            Text(attempt.text)
                                .font(Theme.typography.bodyMedium)
                                .foregroundStyle(Color.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // MARK: - Bottom Actions
                    VStack(spacing: Theme.spacing.sm) {
                        DSPrimaryButton(title: "Neue Übung starten") {
                            dismiss()
                            // Dismiss the editor view as well to go back to task picker
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismissAll?()
                            }
                        }

                        DSSecondaryButton(title: "Ergebnis exportieren", icon: "square.and.arrow.up") {
                            exportJSON()
                        }
                    }
                    .padding(.bottom, Theme.spacing.xl)
                }
                .padding(.horizontal, Theme.spacing.lg)
            }
            .background(Theme.colors.background)
            .navigationTitle("Ergebnis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        storage.toggleFavorite(attempt)
                        toastMessage = attempt.isFavorite ? "Favorit entfernt" : "Als Favorit markiert"
                        showToast = true
                    } label: {
                        Image(systemName: attempt.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(attempt.isFavorite ? ColorPalette.fallbackWarning : .secondary)
                    }
                }
            }
            .toast(
                isShowing: $showToast,
                message: toastMessage,
                type: .success
            )
            .sheet(isPresented: $showingExportSheet, onDismiss: {
                exportURL = nil
            }) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func exportJSON() {
        do {
            let url = try ExportService.exportAttemptToFile(attempt)
            exportURL = url
            showingExportSheet = true
            toastMessage = "Erfolgreich exportiert"
            showToast = true
        } catch {
            toastMessage = "Export fehlgeschlagen"
            showToast = true
        }
    }
}

// MARK: - Error Row with Design System

struct ErrorRowDS: View {
    let error: WritingError

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                DSChip(
                    text: error.type.rawValue,
                    style: .warning
                )

                Spacer()
            }

            if !error.sample.isEmpty {
                Text("❌ \(error.sample)")
                    .font(Theme.typography.bodyMedium)
                    .foregroundStyle(Color.primary)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorPalette.fallbackDanger.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radii.sm))
            }

            Text("✅ \(error.hint)")
                .font(Theme.typography.bodySmall)
                .foregroundStyle(Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Improved Version Card

struct ImprovedVersionCard: View {
    let originalText: String
    let improvedText: String

    @State private var showingComparison = false

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: Theme.spacing.md) {
                HStack {
                    Label("Verbesserte Version", systemImage: "wand.and.stars")
                        .font(Theme.typography.titleMedium)
                        .foregroundStyle(ColorPalette.fallbackPrimary)

                    Spacer()

                    Button {
                        withAnimation(Theme.motion.springy) {
                            showingComparison.toggle()
                        }
                        Theme.haptics.selection()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showingComparison ? "arrow.left.arrow.right" : "eye")
                            Text(showingComparison ? "Vergleich" : "Nur verbessert")
                        }
                        .font(Theme.typography.labelMedium)
                        .foregroundStyle(ColorPalette.fallbackPrimary)
                    }
                }

                Divider()

                if showingComparison {
                    // Side-by-side comparison
                    VStack(spacing: Theme.spacing.md) {
                        // Original
                        VStack(alignment: .leading, spacing: Theme.spacing.xs) {
                            Text("Original")
                                .font(Theme.typography.labelSmall)
                                .foregroundStyle(Color.secondary)

                            Text(originalText)
                                .font(Theme.typography.bodySmall)
                                .foregroundStyle(Color.primary)
                                .padding(Theme.spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radii.md))
                        }

                        // Improved
                        VStack(alignment: .leading, spacing: Theme.spacing.xs) {
                            Text("Verbessert")
                                .font(Theme.typography.labelSmall)
                                .foregroundStyle(Color.secondary)

                            Text(improvedText)
                                .font(Theme.typography.bodySmall)
                                .foregroundStyle(Color.primary)
                                .padding(Theme.spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ColorPalette.fallbackSuccess.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radii.md))
                        }
                    }
                } else {
                    // Just improved version
                    Text(improvedText)
                        .font(Theme.typography.bodyMedium)
                        .foregroundStyle(Color.primary)
                        .padding(Theme.spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ColorPalette.fallbackSuccess.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radii.md))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("Writing Result") {
    NavigationStack {
        WritingResultView(
            attempt: WritingAttempt.mockResult(),
            storage: WritingStorageService()
        )
    }
}

// MARK: - Mock Data Extension

extension WritingAttempt {
    static func mockResult() -> WritingAttempt {
        let task = WritingTask(
            id: UUID(),
            type: .email,
            topic: "Einladung ablehnen",
            situation: "Sie haben eine E-Mail von Ihrem Freund Max bekommen. Er lädt Sie zu seiner Party ein, aber Sie können nicht kommen.",
            subpoints: [
                "Warum können Sie nicht kommen?",
                "Was schlagen Sie vor?",
                "Wann haben Sie Zeit?",
                "Was möchten Sie zusammen machen?"
            ],
            hints: nil,
            timeLimitMinutes: 25
        )

        let metrics = WritingMetrics(
            attemptID: UUID(),
            wordCount: 125,
            sentenceCount: 8,
            avgSentenceLength: 15.6,
            typeTokenRatio: 0.72,
            writingPace: [],
            subpointCoverage: [],
            phrasesUsed: ["außerdem", "deshalb"],
            estimatedLevel: "B1"
        )

        let evaluation = WritingEvaluation(
            scores: WritingEvaluation.RubricScores(
                aufgabenerfuellung: 4.5,
                kohaerenz: 4.0,
                wortschatz: 3.5,
                strukturen: 3.8
            ),
            errors: [
                WritingError(
                    type: .morphologie,
                    sample: "Ich habe gestern gegangen",
                    hint: "Korrekt: 'Ich bin gestern gegangen' (Bewegungsverb mit 'sein')"
                )
            ],
            checkpoints: [
                WritingEvaluation.CheckpointResult(subpoint: "Warum können Sie nicht kommen?", covered: true, evidence: "Ich habe einen Arzttermin"),
                WritingEvaluation.CheckpointResult(subpoint: "Was schlagen Sie vor?", covered: true, evidence: nil),
                WritingEvaluation.CheckpointResult(subpoint: "Wann haben Sie Zeit?", covered: true, evidence: nil),
                WritingEvaluation.CheckpointResult(subpoint: "Was möchten Sie zusammen machen?", covered: false, evidence: nil)
            ],
            summary: "Gute Struktur und klare Kommunikation. Alle Hauptpunkte wurden behandelt.",
            improvements: [
                "Verwenden Sie mehr Konnektoren für besseren Textfluss",
                "Achten Sie auf Perfektbildung mit 'sein' bei Bewegungsverben"
            ],
            modelSuggestions: ["Ich schlage vor, dass wir uns nächste Woche treffen."],
            improvedVersion: "Lieber Max,\n\nvielen Dank für deine Einladung! Leider kann ich am Samstag nicht kommen, weil ich einen wichtigen Arzttermin habe.\n\nIch schlage vor, dass wir uns nächste Woche treffen. Ich habe am Mittwochnachmittag Zeit.\n\nWas hältst du davon, wenn wir zusammen ins Kino gehen?\n\nLiebe Grüße\nAnna",
            positiveAspects: [
                "Klare und verständliche Sprache",
                "Gute Verwendung von Konnektoren",
                "Angemessene Länge für B1-Niveau"
            ],
            negativeAspects: [
                "Ein Punkt wurde nicht beantwortet",
                "Grammatikfehler bei Perfektbildung",
                "Wortschatz könnte vielfältiger sein"
            ]
        )

        return WritingAttempt(
            task: task,
            text: "Lieber Max,\n\nvielen Dank für deine Einladung! Leider kann ich am Samstag nicht kommen, weil ich habe gestern gegangen zum Arzt.\n\nIch schlage vor, wir können uns nächste Woche treffen. Ich habe Zeit am Mittwoch nachmittag.\n\nLiebe Grüße\nAnna",
            duration: 780,
            metrics: metrics,
            evaluation: evaluation
        )
    }
}
