//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

#if !os(watchOS)
struct TimeFramePicker: View {
    @Binding var selectedPeriod: Int
    var body: some View {
        Picker(selection: $selectedPeriod, label: Text("Select Period")) {
            ForEach(0..<TimeFrame.timeFrames.count) {
                                    Text(TimeFrame.timeFrames[$0].shortName)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .accessibilityIdentifier("Picker2")
    }
}
#endif

public struct FitnessView: View {
    @EnvironmentObject var healthData: HealthData
    @Environment(\.scenePhase) private var scenePhase
    
    // Variables
    @State private var isDisplayingOverlay = false
    @State private var deficitLineGraphDaysToShow: Double = 30.0
    @State private var runsToShow: Double = 5.0
    @State private var showLifts = false
    @State private var showWeightRings = false
    @State private var showWeeklyDeficitLine = false
    
    @State private var selectedPeriod = 2
    @Binding var timeFrame: Int
    @State var bottomPadding: CGFloat = 0
        
    // MARK: - Body
    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading) {
                    //#if !os(watchOS)
                    //                TimeFramePicker(selectedPeriod: $selectedPeriod)
                    //#endif
                    let timeFrame = TimeFrame.timeFrames[timeFrame]
                    
                    Text("Net Energy \(timeFrame.longName)")
                        .foregroundStyle(.white)
                        .font(.title)
                    // MARK: Deficit Rings
                    if
                        let thisWeekDeficit = healthData.days.averageDeficitOfPrevious(days: timeFrame.days, endingOnDay: 1),
                        let weeklyDeficitTomorrow = healthData.days.averageDeficitOfPrevious(days: timeFrame.days, endingOnDay: 0),
                        !thisWeekDeficit.isNaN {
                        let thisWeekNetEnergy = 0 - thisWeekDeficit
                        let sign = thisWeekNetEnergy > 0 ? "+" : ""
                        let bodyText = "\(sign)\(Int(Double(thisWeekNetEnergy)))"
                        let color: TodayRingColor = thisWeekNetEnergy > 0 ? .red : .yellow
                        let netEnergyItem = TodayRingViewModel(
                            titleText: "Average\n\(timeFrame.longName)",
                            bodyText: bodyText,
                            subBodyText: "cals",
                            percentage: thisWeekDeficit / (Settings.get(key: .netEnergyGoal) as? Decimal ?? 1000),
                            color: .yellow,
                            bodyTextColor: color,
                            subBodyTextColor: color
                        )
                        
                        let weeklyNetEnergyTomorrow = 0 - weeklyDeficitTomorrow
                        let sign2 = weeklyNetEnergyTomorrow > 0 ? "+" : ""
                        let bodyText2 = "\(sign2)\(Int(Double(weeklyNetEnergyTomorrow)))"
                        let color2: TodayRingColor = weeklyNetEnergyTomorrow > 0 ? .red : .yellow
                        let tomorrowEnergyItem = TodayRingViewModel(
                            titleText: "Tomorrow's Projected Average",
                            bodyText: bodyText2,
                            subBodyText: "cals",
                            percentage: weeklyDeficitTomorrow / (Settings.get(key: .netEnergyGoal) as? Decimal ?? 1000),
                            color: .yellow,
                            bodyTextColor: color2,
                            subBodyTextColor: color2
                        )
                        
                        HStack {
                            TodayRingView(vm: netEnergyItem)
                                .mainBackground()
                            TodayRingView(vm: tomorrowEnergyItem)
                                .mainBackground()
                        }
                        .frame(maxHeight: 300)
                        
                        
                    }
                    
                    //                renderDeficitRingsSection()
                    
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
//                .padding(.bottom, bottomPadding)
                .padding(.bottom, 49)
            }
            .onPreferenceChange(InnerContentSize.self, perform: { value in
                self.bottomPadding = proxy.size.height - (value.last?.height ?? 0)
            })
            .onChange(of: scenePhase) {
                handleSceneChange()
            }.preference(key: InnerContentSize.self, value: [proxy.frame(in: CoordinateSpace.global)])

        }
    }
    
    // MARK: - View Rendering Functions
    
    @ViewBuilder
    private func renderDeficitBarChartSection() -> some View {
        Group {
            Text("Net Energy By Day")
                .foregroundColor(.white)
                .font(.title2)
            NetEnergyBarChart(health: healthData, timeFrame: TimeFrame.timeFrames[timeFrame])
                .frame(maxWidth: .infinity, minHeight: 300)
                .mainBackground()
        }
    }
    
//    @ViewBuilder
//    private func renderDeficitLineGraphSection() -> some View {
//        Group {
//            Text("Expected Weight This Week")
//                .foregroundColor(.white)
//                .font(.title2)
//            DeficitLineGraph()
//                .frame(maxWidth: .infinity, minHeight: 200)
//                .mainBackground()
//        }
//    }
    
    @ViewBuilder
    private func renderWeightRingsAndLineChartSection() -> some View {
        Group {
//            if showWeightRings {
//                StatsTitle(title: "Weight Loss")
//                StatsRow(text: { WeightLossText() }, rings: { WeightLossRings() })
//                    .frame(maxWidth: .infinity)
//            }
            Text("Expected Weight")
                .foregroundColor(.white)
                .font(.title2)
            WeightLineChart(health: healthData, timeFrame: TimeFrame.timeFrames[timeFrame])
                .frame(maxWidth: .infinity, minHeight: 200)
                .mainBackground()
        }
    }
    
//    @ViewBuilder
//    private func renderMileTimeSection() -> some View {
//        Group {
//            StatsTitle(title: "Mile Time")
//            MileTimeStats(runsToShow: $runsToShow)
//                .frame(maxWidth: .infinity)
//                .mainBackground()
//            RunningLineGraph(runsToShow: $runsToShow)
//                .frame(maxWidth: .infinity, idealHeight: 400)
//                .padding()
//                .mainBackground()
//            if healthData.runManager.runs.count > 1 {
//                Slider(value: $runsToShow, in: 1...Double(healthData.runManager.runs.count), step: 1)
//                    .tint(.blue)
//                Text("past \(Int(runsToShow)) runs")
//                    .foregroundColor(.blue)
//            }
//        }
//    }
    
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
//        FitnessPreviewProvider.MainPreview(options: [.dayCount(10)])
    }
}

public struct FitnessPreviewProvider {
    static func MainPreview(options: [TestDayOption]) -> some View {
        @State var timeFrame = 2
        return FitnessView(timeFrame: $timeFrame)
            .environmentObject(HealthData(environment: .debug(options)))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
            .background(Color.black)
    }
    
    static func MainPreview() -> some View {
        @State var timeFrame = 2
        return FitnessView(timeFrame: $timeFrame)
            .environmentObject(HealthData(environment: .debug([.isMissingConsumedCalories(.v3), .testCase(.realisticWeightsIssue)])))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
            .background(Color.black)
    }
}
