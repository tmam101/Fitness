//
//  WeightLineChart.swift
//  Fitness
//
//  Created by Thomas Goss on 11/16/22.
//

import SwiftUI
import Charts
import Combine

public class LineChartViewModel: ObservableObject {
    @Published var days: [Day] = []
    @Published var maxValue: Double = 0
    @Published var minValue: Double = 0
    private var cancellables: [AnyCancellable] = []
    private var weights: [Double] = []
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
            days[-1] = Day(date: Date.subtract(days: -1, from: today.date), daysAgo: -1, expectedWeight: today.expectedWeightTomorrow)
        }
        let values = days.filter { $0.key <= timeFrame.days }
            .values
            .sorted(by: { $0.daysAgo < $1.daysAgo })
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

extension ChartContent {
//    @ChartContentBuilder
//    func conditional(bool: Bool, _ fun: ((some ChartContent) -> some ChartContent)) -> any ChartContent {
//        if bool {
//            fun(self)
//        } else {
//            self
//        }
//    }
    
    @ChartContentBuilder
    func overlayPointWith(text: String) -> some ChartContent {
        self.annotation(position: .overlay, alignment: .bottom, spacing: 5) {
            Text(text)
                .foregroundStyle(.yellow)
                .fontWeight(.light)
                .font(.system(size: 10))
        }
    }
}

struct WeightLineChart: View {
    @ObservedObject private var viewModel: LineChartViewModel
    
    init(health: HealthData, timeFrame: TimeFrame) {
        self.viewModel = LineChartViewModel(health: health, timeFrame: timeFrame)
    }
    
//    struct M: ViewModifier {
//        let day: Day
//        func body(content: Content) -> some View {
//            content
////                .annotation(position: .overlay, alignment: .bottom, spacing: 5) {
////                Text("\(day.dayOfWeek.prefix(1))")
////                    .foregroundStyle(.yellow)
////                    .fontWeight(.light)
////                    .font(.system(size: 10))
//            }
//        }
    
//    @ChartContentBuilder
//    func modifier(day: Day, content: some ChartContent) -> some ChartContent {
//        content.annotation(position: .overlay, alignment: .bottom, spacing: 5) {
//            Text("\(day.dayOfWeek.prefix(1))")
//                .foregroundStyle(.yellow)
//                .fontWeight(.light)
//                .font(.system(size: 10))
//        }
//    }
    
//    @ChartContentBuilder
//    func test(day: Day, conditional: Bool) -> some ChartContent {
//        if conditional {
//            modifier(day: day, content: expectedWeightPlot(day: day))
//        } else {
//            expectedWeightPlot(day: day)
//        }
//    }
    
    @ChartContentBuilder
    func expectedWeightPlot(day: Day) -> some ChartContent {
        // Expected Weight graph until tomorrow
        if day.daysAgo >= 0 {
            LineMark(x: .value("Days ago", day.date),
                     y: .value("Expected Weight", day.expectedWeight),
                     series: .value("Expected weight", "A"))
            .foregroundStyle(by: .value("Expected Weight 2", "Expected Weight"))
            .accessibilityLabel("expected weight line \(day.daysAgo) days ago")
            .accessibilityValue("\(Int(day.expectedWeight))")
            
            if viewModel.timeFrame.type == .week {
                PointMark(
                    x: .value("Days ago", day.date),
                    y: .value("Expected Weight", day.expectedWeight))
                .foregroundStyle(day.wasModifiedBecauseTheUserDidntEnterData ? .red : .yellow)
                .symbolSize(10)
                .overlayPointWith(text: day.firstLetterOfDay)
                .accessibilityLabel("expected weight point \(day.daysAgo) days ago")
                .accessibilityValue("\(Int(day.expectedWeight))")
            } else if viewModel.timeFrame.type == .month {
                PointMark(
                    x: .value("Days ago", day.date),
                    y: .value("Expected Weight", day.expectedWeight))
                .foregroundStyle(day.wasModifiedBecauseTheUserDidntEnterData ? .red : .yellow)
                .symbolSize(10)
                .accessibilityLabel("expected weight point \(day.daysAgo) days ago")
                .accessibilityValue("\(Int(day.expectedWeight))")
            }
        }
    }
    
    @ChartContentBuilder
    func expectedWeightTomorrowPlot(day: Day) -> some ChartContent {
        // Expected weight tomorrow
        if day.daysAgo <= 0 {
            LineMark(x: .value("Days ago", day.date),
                     y: .value("Expected Weight", day.expectedWeight),
                     series: .value("Tomorrow's expected weight", "B"))
//            .foregroundStyle(by: .value("Expected Weight Tomorrow", "Expected Weight Tomorrow"))
            .foregroundStyle(Color.expectedWeightTomorrowYellow)
            PointMark(
                x: .value("Days ago", day.date),
                y: .value("Expected Weight", day.expectedWeight))
            .foregroundStyle(.yellow)
            .symbolSize(10)
            .opacity(0.3)
        }
    }
    
    @ChartContentBuilder
    func weightPlot(day: Day) -> some ChartContent {
        // Weight
        if day.weight != 0 {
            LineMark(x: .value("Days ago", day.date),
                     y: .value("Real Weight", day.weight),
                     series: .value("Weight", "C"))
            .foregroundStyle(by: .value("Weight", "Weight"))
            
            PointMark(
                x: .value("Days ago", day.date),
                y: .value("Real Weight", day.weight))
            .foregroundStyle(.green)
            .symbolSize(10)
        }
    }
    @ChartContentBuilder
    func realisticWeightPlot(day: Day) -> some ChartContent {
        // Realistic weights
        if day.weight != 0 {
            LineMark(x: .value("Days ago", day.date),
                     y: .value("Real Weight", day.realisticWeight),
                     series: .value("Weight", "D"))
            .foregroundStyle(by: .value("Realistic Weight", "Realistic Weight"))
            
            PointMark(
                x: .value("Days ago", day.date),
                y: .value("Real Weight", day.realisticWeight))
            .foregroundStyle(.green)
            .symbolSize(10)
            .opacity(0.2)
        }
    }
    
    var chart: some View {
        Chart(viewModel.days) { day in
            // Expected Weight graph until tomorrow
            expectedWeightPlot(day: day)
            //                test(day: day)
            
            // Expected weight tomorrow
            expectedWeightTomorrowPlot(day: day)
            
            // Weight
            weightPlot(day: day)
            
            // Realistic weights
            realisticWeightPlot(day: day)
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
//                "Expected Weight Tomorrow": Color.expectedWeightTomorrowYellow
            ])
        }
        .padding()
    }
}

//struct WeightLineChart_Previews: PreviewProvider {
//    static var previews: some View {
////        WeightLineChart(health: HealthData(environment: .debug(nil)), timeFrame: .init(longName: "This Week", name: "Week", days: 7))
////            .mainBackground()
////        FitnessPreviewProvider.MainPreview()
//    }
//}
