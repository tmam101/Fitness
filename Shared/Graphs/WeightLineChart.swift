//
//  WeightLineChart.swift
//  Fitness
//
//  Created by Thomas Goss on 11/16/22.
//

import SwiftUI
import Charts
import Combine

public enum PlotStyleType: CaseIterable {
    case weight
    case expectedWeight
    case realisticWeight
    case expectedWeightTomorrow
    
    var foregroundStyle: String {
        switch self {
        case .weight:
            "Weight"
        case .expectedWeight:
            "Expected Weight"
        case .realisticWeight:
            "Realistic Weight"
        case .expectedWeightTomorrow:
            "Expected Weight Tomorrow" // TODO
        }
    }
    
    var xValueLabel: String {
        switch self {
        case .weight, .expectedWeight, .realisticWeight, .expectedWeightTomorrow:
            "Days ago"
        }
    }
    
    var yValueLabel: String {
        switch self {
        case .weight:
            "Real Weight"
        case .expectedWeight:
            "Expected Weight"
        case .realisticWeight:
            "Realistic Weight"
        case .expectedWeightTomorrow:
            "Expected Weight Tomorrow"
        }
    }
    
    var series: String {
        switch self {
        case .weight:
            "C"
        case .expectedWeight:
            "A"
        case .realisticWeight:
            "D"
        case .expectedWeightTomorrow:
            "B"
        }
    }
    
    var color: Color {
        switch self {
        case .weight:
            Color.weightGreen
        case .expectedWeight:
            Color.expectedWeightYellow
        case .expectedWeightTomorrow:
            Color.expectedWeightTomorrowYellow
        case .realisticWeight:
            Color.realisticWeightGreen
        }
    }
}

public class PlotViewModel {
    var type: PlotStyleType
    var day: Day
    var timeFrame: TimeFrame
    var xValue: Date { day.date }
    var xValueLabel: String { type.xValueLabel }
    var dateOverlay: String { day.firstLetterOfDay }
    var yValue: Double {
        switch type {
        case .weight:
            day.weight
        case .expectedWeight:
            day.expectedWeight
        case .realisticWeight:
            day.realisticWeight
        case .expectedWeightTomorrow:
            day.expectedWeight
        }
    }
    var yValueLabel: String { type.yValueLabel }
    var foregroundStyle: String { type.foregroundStyle }
    var series: String { type.series }
    
    init(type: PlotStyleType, day: Day, timeFrame: TimeFrame) {
        self.type = type
        self.day = day
        self.timeFrame = timeFrame
    }
    
    var shouldDisplay: Bool {
        switch type {
        case .weight, .expectedWeight, .realisticWeight:
            day.daysAgo >= 0
        case .expectedWeightTomorrow:
            true
        }
    }
    
    var shouldHavePoint: Bool {
        switch type {
        case .weight, .expectedWeight, .realisticWeight:
            switch timeFrame.type {
            case .allTime:
                return false
            case .week, .month:
                return true
            }
        case .expectedWeightTomorrow:
            return false
        }
    }
    
    var shouldHaveDayOverlay: Bool {
        switch type {
        case .weight, .expectedWeightTomorrow, .realisticWeight:
            false
        case .expectedWeight:
            switch timeFrame.type {
            case .allTime, .month:
                false
            case .week:
                true
            }
        }
    }
    
    var shouldIndicateMissedDays: Bool {
        if !shouldHavePoint {
            return false
        }
        switch type {
        case .weight, .expectedWeightTomorrow, .realisticWeight:
            return false
        case .expectedWeight:
            switch timeFrame.type {
            case .allTime:
                return false
            case .week, .month:
                return true
            }
        }
    }
    
    var pointStyle: some ShapeStyle {
        if shouldIndicateMissedDays && day.wasModifiedBecauseTheUserDidntEnterData {
            return .red
        }
        return type.color
    }
}

public class LineChartViewModel: ObservableObject {
    @Published var days: [Day] = []
    @Published var maxValue: Double = 0
    @Published var minValue: Double = 0
    private var cancellables: [AnyCancellable] = []
    @Published var timeFrame: TimeFrame
    
