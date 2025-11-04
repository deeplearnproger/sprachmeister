//
//  ScenarioPicker.swift
//  SprachMeister
//
//  Scenario selection view
//  Created on 20.10.2025
//

import SwiftUI

struct ScenarioPicker: View {

    @State private var selectedScenario: Scenario?
    @State private var showingPractice = false

    let scenarios = Scenario.defaultScenarios

    var body: some View {
        NavigationStack {
            List {
                ForEach(ScenarioType.allCases) { scenarioType in
                    Section(header: sectionHeader(for: scenarioType)) {
                        ForEach(scenariosFor(type: scenarioType)) { scenario in
                            ScenarioRow(scenario: scenario)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedScenario = scenario
                                    showingPractice = true
                                }
                        }
                    }
                }
            }
            .navigationTitle("Goethe B1 Trainer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AttemptsHistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .navigationDestination(isPresented: $showingPractice) {
                if let scenario = selectedScenario {
                    PracticeScreen(scenario: scenario)
                }
            }
        }
    }

    private func sectionHeader(for type: ScenarioType) -> some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundColor(.blue)
            Text(type.rawValue)
                .font(.headline)
        }
    }

    private func scenariosFor(type: ScenarioType) -> [Scenario] {
        scenarios.filter { $0.type == type }
    }
}

// MARK: - Scenario Row

struct ScenarioRow: View {
    let scenario: Scenario

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scenario.topic)
                .font(.headline)

            Text(scenario.type.description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Label(
                    "\(Int(scenario.expectedDuration / 60)) Min",
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundColor(.secondary)

                Spacer()

                Label(
                    "\(scenario.prompts.count) Fragen",
                    systemImage: "bubble.left.and.bubble.right"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ScenarioPicker()
}
