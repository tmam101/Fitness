//
//  TodayView.swift
//  Fitness
//
//  Created by Thomas on 2/27/23.
//

import SwiftUI
import Charts
import Combine

// MARK: VIEW MODEL
private class ViewModel: ObservableObject {
    var environment: AppEnvironmentConfig = .release
    @Published var day: Day?
    @Published var maxValue: Double = 1000
    @Published var minValue: Double = -1000
    @Published var yValues: [Double] = []
    var goalSurplus: Double = -1000 // TODO Cleanup
    
    init(day: Day) {
        self.day = day
        let maxValue = max(day.surplus, maxValue)
        let minValue = min(day.surplus, minValue)
        let lineEvery = Double(500)
        let topLine = Int(maxValue - (maxValue.truncatingRemainder(dividingBy: lineEvery)))
        let bottomLine = Int(minValue - (minValue.truncatingRemainder(dividingBy: lineEvery)))
        for i in stride(from: bottomLine, through: topLine, by: Int(lineEvery)) {
            self.yValues.append(Double(i))
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

// MARK: TODAY BAR

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
                    if value.as(Double.self) == 0.0 {
                        AxisValueLabel("0 cal")
//                        AxisValueLabel()
                            .foregroundStyle(Color.white)
                            .font(.title)
//                            .font(.system(size: 20))
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
// MARK: TODAY VIEW
struct TodayView: View {
    @State var today: Day? = nil
    @State fileprivate var vm: ViewModel?
    @Environment(\.scenePhase) private var scenePhase
    var environment: AppEnvironmentConfig = .release
//    let sectionHeight: CGFloat = 273.0
    let paddingAmount: CGFloat = 2 * 10
    
    var body: some View {
        GeometryReader { geometry in
            let sectionHeight = (geometry.size.height / 3) - paddingAmount
            HStack(alignment: .top) {
                if let vm, let today {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text("Net Energy")
                                .bold()
                                .foregroundColor(.white)
                            let sign = today.surplus > 0 ? "+" : ""
                            ZStack {
                                let deficitPercentage = today.deficit / 1000
                                let color: Color = today.surplus > 0 ? .red : .yellow
                                VStack {
                                    Text("\(sign)\(Int(today.surplus))")
                                        .font(.system(size: 40))
                                        .foregroundColor(color)
                                    Text("cals")
                                        .foregroundColor(color)
                                }
                                GenericCircle(color: color, starting: 0, ending: deficitPercentage, opacity: 1)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: sectionHeight)
                        .mainBackground()
                        TodayBar(today: today, vm: vm)
                            .frame(maxHeight: (sectionHeight * 2) - paddingAmount)
                            .padding()
                            .mainBackground()
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            let protein = (today.protein * today.caloriesPerGramOfProtein) / today.consumedCalories
                            let proteinPercentage = protein.isNaN ? 0 : protein
                            Text("Protein")
                                .foregroundColor(.white)
                            Text(proteinPercentage.percentageToWholeNumber() + "/30% of cals")
                                .foregroundColor(.white)
                            ZStack {
                                Text(proteinPercentage.percentageToWholeNumber() + "%")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 60))
                                GenericCircle(color: .purple, starting: 0, ending: proteinPercentage / 0.3, opacity: 1)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: sectionHeight)
                        .mainBackground()
                        
                        VStack(alignment: .leading) {
                            Text("Active Calories")
                                .foregroundColor(.white)
                            ZStack {
                                let caloriePercentage = today.activeCalories / 900
                                let color: Color = .orange
                                VStack {
                                    Text(String(Int(today.activeCalories)))
                                        .font(.system(size: 40))
                                        .foregroundColor(color)
                                    Text("cals")
                                        .foregroundColor(color)
                                }
                                GenericCircle(color: color, starting: 0, ending: caloriePercentage, opacity: 1)
                            }
//                            Text(String(Int(today.realActiveCalories)))
//                                .foregroundColor(.orange)
//                                .font(.system(size: 60))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: sectionHeight)
                        .mainBackground()
                        
                        VStack(alignment: .leading) {
                            Text("Expected Weight Change")
                                .foregroundColor(.white)
                            ZStack {
                                let deficitPercentage = today.expectedWeightChangedBasedOnDeficit / (-2/7)
                                let color: Color = .green
                                VStack {
                                    Text(today.expectedWeightChangedBasedOnDeficit.roundedString())
                                        .font(.system(size: 40))
                                        .foregroundColor(color)
                                    Text("pounds")
                                        .foregroundColor(color)
                                }
                                GenericCircle(color: color, starting: 0, ending: deficitPercentage, opacity: 1)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: sectionHeight)
                        .mainBackground()
                        
                    }
                }
            }
            .padding(20)
        }
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
    
// MARK: PREVIEW
struct Previews_TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView(environment: .debug)
            .background(Color.black)
//                    .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))

    }
}
