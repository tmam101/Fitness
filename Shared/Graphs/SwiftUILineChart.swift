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
    
    init(health: HealthData) {
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
        switch health.environment {
        case .debug:
            return (0...7).map {
                Day(date: Date.subtract(days: $0, from: Date()),
                    daysAgo: $0,
                    activeCalories: 200,
                    expectedWeight: [200, 201, 198, 197, 200, 202, 203, 205][$0])
            }
        case .release:
            return health.days.filter { $0.key <= 31 }
                .values
                .sorted(by: { $0.daysAgo < $1.daysAgo })
        default:
            return []
        }
    }
    
    private func updateMinMaxValues() {
        maxValue = days.map(\.expectedWeight).max() ?? 1
        minValue = days.map(\.expectedWeight).min() ?? 0
    }
}

struct SwiftUILineChart: View {
    @State private var viewModel: LineChartViewModel
    
    init(health: HealthData) {
        self.viewModel = LineChartViewModel(health: health)
    }
    
    var body: some View {
        Group {
            Chart(viewModel.days) { day in
                LineMark(x: .value("Days ago", day.date), y: .value("Expected Weight", day.expectedWeight))
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
            .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: viewModel.minValue, upper: viewModel.maxValue)))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
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
        SwiftUILineChart(health: HealthData(environment: .debug))
            .mainBackground()
        FitnessPreviewProvider.MainPreview()
    }
}
