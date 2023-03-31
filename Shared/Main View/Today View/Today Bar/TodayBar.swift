//
//  TodayBar.swift
//  Fitness
//
//  Created by Thomas on 3/31/23.
//

import Foundation
import SwiftUI
import Charts

struct TodayBar: View {
    @EnvironmentObject var vm: TodayBarViewModel
    
    func gradient(for day: Day) -> LinearGradient {
        let gradientColors = {
            var colors: [Color] = []
            for _ in 0..<100 {
                colors.append(.orange)
            }
            colors.append(.yellow)
            return colors
        }()
        let gradientPercentage = CGFloat(day.activeCalorieToDeficitRatio)
        let midPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y * (1 - gradientPercentage))
        let startPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y)
        let gradientStyle: LinearGradient = .linearGradient(colors: gradientColors,
                                                            startPoint: startPoint,
                                                            endPoint: midPoint)
        return gradientStyle
    }
    
    var body: some View {
        let today = vm.today
        Chart([today]) { day in
            if day.surplus > 0 {
                BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                    .cornerRadius(5)
                    .foregroundStyle(.red)
            }
            else {
                BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                    .cornerRadius(5)
                    .foregroundStyle(gradient(for: day))
            }
        }
        .backgroundStyle(.yellow)
        .chartYAxis {
            AxisMarks(values: vm.yValues) { value in
                if let _ = value.as(Double.self) {
                    AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1, 2]))
                        .foregroundStyle(Color.white.opacity(0.5))
                    if value.as(Double.self) == 0.0 {
                        AxisValueLabel("0 cal")
                        //                        AxisValueLabel()
                            .foregroundStyle(Color.white)
                        //                            .font(.title)
                            .font(.system(size: 20))
                    } else {
                        AxisValueLabel()
                            .foregroundStyle(Color.white)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(), centered: true)
                    .foregroundStyle(Color.white)
            }
        }
        .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: vm.minValue, upper: vm.maxValue)))
    }
}
