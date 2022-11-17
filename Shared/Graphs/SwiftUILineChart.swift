//
//  SwiftUILineChart.swift
//  Fitness
//
//  Created by Thomas Goss on 11/16/22.
//

import SwiftUI
import Charts
import Combine

private class ViewModel: ObservableObject {
    @State private var health: HealthData
    var days: [Day] = []
    private var cancellables: [AnyCancellable] = []
    @Published var maxValue: Double = 0
    @Published var minValue: Double = 0

    init(health: HealthData) {
        self.health = health
        health.$hasLoaded.sink(
            receiveCompletion: { _ in },
            receiveValue: { hasLoaded in
                if hasLoaded {
                    let days = {
                        switch health.environment {
                        case .debug:
                            return [Day(date: Date.subtract(days: 0, from: Date()), daysAgo: 0, activeCalories: 200, expectedWeight: 200.0),
                                    Day(date: Date.subtract(days: 1, from: Date()), daysAgo: 1, activeCalories: 200, expectedWeight: 199),
                                    Day(date: Date.subtract(days: 2, from: Date()), daysAgo: 2, activeCalories: 200, expectedWeight: 201),
                                    Day(date: Date.subtract(days: 3, from: Date()), daysAgo: 3, activeCalories: 200, expectedWeight: 200.0),
                                    Day(date: Date.subtract(days: 4, from: Date()), daysAgo: 4, activeCalories: 500, expectedWeight: 200.0),
                                    Day(date: Date.subtract(days: 5, from: Date()), daysAgo: 5, activeCalories: 200, expectedWeight: 200.0),
                                    Day(date: Date.subtract(days: 6, from: Date()), daysAgo: 6, activeCalories: 200, expectedWeight: 200.0),
                                    Day(date: Date.subtract(days: 7, from: Date()), daysAgo: 7, activeCalories: 200, expectedWeight: 200.0)]
                        case .release:
                            return health.days.filter { $0.key <= 31 }
                                .values
                                .sorted(by: { $0.daysAgo < $1.daysAgo })
                        default:
                            return []
                            
                        }
                    }()
                    self.days = days
                    self.maxValue = days.map(\.expectedWeight).max() ?? 1
                    self.minValue = days.map(\.expectedWeight).min() ?? 0
                }
            }).store(in: &cancellables)
        
    }
}

struct SwiftUILineChart: View {
    @State fileprivate var vm: ViewModel
    
    init(health: HealthData) {
        self.vm = ViewModel(health: health)
    }
    
    var body: some View {
        Group {
            Chart(vm.days) { day in
                LineMark(x: .value("Days ago", day.date), y: .value("Expected Weight", day.expectedWeight))
                    .foregroundStyle(.yellow)
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
//                    if let _ = value.as(Double.self) {
                        AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1, 2]))
                            .foregroundStyle(Color.white.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(Color.white)
//                    }
                }
            }
            .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: vm.minValue, upper: vm.maxValue)))
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
