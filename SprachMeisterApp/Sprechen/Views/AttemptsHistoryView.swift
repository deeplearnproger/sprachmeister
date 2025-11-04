//
//  AttemptsHistoryView.swift
//  SprachMeister
//
//  Practice attempts history view
//  Created on 20.10.2025
//

import SwiftUI

struct AttemptsHistoryView: View {

    @StateObject private var storageService = StorageService()
    @State private var selectedAttempt: PracticeAttempt?
    @State private var showingTranscript = false
    @State private var filterType: ScenarioType?

    var body: some View {
        List {
            // Statistics Section
            if !storageService.attempts.isEmpty {
                Section("Statistik") {
                    statisticsSection
                }
            }

            // Filter Section
            Section {
                Picker("Filter", selection: $filterType) {
                    Text("Alle").tag(nil as ScenarioType?)
                    ForEach(ScenarioType.allCases) { type in
                        Text(type.rawValue).tag(type as ScenarioType?)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Attempts List
            Section("Versuche") {
                if filteredAttempts.isEmpty {
                    ContentUnavailableView(
                        "Keine Versuche",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Beginnen Sie mit dem Training!")
                    )
                } else {
                    ForEach(filteredAttempts) { attempt in
                        AttemptRow(attempt: attempt)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedAttempt = attempt
                                showingTranscript = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    storageService.deleteAttempt(attempt)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }

                                Button {
                                    storageService.toggleFavorite(attempt)
                                } label: {
                                    Label(
                                        attempt.isFavorite ? "Favorit entfernen" : "Favorit",
                                        systemImage: attempt.isFavorite ? "star.slash" : "star"
                                    )
                                }
                                .tint(.yellow)
                            }
                    }
                }
            }
        }
        .navigationTitle("Verlauf")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !storageService.attempts.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            storageService.clearAllAttempts()
                        } label: {
                            Label("Alle löschen", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingTranscript) {
            if let attempt = selectedAttempt {
                TranscriptScreen(
                    transcript: attempt.transcript,
                    scenario: attempt.scenario
                )
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(spacing: 12) {
            HStack {
                StatCard(
                    title: "Gesamt",
                    value: "\(storageService.attempts.count)",
                    icon: "checkmark.circle"
                )

                StatCard(
                    title: "Zeit",
                    value: formatTotalTime(storageService.totalPracticeTime),
                    icon: "clock"
                )
            }

            if let avgPerformance = storageService.averagePerformance {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                    Text("Durchschnitt: \(avgPerformance.rawValue)")
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Filtered Attempts

    private var filteredAttempts: [PracticeAttempt] {
        if let filterType = filterType {
            return storageService.getAttempts(for: filterType)
        }
        return storageService.attempts
    }

    // MARK: - Helpers

    private func formatTotalTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Attempt Row

struct AttemptRow: View {
    let attempt: PracticeAttempt

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: attempt.scenario.type.icon)
                    .foregroundColor(.blue)

                Text(attempt.scenario.topic)
                    .font(.headline)

                Spacer()

                if attempt.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }

            Text(attempt.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Label(attempt.durationFormatted, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label(
                    "\(attempt.metrics.totalWords) Wörter",
                    systemImage: "text.bubble"
                )
                .font(.caption)
                .foregroundColor(.secondary)

                Spacer()

                Text(attempt.metrics.performanceLevel.rawValue)
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(performanceLevelColor(attempt.metrics.performanceLevel).opacity(0.2))
                    .foregroundColor(performanceLevelColor(attempt.metrics.performanceLevel))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }

    private func performanceLevelColor(_ level: PracticeMetrics.PerformanceLevel) -> Color {
        switch level {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .needsImprovement: return .red
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        AttemptsHistoryView()
    }
}
