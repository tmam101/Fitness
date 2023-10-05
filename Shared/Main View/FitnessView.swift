//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

struct FitnessView: View {
    @EnvironmentObject var healthData: HealthData
    @Environment(\.scenePhase) private var scenePhase
    
    // Variables
    @State private var isDisplayingOverlay = false
    @State private var deficitLineGraphDaysToShow: Double = 30.0
    @State private var runsToShow: Double = 5.0
    @State private var showLifts = false
    @State private var showWeightRings = false
    @State private var showWeeklyDeficitLine = false

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // MARK: Deficit Rings
                renderDeficitRingsSection()

                // MARK: Deficit Bar Chart
                renderDeficitBarChartSection()

                // MARK: Deficit Line Graph
//                if showWeeklyDeficitLine {
//                    renderDeficitLineGraphSection()
//                }

                renderWeightRingsAndLineChartSection()

                // MARK: Mile Time
//                renderMileTimeSection()
            }
            .padding()
        }
        .onChange(of: scenePhase) { _ in
            handleSceneChange()
        }
    }
    
    // MARK: - View Rendering Functions
    
    // TODO: Do I need ViewBuilder?
    @ViewBuilder
    private func renderDeficitRingsSection() -> some View {
        Group {
            HStack {
                StatsTitle(title: "Deficits")
                if !healthData.hasLoaded {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20)
                }
            }
            StatsRow(text: { DeficitText() }, rings: { DeficitRings() })
                .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private func renderDeficitBarChartSection() -> some View {
        Group {
            Text("Net Energy This Week")
                .foregroundColor(.white)
                .font(.title2)
            SwiftUIBarChart(health: healthData)
                .frame(maxWidth: .infinity, minHeight: 400)
                .mainBackground()
        }
    }
    
    @ViewBuilder
    private func renderDeficitLineGraphSection() -> some View {
        Group {
            Text("Expected Weight This Week")
                .foregroundColor(.white)
                .font(.title2)
            DeficitLineGraph()
                .frame(maxWidth: .infinity, minHeight: 200)
                .mainBackground()
        }
    }
    
    @ViewBuilder
    private func renderWeightRingsAndLineChartSection() -> some View {
        Group {
            if showWeightRings {
                StatsTitle(title: "Weight Loss")
                StatsRow(text: { WeightLossText() }, rings: { WeightLossRings() })
                    .frame(maxWidth: .infinity)
            }
            SwiftUILineChart(health: healthData)
                .frame(maxWidth: .infinity, minHeight: 200)
                .mainBackground()
        }
    }
    
    @ViewBuilder
    private func renderMileTimeSection() -> some View {
        Group {
            StatsTitle(title: "Mile Time")
            MileTimeStats(runsToShow: $runsToShow)
                .frame(maxWidth: .infinity)
                .mainBackground()
            RunningLineGraph(runsToShow: $runsToShow)
                .frame(maxWidth: .infinity, idealHeight: 400)
                .padding()
                .mainBackground()
            if healthData.runManager.runs.count > 1 {
                Slider(value: $runsToShow, in: 1...Double(healthData.runManager.runs.count), step: 1)
                    .tint(.blue)
                Text("past \(Int(runsToShow)) runs")
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleSceneChange() {
        if scenePhase == .background {
            Task {
                await healthData.setValues(completion: nil)
            }
        }
    }
}



struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessPreviewProvider.MainPreview()
    }
}

public struct FitnessPreviewProvider {
    static func MainPreview() -> some View {
        return FitnessView()
            .environmentObject(HealthData(environment: .debug))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
            .background(Color.black)
    }
}