    init(health: HealthData, timeFrame: TimeFrame) {
        self.timeFrame = timeFrame
        switch health.environment {
        case .debug:
            self.populateDays(for: health.days)
        case .release, .widgetRelease:
            health.$hasLoaded.sink { [weak self] hasLoaded in
                guard let self = self, hasLoaded else { return }
                self.populateDays(for: health.days)
            }.store(in: &cancellables)
        }
    }
    
    init(days: Days, timeFrame: TimeFrame) {
        self.timeFrame = timeFrame
        self.populateDays(for: days)
    }
    
    public func populateDays(for days: Days) {
        self.days = self.constructDays(using: days)
        self.updateMinMaxValues(days: self.days)
    }

    public func constructDays(using days: Days) -> [Day] {
        var days = days
        // Add tomorrow for the graph
        if let today = days[0] {
            let _ = days.append(Day(date: Date.add(days: 1, from: today.date), daysAgo: -1, expectedWeight: today.expectedWeightTomorrow))
        }
        let values = days
            .subset(from: -1, through: timeFrame.days)
            .sortedMostRecentToLongestAgo()
        return values
    }
    
    public func updateMinMaxValues(days: [Day]) {
        let expectedWeights = days.map {
            $0.expectedWeight + $0.expectedWeightChangeBasedOnDeficit
        }.filter { $0 != 0 }
        
        let realWeights = days.map { $0.weight }.filter { $0 != 0 }
        let allValues = [expectedWeights, realWeights]
        maxValue = allValues.compactMap { $0.max() ?? nil }.max() ?? 1 //todo
        minValue = allValues.compactMap { $0.min() ?? nil }.min() ?? 1 //todo
    }
}

struct WeightLineChart: View {
    @ObservedObject private var viewModel: LineChartViewModel
    
    init(health: HealthData, timeFrame: TimeFrame) {
        self.viewModel = LineChartViewModel(health: health, timeFrame: timeFrame)
    }
    
    @ChartContentBuilder
    func lineAndPoint(_ viewModel: PlotViewModel) -> some ChartContent {
        // Add Line
        if viewModel.shouldDisplay {
            LineMark(x: .value(viewModel.xValueLabel, viewModel.xValue),
                     y: .value(viewModel.yValueLabel, viewModel.yValue),
                     series: .value(viewModel.yValueLabel, viewModel.series))
            .foregroundStyle(by: .value(viewModel.foregroundStyle, viewModel.foregroundStyle))
            
            // Add Point
            if viewModel.shouldHavePoint {
                PointMark(
                    x: .value(viewModel.xValueLabel, viewModel.xValue),
                    y: .value(viewModel.yValueLabel, viewModel.yValue))
                .foregroundStyle(viewModel.pointStyle)
                .symbolSize(10)
                .conditional(viewModel.shouldHaveDayOverlay) { view in
                    view.overlayPointWith(text: viewModel.dateOverlay)
                }
            }
        }
    }
    
    var chart: some View {
        Chart(viewModel.days) { day in
            lineAndPoint(PlotViewModel(type: .expectedWeight, day: day, timeFrame: viewModel.timeFrame))
            lineAndPoint(PlotViewModel(type: .weight, day: day, timeFrame: viewModel.timeFrame))
            lineAndPoint(PlotViewModel(type: .realisticWeight, day: day, timeFrame: viewModel.timeFrame))
            lineAndPoint(PlotViewModel(type: .expectedWeightTomorrow, day: day, timeFrame: viewModel.timeFrame))
        }
    }
    
    let yAxis: AxisMarks<some AxisMark> = AxisMarks(values: .automatic) { _ in
        AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1, 2]))
            .foregroundStyle(Color.white.opacity(0.5))
        AxisValueLabel()
            .foregroundStyle(Color.white)
    }
    
    //TODO: The initial weight doesn't quite match up with the deficit line.
    var body: some View {
        Group {
            chart
            .chartYAxis {
                yAxis
            }
            .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: viewModel.minValue - 1, upper: viewModel.maxValue + 1))) // todo round up max value properly
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: viewModel.days.count)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                        .foregroundStyle(Color.white)
                }
            }
            .chartForegroundStyleScale([
                "Expected Weight": Color.expectedWeightYellow,
                "Weight": Color.weightGreen,
                "Realistic Weight": Color.realisticWeightGreen,
                "Expected Weight Tomorrow": Color.expectedWeightTomorrowYellow
            ])
        }
        .padding()
    }
}
