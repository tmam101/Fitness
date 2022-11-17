//
//  SwiftUIBarChart.swift
//  Fitness
//
//  Created by Thomas Goss on 11/16/22.
//

import Foundation
import SwiftUI
import Charts

struct SwiftUIBarChart: View {
    @EnvironmentObject var health: HealthData
    var body: some View {
        Group {
            let days: [Day] = {
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
            let maxValue = Double(days.map(\.surplus).max() ?? 1.0)
            let minValue = Double(days.map(\.surplus).min() ?? 0.0)

            Chart(days) { day in
                let gradientPercentage = CGFloat(day.activeCalories / day.deficit)
                let gradientColors: [Color] = {
                    var colors: [Color] = []
                    for _ in 0..<100 {
                        colors.append(.orange)
                    }
                    colors.append(.yellow)
                    return colors
//                    [.orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .yellow]
                }()
                let midPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y * (1 - gradientPercentage))
                let startPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y)
                let gradientStyle: LinearGradient = .linearGradient(colors: gradientColors,
                                                   startPoint: startPoint,
                                                   endPoint: midPoint)
                if day.surplus > 0 {
                    BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                        .cornerRadius(5)
                        .foregroundStyle(.red)
                } else {
                    BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                        .cornerRadius(5)
                        .foregroundStyle(gradientStyle)
                }
            }
//            .chartForegroundStyleScale(domain:
//                                        days.compactMap({ day in
//                day.surplus
//            }), range: markColors)
            .backgroundStyle(.yellow)
            .chartPlotStyle { plotContent in
                plotContent
//                    .background(.green.opacity(0.4))
//                    .border(Color.blue, width: 2)
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1, 2]))
                        .foregroundStyle(Color.white)
//                    AxisTick(centered: true, stroke: StrokeStyle(lineWidth: 2))
//                        .foregroundStyle(Color.red)
                    AxisValueLabel()
                        .foregroundStyle(Color.white)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                        .foregroundStyle(Color.white)
                }
            }
            .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: minValue, upper: maxValue)))
        }.padding()
            .padding()
//        .foregroundColor(.red)
        
    }
}

struct SwiftUIBarChart_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIBarChart()
            .environmentObject(HealthData(environment: .debug))
            .mainBackground()
        FitnessPreviewProvider.MainPreview()
    }
}
