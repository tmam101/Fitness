//
//  TodayView.swift
//  Fitness
//
//  Created by Thomas on 2/27/23.
//

import SwiftUI
import Charts
import Combine

//// MARK: VIEW MODEL
//private class ViewModel: ObservableObject {
//    var environment: AppEnvironmentConfig = .release
//    @Published var day: Day?
//    @Published var maxValue: Double = 1000
//    @Published var minValue: Double = -1000
//    @Published var yValues: [Double] = []
//
//    init(day: Day) {
//        self.day = day
//        let maxValue = max(day.surplus, maxValue)
//        let minValue = min(day.surplus, minValue)
//        let lineEvery = Double(500)
//        let topLine = Int(maxValue - (maxValue.truncatingRemainder(dividingBy: lineEvery)))
//        let bottomLine = Int(minValue - (minValue.truncatingRemainder(dividingBy: lineEvery)))
//        for i in stride(from: bottomLine, through: topLine, by: Int(lineEvery)) {
//            self.yValues.append(Double(i))
//        }
//        self.maxValue = maxValue
//        self.minValue = minValue
//    }
//
//    func gradient(for day: Day) -> LinearGradient {
//        let gradientColors = {
//            var colors: [Color] = []
//            for _ in 0..<100 {
//                colors.append(.orange)
//            }
//            colors.append(.yellow)
//            return colors
//        }()
//        let gradientPercentage = CGFloat(day.activeCalorieToDeficitRatio)
//        let midPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y * (1 - gradientPercentage))
//        let startPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y)
//        let gradientStyle: LinearGradient = .linearGradient(colors: gradientColors,
//                                                            startPoint: startPoint,
//                                                            endPoint: midPoint)
//        return gradientStyle
//    }
//}

// MARK: TODAY BAR

struct TodayBar: View {
    @State var today: Day
    @State var maxValue: Double
    @State var minValue: Double
    @State var yValues: [Double]
    
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
            AxisMarks(values: yValues) { value in
                if let _ = value.as(Double.self) {
                    AxisGridLine(centered: true, stroke: StrokeStyle(dash: [1, 2]))
                        .foregroundStyle(Color.white.opacity(0.5))
                    if value.as(Double.self) == 0.0 {
                        AxisValueLabel("0 cal")
//                        AxisValueLabel()
                            .foregroundStyle(Color.white)
//                            .font(.title)
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
        .chartYScale(domain: ClosedRange(uncheckedBounds: (lower: minValue, upper: maxValue)))
    }
}

struct RingView: View {
    var titleText: String
    var bodyText: String
    var subBodyText: String
    var color: Color
    var percentage: Double
    var gradient: LinearGradient?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(titleText)
                .bold()
                .foregroundColor(.white)
            ZStack {
                VStack {
                    Text(bodyText)
                        .font(.system(size: 40))
                        .foregroundColor(color)
                    Text(subBodyText)
                        .foregroundColor(color)
                }
                if let gradient {
                    Circle()
                        .trim(from: 0, to: percentage)
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .fill(gradient)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.easeOut(duration: 1), value: percentage)
                } else {
                    GenericCircle(color: color, starting: 0, ending: percentage, opacity: 1)
                }
            }
        }.padding()
    }
}

// MARK: TODAY VIEW
struct TodayView: View {
    @State var today: Day? = nil
    @Environment(\.scenePhase) private var scenePhase
    var environment: AppEnvironmentConfig = .release
    let paddingAmount: CGFloat = 2 * 10
    
    @State var maxValue: Double = 1000
    @State var minValue: Double = -1000
    @State var yValues: [Double] = []
    @State var deficitPercentage: CGFloat = 0
    @State var protein: Double = 0
    @State var proteinPercentage: Double = 0
    @State var proteinGoalPercentage: CGFloat = 0
    @State var activeCaloriePercentage: CGFloat = 0
    @State var averagePercentage: CGFloat = 0
    @State var weightChangePercentage: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let sectionHeight = (geometry.size.height / 3) - paddingAmount
            HStack(alignment: .top) {
                if let today {
                    VStack(alignment: .leading) {
                        let sign = today.surplus > 0 ? "+" : ""
                        let bodyText = "\(sign)\(Int(today.surplus))"
                        let color: Color = today.surplus > 0 ? .red : .yellow
                        RingView(titleText: "Net Energy", bodyText: bodyText, subBodyText: "cals", color: color, percentage: deficitPercentage)
                            .frame(maxWidth: .infinity, maxHeight: sectionHeight)
                            .mainBackground()
                        
                        TodayBar(today: today, maxValue: maxValue, minValue: minValue, yValues: yValues)
                            .frame(maxHeight: sectionHeight)
                            .padding()
                            .mainBackground()
                        
                        RingView(titleText: "Overall SCore", bodyText: String(Int(averagePercentage * 100)) + "%", subBodyText: "overall", color: .white, percentage: averagePercentage, gradient: LinearGradient(
                            gradient: .init(colors: [.yellow, .purple, .orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(maxWidth: .infinity, maxHeight: sectionHeight)
                        .mainBackground()
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading) {
                        RingView(titleText: "Protein", bodyText: proteinPercentage.percentageToWholeNumber() + "/30%", subBodyText: "cals", color: .purple, percentage: proteinGoalPercentage)
                        .frame(maxWidth: .infinity, maxHeight: sectionHeight)
                        .mainBackground()
                        
                        RingView(titleText: "ActiveCalories", bodyText: String(Int(today.activeCalories)), subBodyText: "cals", color: .orange, percentage: activeCaloriePercentage)
                        .frame(maxWidth: .infinity, maxHeight: sectionHeight)
                        .mainBackground()
                        
                        RingView(titleText: "ExpectedWeightChange", bodyText: today.expectedWeightChangedBasedOnDeficit.roundedString(), subBodyText: "pounds", color: .green, percentage: weightChangePercentage)
                        
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
            if let today = self.today {
                let maxValue = max(today.surplus, maxValue)
                let minValue = min(today.surplus, minValue)
                let lineEvery = Double(500)
                let topLine = Int(maxValue - (maxValue.truncatingRemainder(dividingBy: lineEvery)))
                let bottomLine = Int(minValue - (minValue.truncatingRemainder(dividingBy: lineEvery)))
                for i in stride(from: bottomLine, through: topLine, by: Int(lineEvery)) {
                    self.yValues.append(Double(i))
                }
                self.maxValue = maxValue
                self.minValue = minValue
                
                self.deficitPercentage = today.deficit / 1000
                self.protein = (today.protein * today.caloriesPerGramOfProtein) / today.consumedCalories
                self.proteinPercentage = protein.isNaN ? 0 : protein
                self.proteinGoalPercentage = proteinPercentage / 0.3
                self.activeCaloriePercentage = today.activeCalories / 900
                self.averagePercentage = (deficitPercentage + proteinGoalPercentage + activeCaloriePercentage) / 3
                self.weightChangePercentage = today.expectedWeightChangedBasedOnDeficit / (-2/7)
            }
        }
    }
}
    
// MARK: PREVIEW
struct Previews_TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView(environment: .debug)
            .background(Color.black)
                    .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))

    }
}
