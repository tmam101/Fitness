//
//  WeightLineChart.swift
//  Fitness
//
//  Created by Thomas Goss on 11/16/22.
//

import SwiftUI
import Charts
import Combine

private class LineChartViewModel: ObservableObject {
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
            self.populateDays(for: health)
        case .release, .widgetRelease:
            health.$hasLoaded.sink { [weak self] hasLoaded in
                guard let self = self, hasLoaded else { return }
                self.populateDays(for: health)
            }.store(in: &cancellables)
        }
    }
    
    private func populateDays(for health: HealthData) {
        self.days = self.constructDays(using: health)
        self.updateMinMaxValues()
    }

    private func constructDays(using health: HealthData) -> [Day] {
        var days = health.days
        // Add tomorrow for the graph
        if let today = days[0] {
            days[-1] = Day(date: Date.subtract(days: -1, from: today.date), daysAgo: -1, expectedWeight: today.expectedWeightTomorrow)
        }
        return days.filter { $0.key <= timeFrame.days }
            .values
            .sorted(by: { $0.daysAgo < $1.daysAgo })
    }
    
    private func updateMinMaxValues() {
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
    func expectedWeightPlot(day: Day) -> some ChartContent {
        // Expected Weight graph until tomorrow
        if day.daysAgo >= 0 {
            LineMark(x: .value("Days ago", day.date),
                     y: .value("Expected Weight", day.expectedWeight),
                     series: .value("Expected weight", "A"))
            .foregroundStyle(.yellow)
            .opacity(0.8)
            if viewModel.timeFrame.days == 7 {
                PointMark(
                    x: .value("Days ago", day.date),
                    y: .value("Expected Weight", day.expectedWeight))
                .foregroundStyle(day.wasModifiedBecauseTheUserDidntEnterData ? .red : .yellow)
                .symbolSize(10)
                .annotation(position: .overlay, alignment: .bottom, spacing: 5) {
                    Text("\(day.dayOfWeek.prefix(1))")
                        .foregroundStyle(.yellow)
                        .fontWeight(.light)
                        .font(.system(size: 10))
                }
            }
                    else {
                        PointMark(
                            x: .value("Days ago", day.date),
                            y: .value("Expected Weight", day.expectedWeight))
                        .foregroundStyle(day.wasModifiedBecauseTheUserDidntEnterData ? .red : .yellow)
                        .symbolSize(10)
                    }
        }
    }
    
    //TODO: The initial weight doesn't quite match up with the deficit line.
    var body: some View {
        Group {
            Chart(viewModel.days) { day in
                // Expected Weight graph until tomorrow
                expectedWeightPlot(day: day)
                
                // Expected weight tomorrow
                if day.daysAgo <= 0 {
                    LineMark(x: .value("Days ago", day.date),
                             y: .value("Expected Weight", day.expectedWeight),
                             series: .value("Tomorrow's expected weight", "B"))
                    .foregroundStyle(.yellow)
                    .opacity(0.3)
                    PointMark(
                        x: .value("Days ago", day.date),
                        y: .value("Expected Weight", day.expectedWeight))
                    .foregroundStyle(.yellow)
                    .symbolSize(10)
                    .opacity(0.3)
                }
                
                // Weight
                if day.weight != 0 {
                    LineMark(x: .value("Days ago", day.date),
                             y: .value("Real Weight", day.weight),
                             series: .value("Weight", "C"))
                    .foregroundStyle(.green)
                    .opacity(0.5)
                    
                    PointMark(
                        x: .value("Days ago", day.date),
                        y: .value("Real Weight", day.weight))
                    .foregroundStyle(.green)
                    .symbolSize(10)
                    .opacity(0.5)
                }
                
                // Realistic weights
                if day.weight != 0 {
                    LineMark(x: .value("Days ago", day.date),
                             y: .value("Real Weight", day.realisticWeight),
                             series: .value("Weight", "D"))
                    .foregroundStyle(.green)
                    .opacity(0.2)
                    
                    PointMark(
                        x: .value("Days ago", day.date),
                        y: .value("Real Weight", day.realisticWeight))
                    .foregroundStyle(.green)
                    .symbolSize(10)
                    .opacity(0.2)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1, 2]))
                        .foregroundStyle(Color.white.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(Color.white)
                }
            }
            .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: viewModel.minValue - 1, upper: viewModel.maxValue)))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: viewModel.days.count)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                        .foregroundStyle(Color.white)
                }
            }
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
