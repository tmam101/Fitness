//
//  HomeScreen.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

#if !os(watchOS)
public struct TimeFramePicker: View {
    @Binding var selectedPeriod: Int
    public var body: some View {
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

//class HomeScreenViewModel {
//    
//}

public struct HomeScreen: View {
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
                    let timeFrame = TimeFrame.timeFrames[timeFrame]
                    
                    Text("Net Energy \(timeFrame.longName)")
                        .foregroundStyle(.white)
                        .font(.title)
                    // MARK: Deficit Rings
                    
                    if let netEnergyModels = HomeScreen.netEnergyRingModels(days: healthData.days, timeFrame: timeFrame) {
                        renderNetEnergyRings(netEnergyModels: netEnergyModels)
                    }
                                        
                    // MARK: Deficit Bar Chart
                    renderDeficitBarChartSection()
                    
                    renderWeightRingsAndLineChartSection()
                    
                    // MARK: Mile Time
                    //                renderMileTimeSection()
                }
                .padding()
//                .padding(.bottom, bottomPadding)
            }
            .onChange(of: scenePhase) {
                handleSceneChange()
            }

        }
    }
    
    // MARK: - View Rendering Functions
    // TODO what if oldest day doesnt have a weight? or newest?
    public static func netEnergyRingModels(days: Days, timeFrame: TimeFrame) -> [TodayRingViewModel]? {
        let daysInTimeFrame = days.filteredBy(timeFrame)
        if let thisWeekDeficit = daysInTimeFrame.averageDeficitOfPrevious(days: timeFrame.days, endingOnDay: 1),
           let weeklyDeficitTomorrow = daysInTimeFrame.averageDeficitOfPrevious(days: timeFrame.days, endingOnDay: 0),
           !thisWeekDeficit.isNaN {
            let thisWeekNetEnergy = 0 - thisWeekDeficit
            let bodyText = thisWeekNetEnergy.stringWithPlusIfNecessary
            let color: TodayRingColor = thisWeekNetEnergy > 0 ? .red : .yellow
            let netEnergyItem = TodayRingViewModel(
                titleText: "Average\n\(timeFrame.longName)",
                bodyText: bodyText,
                subBodyText: "cals",
                percentage: thisWeekDeficit / (Settings.get(key: .netEnergyGoal) as? Decimal ?? 1000),
                color: color,
                bodyTextColor: color,
                subBodyTextColor: color
            )
            
            let weeklyNetEnergyTomorrow = 0 - weeklyDeficitTomorrow
            let bodyText2 = weeklyNetEnergyTomorrow.stringWithPlusIfNecessary
            let color2: TodayRingColor = weeklyNetEnergyTomorrow > 0 ? .red : .yellow
            let tomorrowEnergyItem = TodayRingViewModel(
                titleText: "Tomorrow's Projected Average",
                bodyText: bodyText2,
                subBodyText: "cals",
                percentage: weeklyDeficitTomorrow / (Settings.get(key: .netEnergyGoal) as? Decimal ?? 1000),
                color: color2,
                bodyTextColor: color2,
                subBodyTextColor: color2
            )
            return [netEnergyItem, tomorrowEnergyItem]
        }
        return nil
    }
    
    func renderNetEnergyRings(netEnergyModels: [TodayRingViewModel]) -> some View {
        HStack {
            ForEach(netEnergyModels) { model in
                TodayRingView(vm: model)
                    .mainBackground()
            }
        }
        .frame(maxHeight: 300)
    }
    
    @ViewBuilder
    func renderDeficitBarChartSection() -> some View {
        Group {
            Text("Net Energy By Day")
                .foregroundColor(.white)
                .font(.title2)
            NetEnergyBarChart(health: healthData, timeFrame: TimeFrame.timeFrames[timeFrame])
                .frame(maxWidth: .infinity, minHeight: 300)
                .mainBackground()
        }
    }
    
   public static func weightRingModels(days: Days, timeFrame: TimeFrame) -> [TodayRingViewModel]? {
        let daysInTimeFrame = days.filteredBy(timeFrame)
        if let oldestDay = daysInTimeFrame.oldestDay,
           let newestDay = daysInTimeFrame.newestDay {
            let weightChange = newestDay.weight - oldestDay.weight
            let expectedWeightChange = newestDay.expectedWeight - oldestDay.expectedWeight
            return [
                (expectedWeightChange, Day.Property.expectedWeight),
                (weightChange, Day.Property.weight)
            ].map { change, property -> TodayRingViewModel in
                let bodyText = change.roundedString(withSign: true)
                var color = TodayRingColor.fromProperty(property) ?? .white
                color = change < 0 ? color : .white
                var percentage = change / -2.0
                percentage = percentage < 0 ? 0 : percentage
                return TodayRingViewModel(
                    titleText: "\(property.rawValue.capitalized) change",
                    bodyText: bodyText,
                    subBodyText: "lbs",
                    percentage: percentage,
                    color: color,
                    bodyTextColor: color,
                    subBodyTextColor: color
                )
            }
        }
        return nil
    }
    
    @ViewBuilder
    func renderWeightRingsAndLineChartSection() -> some View {
        Group {
            Text("Expected Weight")
                .foregroundColor(.white)
                .font(.title2)
            
            let timeFrame = TimeFrame.timeFrames[timeFrame]

            if let weightModels = HomeScreen.weightRingModels(days: healthData.days, timeFrame: timeFrame) {
                renderNetEnergyRings(netEnergyModels: weightModels)
            }
            
            WeightLineChart(health: healthData, timeFrame: TimeFrame.timeFrames[self.timeFrame])
                .frame(maxWidth: .infinity, minHeight: 200)
                .mainBackground()
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


#Preview("Home screen") {
    FitnessPreviewProvider.MainPreview()
}

public struct FitnessPreviewProvider {
    static func MainPreview(options: Config) -> some View {
        @State var timeFrame = 2
        return HomeScreen(timeFrame: $timeFrame)
            .environmentObject(HealthData(environment: .debug(options)))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
            .background(Color.black)
    }
    
    static func MainPreview() -> some View {
        @State var timeFrame = 2
        return HomeScreen(timeFrame: $timeFrame)
            .environmentObject(HealthData(environment: .debug(.init([.isMissingConsumedCalories(.v3), .testCase(.realisticWeightsIssue)]))))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
            .background(Color.black)
    }
}
