//  NetEnergyBarChart.swift
//  Fitness
//
//  Created by Thomas Goss on 11/16/22.

import Foundation
import SwiftUI
import Charts
import Combine

// MARK: VIEW MODEL

class NetEnergyBarChartViewModel: ObservableObject {
    @Published var days: [Day] = []
    @Published var maxValue: Double = 0
    @Published var minValue: Double = 0
    @Published var gradientColors: [Color] = Array(repeating: .orange, count: 101) + [.yellow]
    private var cancellables: [AnyCancellable] = []
    @Published var yValues: [Double] = []
    
    // Constants
    private let lineInterval: Double = 500
    
    init(health: HealthData) {
        switch health.environment {
        case .debug:
            populateDays(for: health)
        case .release, .widgetRelease:
            health.$hasLoaded.sink { [weak self] hasLoaded in
                guard let self = self, hasLoaded else { return }
                self.populateDays(for: health)
            }.store(in: &cancellables)
        }
    }

    private func populateDays(for health: HealthData) {
        setupDays(using: health)
        updateMinMaxValues()
        setupYValues()
    }

    func setupDays(using health: HealthData) {
        switch health.environment {
        case .debug:
            days = Array(Days.testDays.values).sorted { $0.date < $1.date }.filter { $0.daysAgo <= 7}
        case .release:
            days = health.days.filter { $0.key <= 7 }.values.sorted { $0.daysAgo < $1.daysAgo }
        default:
            days = []
        }
    }
    
    func updateMinMaxValues() {
        maxValue = Double(days.map(\.surplus).max() ?? 1.0).rounded(toNextSignificant: lineInterval)
        maxValue = max(0, maxValue)
        minValue = Double(days.map(\.surplus).min() ?? 0.0).rounded(toNextSignificant: lineInterval)
        minValue = min(0, minValue)
    }
    
    func setupYValues() {
        let diff = maxValue - minValue
        let number = Int(diff / lineInterval)
        yValues = (0...number).map { minValue + (lineInterval * Double($0)) }
    }
    
    func gradient(for day: Day) -> LinearGradient {
        let gradientPercentage = CGFloat(day.activeCalorieToDeficitRatio)
        let midPoint = UnitPoint(x: 0.5, y: (1 - gradientPercentage))
        return LinearGradient(colors: gradientColors, startPoint: .bottom, endPoint: midPoint)
    }
}

// MARK: SWIFTUI BAR CHART

struct NetEnergyBarChart: View {
    @ObservedObject private var viewModel: NetEnergyBarChartViewModel
    
    init(health: HealthData) {
        viewModel = NetEnergyBarChartViewModel(health: health)
    }
    
    var body: some View {
        Group {
            Chart(viewModel.days) { day in
                BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                    .cornerRadius(5)
                    .foregroundStyle(day.surplus > 0 ? Color.red.solidColorGradient() : viewModel.gradient(for: day))
                    .opacity(day.daysAgo == 0 ? 0.5 : 1.0)

            }
            .backgroundStyle(.yellow)
            .chartYAxis {
                AxisMarks(values: viewModel.yValues) { value in
                    if let _ = value.as(Double.self) {
                        AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1, 2]))
                            .foregroundStyle(Color.white.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                        .foregroundStyle(Color.white)
                }
            }
            .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: viewModel.minValue, upper: viewModel.maxValue)))
        }
        .padding()
    }
}

struct NetEnergyBarChart_Previews: PreviewProvider {
    static var previews: some View {
        NetEnergyBarChart(health: HealthData(environment: .debug))
            .mainBackground()
        // More preview configurations can be added as needed
    }
}
