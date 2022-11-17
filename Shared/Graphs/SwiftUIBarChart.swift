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

private class ViewModel: ObservableObject {
    @State private var health: HealthData?
    @Published var days: [Day] = []
    @Published var maxValue: Double = 0
    @Published var minValue: Double = 0
    @Published var gradientColors: [Color] = []
    private var cancellables: [AnyCancellable] = []
    @Published var yValues: [Double] = []
    
    init(health: HealthData) {
        self.health = health
        health.$hasLoaded.sink(
            receiveCompletion: { _ in },
            receiveValue: { hasLoaded in
                if hasLoaded {
                    let days = {
                        switch health.environment {
                        case .debug:
                            return [Day(date: Date.subtract(days: 0, from: Date()), deficit: 1000, activeCalories: 200),
                                    Day(date: Date.subtract(days: 1, from: Date()), deficit: 300, activeCalories: 200),
                                    Day(date: Date.subtract(days: 2, from: Date()), deficit: 200, activeCalories: 200),
                                    Day(date: Date.subtract(days: 3, from: Date()), deficit: -200, activeCalories: 200),
                                    Day(date: Date.subtract(days: 4, from: Date()), deficit: 1200, activeCalories: 500),
                                    Day(date: Date.subtract(days: 5, from: Date()), deficit: 200, activeCalories: 200),
                                    Day(date: Date.subtract(days: 6, from: Date()), deficit: 200, activeCalories: 200),
                                    Day(date: Date.subtract(days: 7, from: Date()), deficit: 100, activeCalories: 200)]
                        case .release:
                            return health.days.filter { $0.key <= 7 }
                                .values
                                .sorted(by: { $0.daysAgo < $1.daysAgo })
                        default:
                            return []
                            
                        }
                    }()
                    self.days = days
                    self.maxValue = Double(days.map(\.surplus).max() ?? 1.0)
                    self.maxValue = self.maxValue.rounded(toNextSignificant: 500)
                    self.minValue = Double(days.map(\.surplus).min() ?? 0.0)
                    self.minValue = self.minValue.rounded(toNextSignificant: 500)
                    self.gradientColors = {
                        var colors: [Color] = []
                        for _ in 0..<100 {
                            colors.append(.orange)
                        }
                        colors.append(.yellow)
                        return colors
                    }()
                    let diff = self.maxValue - self.minValue
                    let lineEvery = Double(500)
                    let number = Int(diff / lineEvery)
                    for i in 0...number {
                        self.yValues.append(self.minValue + (lineEvery * Double(i)))
                    }
                }
            }).store(in: &cancellables)
    }
    
    func gradient(for day: Day) -> LinearGradient {
        let gradientPercentage = CGFloat(day.activeCalorieToDeficitRatio)
        let midPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y * (1 - gradientPercentage))
        let startPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y)
        let gradientStyle: LinearGradient = .linearGradient(colors: gradientColors,
                                                            startPoint: startPoint,
                                                            endPoint: midPoint)
        return gradientStyle
    }
}

// MARK: SWIFTUI BAR CHART

struct SwiftUIBarChart: View {
    @State fileprivate var vm: ViewModel
    
    init(health: HealthData) {
        vm = ViewModel(health: health)
    }
    
    var body: some View {
        Group {
            Chart(vm.days) { day in
                if day.surplus > 0 {
                    BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                        .cornerRadius(5)
                        .foregroundStyle(.red)
                } else {
                    BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                        .cornerRadius(5)
                        .foregroundStyle(vm.gradient(for: day))
                }
            }
            .backgroundStyle(.yellow)
            .chartYAxis {
                AxisMarks(values: vm.yValues) { value in
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
            .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: vm.minValue, upper: vm.maxValue)))
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
