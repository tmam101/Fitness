//
//  HomeScreen.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

#if !os(watchOS)
public struct TimeFramePicker: View {
    @Binding var selectedTimeFrame: TimeFrame
    public var body: some View {
        Picker(selection: $selectedTimeFrame, label: Text("Select Period")) {
            ForEach(TimeFrame.timeFrames, id: \.self) { timeFrame in
                Text(timeFrame.shortName)
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
    
    @Binding var timeFrame: TimeFrame
    @State var bottomPadding: CGFloat = 0
        
    // MARK: - Body
    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading) {
                    
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
                percentage: thisWeekDeficit / (Settings.get(.netEnergyGoal) ?? 1000),
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
                percentage: weeklyDeficitTomorrow / (Settings.get(.netEnergyGoal) ?? 1000),
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
            NetEnergyBarChart(days: healthData.days, timeFrame: timeFrame)
                .frame(maxWidth: .infinity, minHeight: 300)
                .mainBackground()
        }
    }
    
   public static func weightRingModels(days: Days, timeFrame: TimeFrame) -> [TodayRingViewModel]? {
        let daysInTimeFrame = days.filteredBy(timeFrame)
        if let oldestDay = daysInTimeFrame.oldestDay,
           let newestDay = daysInTimeFrame.newestDay {
            let dayDifference = oldestDay.daysAgo - newestDay.daysAgo
            let weightChange = newestDay.weight - oldestDay.weight
            let expectedWeightChange = newestDay.expectedWeight - oldestDay.expectedWeight
            return [
                (expectedWeightChange, Day.Property.expectedWeight),
                (weightChange, Day.Property.weight)
            ].map { change, property -> TodayRingViewModel in
                let bodyText = change.roundedString(withSign: true)
                var color = TodayRingColor.fromProperty(property) ?? .white
                color = change < 0 ? color : .white
                let goalDifference = -(Decimal((2.0/7.0)) * Decimal(dayDifference))
                var percentage = change / goalDifference
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
            
            if let weightModels = HomeScreen.weightRingModels(days: healthData.days, timeFrame: timeFrame) {
                renderNetEnergyRings(netEnergyModels: weightModels)
            }
            
            WeightLineChart(days: healthData.days, timeFrame: timeFrame)
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
    static func MainPreview(options: AppEnvironmentConfig) -> some View {
        @State var timeFrame = TimeFrame.week
        return HomeScreen(timeFrame: $timeFrame)
            .environmentObject(HealthData(environment: options))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
            .background(Color.black)
    }
    
    static func MainPreview() -> some View {
        @State var timeFrame = TimeFrame.week
        return HomeScreen(timeFrame: $timeFrame)
            .environmentObject(HealthData(environment: .init([.isMissingConsumedCalories(true), .testCase(.realisticWeightsIssue)])))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
            .background(Color.black)
    }
}
