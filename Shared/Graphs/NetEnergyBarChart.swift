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
    var timeFrame: TimeFrame
    
    // Constants
    private let lineInterval: Double = 500
    
    init(health: HealthData, timeFrame: TimeFrame) {
        self.timeFrame = timeFrame
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
        days = health.days
            .filter { $0.key <= timeFrame.days }
            .values
            .sorted { $0.daysAgo < $1.daysAgo }
    }
    
    func updateMinMaxValues() {
        maxValue = Double(days.map(\.netEnergy).max() ?? 1.0).rounded(toNextSignificant: lineInterval)
        maxValue = max(0, maxValue)
        minValue = Double(days.map(\.netEnergy).min() ?? 0.0).rounded(toNextSignificant: lineInterval)
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
    
    init(health: HealthData, timeFrame: TimeFrame) {
        viewModel = NetEnergyBarChartViewModel(health: health, timeFrame: timeFrame)
    }
    
    var body: some View {
        Group {
            Chart(viewModel.days) { day in
                BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.netEnergy))
                    .cornerRadius(5)
                    .foregroundStyle(day.netEnergy > 0 ? Color.red.solidColorGradient() : viewModel.gradient(for: day))
                    .opacity(day.daysAgo == 0 ? 0.5 : 1.0)
                    .accessibilityLabel("bar \(day.daysAgo) days ago")

            }
            .backgroundStyle(.yellow)
            .chartYAxis {
                AxisMarks(values: viewModel.yValues) { value in
                    if let value = value.as(Double.self) {
                        AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1, 2]))
                            .foregroundStyle(Color.white.opacity(0.5))
                        AxisValueLabel("\(Int(value)) cal")
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .chartXAxis {
                if viewModel.days.count < 30 {
                    AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                            .foregroundStyle(Color.white)
                    }
                } else {
                    AxisMarks(values: .stride(by: .day, count:  31)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.wide), centered: true)
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: viewModel.minValue, upper: viewModel.maxValue)))
        }
        .padding()
    }
}

struct NetEnergyBarChart_Previews: PreviewProvider {
    static var previews: some View {
        NetEnergyBarChart(health: HealthData(environment: .debug(nil)), timeFrame: .week)
            .mainBackground()
        // More preview configurations can be added as needed
    }
}
