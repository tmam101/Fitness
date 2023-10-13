//
//  SwiftUILineChart.swift
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
        print("timeFrame \(timeFrame)")
        print("keys \(health.days.keys) \(health.days.filter { $0.key <= timeFrame.days }.count)")
        return health.days.filter { $0.key <= timeFrame.days }
            .values
            .sorted(by: { $0.daysAgo < $1.daysAgo })
    }
    
    private func updateMinMaxValues() {
        maxValue = days.map {
            $0.expectedWeight + $0.expectedWeightChangeBasedOnDeficit
        }.max() ?? 1
        minValue = days.map {
            $0.expectedWeight + $0.expectedWeightChangeBasedOnDeficit
        }.min() ?? 0
    }
}

struct SwiftUILineChart: View {
    @ObservedObject private var viewModel: LineChartViewModel
    
    init(health: HealthData, timeFrame: TimeFrame) {
        self.viewModel = LineChartViewModel(health: health, timeFrame: timeFrame)
    }
    
    //TODO: The initial weight doesn't quite match up with the deficit line.
    var body: some View {
        Group {
            Chart(viewModel.days) { day in
                LineMark(x: .value("Days ago", day.date), y: .value("Expected Weight", day.expectedWeightTomorrow))
                    .foregroundStyle(.yellow)
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

struct SwiftUILineChart_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUILineChart(health: HealthData(environment: .debug), timeFrame: .init(longName: "This Week", name: "Week", days: 7))
            .mainBackground()
        FitnessPreviewProvider.MainPreview()
    }
}
