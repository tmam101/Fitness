//
//  TodayView.swift
//  Fitness
//
//  Created by Thomas on 2/27/23.
//

import SwiftUI
import Charts
import Combine

class TodayBarViewModel: ObservableObject {
    @Published var today: Day
    @Published var maxValue: Double
    @Published var minValue: Double
    @Published var yValues: [Double]
    
    init(today: Day, maxValue: Double, minValue: Double, yValues: [Double]) {
        self.today = today
        self.maxValue = maxValue
        self.minValue = minValue
        self.yValues = yValues
    }
}

// MARK: TODAY BAR

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

enum RingColor {
    case red
    case green
    case purple
    case orange
    case white
    case yellow
    
    var color: Color {
        switch self {
        case .red:
            return .red
        case .green:
               return .green
        case .purple:
            return .purple
        case .orange:
            return .orange
        case .white:
            return .white
        case .yellow:
            return .yellow

        }
    }
}

struct RingViewModel: Hashable, Identifiable {
    static func == (lhs: RingViewModel, rhs: RingViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: UUID = UUID()
    var titleText: String
    var bodyText: String
    var subBodyText: String
    var percentage: Double
    var color: RingColor = .yellow
    var bodyTextColor: RingColor = .white
    var subBodyTextColor: RingColor = .white
    var gradient: [RingColor]?
    var lineWidth: CGFloat = 10
    var fontSize: CGFloat = 40
    var includeTitle: Bool = true
    var includeSubBody: Bool = true
    var shouldPad: Bool = true
}

struct OptionalPadding: ViewModifier {
    var shouldPad: Bool
    func body(content: Content) -> some View {
        if shouldPad {
            content
                .padding()
        } else {
            content
        }
    }
}

struct RingView: View {
    var vm: RingViewModel
    @State var animate: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if vm.includeTitle {
                Text(vm.titleText)
                    .bold()
                    .foregroundColor(.white)
            }
            ZStack {
                VStack {
                    Text(vm.bodyText)
                        .font(.system(size: vm.fontSize))
                        .foregroundColor(vm.bodyTextColor.color)
                    if vm.includeSubBody {
                        Text(vm.subBodyText)
                            .foregroundColor(vm.subBodyTextColor.color)
                    }
                }
                if let g = vm.gradient {
                    let gradient = LinearGradient(
                        gradient: .init(colors: g.map(\.color)),
                        startPoint: animate ? .topLeading : .topTrailing,
                        endPoint: animate ? .bottomTrailing : .bottomLeading
                    )
                    Circle()
                        .stroke(style: .init(lineWidth: 1))
                        .foregroundColor(.gray)
                    Circle()
                        .trim(from: 0, to: vm.percentage)
                        .stroke(style: StrokeStyle(lineWidth: vm.lineWidth, lineCap: .round, lineJoin: .round))
                        .fill(gradient)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.easeOut(duration: 1), value: vm.percentage)
                    
                } else {
                    Circle()
                        .stroke(style: .init(lineWidth: 1))
                        .foregroundColor(.gray)
                    GenericCircle(color: vm.color.color, starting: 0, ending: vm.percentage, opacity: 1)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
        .modifier(OptionalPadding(shouldPad: vm.shouldPad))
    }
}

class TestVM: ObservableObject {
    @Published var today: Day
    
