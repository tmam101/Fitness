//
//  TodayView.swift
//  Fitness
//
//  Created by Thomas on 2/27/23.
//

import SwiftUI
import Charts
import Combine

private class ViewModel: ObservableObject {
    var environment: AppEnvironmentConfig = .release
    @Published var day: Day?
    @Published var maxValue: Double = 0
    @Published var minValue: Double = 0
    @Published var yValues: [Double] = []
    
    init(day: Day) {
        self.day = day
        var maxValue = day.surplus > 0 ? day.surplus : 0
        maxValue = maxValue == 0 ? maxValue : maxValue.rounded(toNextSignificant: 500)
        var minValue = day.surplus > 0 ? 0 : day.surplus
        minValue = minValue == 0 ? minValue : minValue.rounded(toNextSignificant: 500)
        let diff = maxValue - minValue
        let lineEvery = Double(500)
        let number = Int(diff / lineEvery)
        for i in 0...number {
            self.yValues.append(minValue + (lineEvery * Double(i)))
        }
        self.maxValue = maxValue
        self.minValue = minValue
    }
    
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
}

struct TodayBar: View {
    @State var today: Day
    @State fileprivate var vm: ViewModel
    
    var body: some View {
        Chart([today]) { day in
            if day.surplus > 0 {
                BarMark(x: .value("Day", day.date, unit: .day), y: .value("Deficit", day.surplus))
                    .cornerRadius(5)
                    .foregroundStyle(.red)
            }
            else {
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
}

struct TodayView: View {
    @State var today: Day? = nil
    @State fileprivate var vm: ViewModel?
    @Environment(\.scenePhase) private var scenePhase
    var environment: AppEnvironmentConfig = .release
    
    var body: some View {
        HStack {
            if let vm, let today {
                VStack {
                    Text("You have a deficit of \(Int(today.deficit))! Try to burn \(1000 - Int(today.deficit)) more calories today.")
//                        .frame(maxHeight: .infinity)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    Spacer()
                    TodayBar(today: today, vm: vm)
                        .frame(maxHeight: .infinity)
                }
                Spacer()
                    .frame(width: 100)
                VStack {
                    let proteinPercentage = (today.protein * today.caloriesPerGramOfProtein) / today.consumedCalories
                    Text("Protein")
                        .foregroundColor(.white)
                    Text(proteinPercentage.percentageToWholeNumber() + "/30% of cals")
                        .foregroundColor(.white)
                    GenericCircle(color: .purple, starting: 0, ending: proteinPercentage / 0.3, opacity: 1)
                    Text(String(today.activeCalories))
                        .foregroundColor(.white)
                    Text(String(today.restingCalories))
                        .foregroundColor(.white)
                    Text(String(today.consumedCalories))
                        .foregroundColor(.white)
                }
                .frame(height: nil)
                .padding()
            }
        }.padding()
        .onAppear {
            reloadToday()
            
        }
        .onChange(of: scenePhase) { _ in
            reloadToday()
        }
    }
    
    private func reloadToday() {
        Task {
            switch environment {
            case .release:
                self.today = await HealthData.getToday()
            default:
                self.today = TestData.today
            }
            if let today {
                self.vm = ViewModel(day: today)
            }
        }
    }
}
    

struct Previews_TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView(environment: .debug)
            .background(Color.myGray)
    }
}
