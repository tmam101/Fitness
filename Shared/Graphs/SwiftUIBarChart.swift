//
//  SwiftUIBarChart.swift
//  Fitness
//
//  Created by Thomas Goss on 11/16/22.
//

import Foundation
import SwiftUI
import Charts
import Combine

// MARK: VIEW MODEL

class SwiftUIBarChartViewModel: ObservableObject {
    @Published var days: [Day] = []
    @Published var maxValue: Double = 0
    @Published var minValue: Double = 0
    @Published var gradientColors: [Color] = Array(repeating: .orange, count: 101) + [.yellow]
    private var cancellables: [AnyCancellable] = []
    @Published var yValues: [Double] = []
    
    init(health: HealthData) {
        health.$hasLoaded.sink { [weak self] hasLoaded in
            guard let self = self else { return }
            if hasLoaded {
                self.setupDays(using: health)
                self.updateMinMaxValues()
                self.setupYValues()
            }
        }.store(in: &cancellables)
    }
    
    func setupDays(using health: HealthData) {
        switch health.environment {
        case .debug:
            days = (0...7).map {
                Day(
                    date: Date.subtract(days: $0, from: Date()),
                    deficit: [1000, 300, 200, -200, 1200, 200, 200, 100][$0],
                    activeCalories: 200)
            }
        case .release:
            days = health.days.filter { $0.key <= 7 }.values.sorted { $0.daysAgo < $1.daysAgo }
        default:
            days = []
        }
    }
    
    func updateMinMaxValues() {
        maxValue = Double(days.map(\.surplus).max() ?? 1.0).rounded(toNextSignificant: 500)
        minValue = Double(days.map(\.surplus).min() ?? 0.0).rounded(toNextSignificant: 500)
    }
    
    func setupYValues() {
        let diff = maxValue - minValue
        let lineEvery = Double(500)
        let number = Int(diff / lineEvery)
        yValues = (0...number).map { minValue + (lineEvery * Double($0)) }
    }
    
    func gradient(for day: Day) -> LinearGradient {
        let gradientPercentage = CGFloat(day.activeCalorieToDeficitRatio)
        let midPoint = UnitPoint(x: 0.5, y: (1 - gradientPercentage))
        return LinearGradient(colors: gradientColors, startPoint: .bottom, endPoint: midPoint)
    }
}

// MARK: SWIFTUI BAR CHART

struct SwiftUIBarChart: View {
    @State private var viewModel: SwiftUIBarChartViewModel
    
    init(health: HealthData) {
        viewModel = SwiftUIBarChartViewModel(health: health)
    }
    
    var body: some View {
        Group {
            Chart(viewModel.days) { day in
                if day.surplus > 0 {
                    BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                        .cornerRadius(5)
                        .foregroundStyle(.red)
                } else {
                    BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                        .cornerRadius(5)
                        .foregroundStyle(viewModel.gradient(for: day))
                }
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

struct SwiftUIBarChart_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIBarChart(health: HealthData(environment: .debug))
//            .environmentObject(HealthData(environment: .debug))
            .mainBackground()
        FitnessPreviewProvider.MainPreview()
    }
}