    init(today: Day) {
        self.today = today
    }
}

// MARK: TODAY VIEW
struct TodayView: View {
    @EnvironmentObject var vm: TestVM
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
    @State var columnCount: Int = 2
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let today = vm.today {
                    let overallItem = RingViewModel(titleText: "Overall Score", bodyText: String(Int(averagePercentage * 100)) + "%", subBodyText: "overall", percentage: averagePercentage, bodyTextColor: .white, gradient: [.yellow, .purple, .orange, .yellow, .orange, .purple])
                    
                    let sign = today.surplus > 0 ? "+" : ""
                    let bodyText = "\(sign)\(Int(today.surplus))"
                    let color: RingColor = today.surplus > 0 ? .red : .yellow
                    let netEnergyItem = RingViewModel(titleText: "Net Energy", bodyText: bodyText, subBodyText: "cals", percentage: deficitPercentage, color: .yellow, bodyTextColor: color, subBodyTextColor: color)
                    
                    let proteinItem = RingViewModel(titleText: "Protein", bodyText: proteinPercentage.percentageToWholeNumber() + "/30%", subBodyText: "cals", percentage: proteinGoalPercentage, color: .purple, bodyTextColor: .purple, subBodyTextColor: .purple)
                    
                    let activeCalorieItem = RingViewModel(titleText: "Active Calories", bodyText: String(Int(today.activeCalories)), subBodyText: "cals", percentage: activeCaloriePercentage, color: .orange, bodyTextColor: .orange, subBodyTextColor: .orange)
                    
                    let weightChangeItem = RingViewModel(titleText: "Weight Change", bodyText: today.expectedWeightChangedBasedOnDeficit.roundedString(), subBodyText: "pounds", percentage: weightChangePercentage, color: .green, bodyTextColor: .green, subBodyTextColor: .green)
                    
                    let vms = [overallItem, proteinItem, activeCalorieItem, weightChangeItem, netEnergyItem]
                    
                    let columns: [GridItem] = {
                        var c: [GridItem] = []
                        for _ in 1...columnCount {
                            c.append(GridItem(.adaptive(minimum: 400)))
                        }
                        return c
                    }()
                    Text("Fitness")
                        .foregroundColor(.white)
                        .font(.title)
                        .padding([.leading])
                        .bold()
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(vms, id: \.self) { item in
                            RingView(vm: item)
                                .mainBackground()
                        }
                        TodayBar()
                            .environmentObject(TodayBarViewModel(today: vm.today, maxValue: maxValue, minValue: minValue, yValues: yValues))
                            .padding()
                            .mainBackground()
                    }
                    .padding(.horizontal)
                }
            }
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
            var today: Day?
            switch environment {
            case .release:
                today = await HealthData.getToday()
            default:
                today = TestData.today
            }
            if let today {
                let maxValue = max(today.surplus, maxValue)
                let minValue = min(today.surplus, minValue)
                let lineEvery = Double(500)
                let topLine = Int(maxValue - (maxValue.truncatingRemainder(dividingBy: lineEvery)))
                let bottomLine = Int(minValue - (minValue.truncatingRemainder(dividingBy: lineEvery)))
                var yValues: [Double] = []
                for i in stride(from: bottomLine, through: topLine, by: Int(lineEvery)) {
                    yValues.append(Double(i))
                }
                self.yValues = yValues
                self.maxValue = maxValue
                self.minValue = minValue
                
                self.deficitPercentage = today.deficit / 1000
                self.protein = (today.protein * today.caloriesPerGramOfProtein) / today.consumedCalories
                self.proteinPercentage = protein.isNaN ? 0 : protein
                self.proteinGoalPercentage = proteinPercentage / 0.3
                self.activeCaloriePercentage = today.activeCalories / 900
                self.averagePercentage = (deficitPercentage + proteinGoalPercentage + activeCaloriePercentage) / 3
                self.weightChangePercentage = today.expectedWeightChangedBasedOnDeficit / (-2/7)
                vm.today = today
            }
        }
    }
}

struct Prev: View {
//    @State var day = TestData.emptyDay
    @State var vm = TestVM(today: TestData.today)

    var body: some View {
        TodayView(environment: .debug)
            .environmentObject(vm)
            .background(Color.black)
    }
}
    
// MARK: PREVIEW
struct Previews_TodayView_Previews: PreviewProvider {
    @State var day = TestData.emptyDay
    static var previews: some View {
        Prev()
//                    .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))

    }
}
