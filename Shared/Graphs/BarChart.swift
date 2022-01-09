//
//  BarChart.swift
//  Fitness
//
//  Created by Thomas Goss on 4/8/21.
//

import SwiftUI

struct TodaysDate {
    var fullDayName: String = ""
    var days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    func day(subtracting: Int) -> String {
        var index = days.firstIndex(of: fullDayName) ?? 0
        index = index - subtracting
        while index < 0 {
            index = days.count + index
        }
        return days[index]
    }
    
    init() {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        fullDayName = dateFormatter.string(from: date)
    }
}

struct DaysLetters: View {
    var isComplication = false
    let day = TodaysDate()
    var body: some View {
        HStack {
            ForEach((0...7).reversed(), id: \.self) {
                Text(String(day.day(subtracting: $0).first ?? "?"))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .font((isComplication || GlobalEnvironment.isWatch) ? .system(size: 8) : .caption)
            }
        }
    }
}

struct BarViewModel {
    var isNegative: Bool
    var activeCaloriesBurned: Double
    var restingCaloriesBurned: Double
    var caloriesConsumed: Double
}

struct Bar: View {
    var cornerRadius: CGFloat = 7.0
    var color: Color = .green
    var height: CGFloat = 100.0
    var activeCalories: Double = 1
    var totalDeficit: Double = 1
    var isPositive: Bool = true
    var indexAndPercent: BarChart.IndexAndPercent? = nil
    let gradientColors: [Color] = [.orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .yellow]
    
    var body: some View {
        if color == .yellow {
            let gradientPercentage = CGFloat(activeCalories / totalDeficit)
            
            RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LinearGradient(colors: gradientColors,
                                 startPoint: UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: 0),
                                 endPoint: UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y * gradientPercentage)))
            .frame(height: height, alignment: .bottom)
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(height: height, alignment: .bottom)
                .foregroundColor(color)
        }
    }
}

struct CalorieTexts: View {
    @EnvironmentObject var healthData: HealthData
    
    var body: some View {
        HStack {
            ForEach((0...7).reversed(), id: \.self) {
                Text(String(Int(healthData.deficitsThisWeek[$0] ?? 0.0)))
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct BarChart: View {
    @EnvironmentObject var healthData: HealthData
    var cornerRadius: CGFloat = 7.0
    var showCalories: Bool = true
    var isComplication = false
    
    var body: some View {
        if !isComplication {
            VStack {
                if showCalories {
                    CalorieTexts()
                        .padding([.trailing], 50)
                        .padding([.leading], 10)
                }
                
                BarsAndLines(cornerRadius: cornerRadius)
                    .environmentObject(healthData)
                    .frame(maxHeight: .infinity)
                
                DaysLetters()
                    .padding([.trailing], 50)
                    .padding([.leading], 10)
                
            }
            .padding([.leading, .bottom, .top])
        } else {
            VStack {
                if showCalories {
                    CalorieTexts()
                        .padding([.trailing], 50)
                        .padding([.leading], 10)
                }
                
                BarsAndLines(cornerRadius: cornerRadius, isComplication: isComplication)
                    .environmentObject(healthData)
                    .frame(maxHeight: .infinity)
                
                DaysLetters(isComplication: isComplication)
                    .padding([.trailing], 50)
                    .padding([.leading], 10)
            }
        }
    }
    
    struct Overlay: View {
        var viewModel: OverlayViewModel?
        
        var body: some View {
            let activeCalorieString = "\(Int(viewModel?.activeCalories ?? 0))"
            let consumedCalorieString = "\(Int(viewModel?.consumedCalories ?? 0))"
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Active")
                    Text(activeCalorieString)
                        .font(.title)
                }.padding(1)
                VStack(alignment: .leading) {
                    Text("Consumed")

                    Text(consumedCalorieString)
                        .font(.title)
                }.padding(1)
            }
            .background(.white)
            .cornerRadius(5)
        }
    }
    
    struct OverlayViewModel {
        var activeCalories: Double = 0
        var restingCalories: Double = 0
        var consumedCalories: Double = 0
    }
    
    struct Sheet: View {
        var body: some View{
            Text("Test")
        }
    }
    
    struct BarsAndLines: View {
        @EnvironmentObject var healthData: HealthData
        var cornerRadius: CGFloat = 7.0
        @State var isDisplayingOverlay = false
        @State var overlayViewModel = OverlayViewModel(activeCalories: 0, restingCalories: 0, consumedCalories: 0)

        @State var barViewModel = BarViewModel()
        var isComplication = false
        
        var body: some View {
            let results = BarChart.deficitsToPercents(daysAndDeficits: healthData.deficitsThisWeek)
            let percents = results.0
            let top = results.1
            let horizontalRatio = top / 1000
            let avgRatio = top / (healthData.averageDeficitThisWeek == 0 ? 1 : healthData.averageDeficitThisWeek)
                        
//            let tmrwRatio = top / (healthData.projectedAverageWeeklyDeficitForTomorrow == 0 ? 1 : healthData.projectedAverageWeeklyDeficitForTomorrow)
            
            GeometryReader { geometry in
                ZStack {
                    HStack(alignment: .bottom) {
                        ForEach(percents ?? [], id: \.index) { indexAndPercent in
                            let height = geometry.size.height * (indexAndPercent.percent >= 0 ? indexAndPercent.percent : (indexAndPercent.percent * -1))
                            let isToday = indexAndPercent.index == percents!.count - 1
                            let isPositive = indexAndPercent.percent >= 0
                            let color: Color = isPositive ? (isToday ? .yellow : .yellow) : .red
                            
                            let day = healthData.individualStatistics[7 - indexAndPercent.index] ?? Day()
                            let activeCalories = day.activeCalories
                            let totalDeficit = day.deficit
//                            let consumed = day.consumedCalories
                            
                            Bar(cornerRadius: cornerRadius, color: color, height: height, activeCalories: activeCalories, totalDeficit: totalDeficit)
                                .opacity(isToday ? 0.5 : 1)
                                .onTapGesture {
#if !os(watchOS)
                                    let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                                    impactHeavy.impactOccurred()
#endif
                                    isDisplayingOverlay = true
                                    barViewModel.barClicked = day
//                                    overlayViewModel = OverlayViewModel(activeCalories: activeCalories, restingCalories: totalDeficit - activeCalories, consumedCalories: consumed)
                                }
                                .sheet(isPresented: $isDisplayingOverlay, onDismiss: {
                                    self.isDisplayingOverlay = false
                                }) {
                                    BarView()
                                        .environmentObject(barViewModel)
                                }
                        }
                    }.padding(.trailing, 50)
                        .padding([.leading], 10)
                    
                    if horizontalRatio != 0 {
                        let heightOffset = geometry.size.height - (geometry.size.height / CGFloat(horizontalRatio))
                        Rectangle()
                            .size(width: geometry.size.width - 40, height: isComplication ? 2.5 : 5.0)
                            .offset(x: 0.0, y: heightOffset - 2.5)
                            .foregroundColor(.white)
                            .opacity(0.5)
                        Text("1000")
                            .font(.system(size: 8))
                            .frame(maxWidth: 50)
                            .position(x: geometry.size.width - 20, y: 0.0)
                            .offset(x: 0.0, y: heightOffset)
                            .foregroundColor(.white)
                    }
                    if avgRatio != 0 {
                        let heightOffset = geometry.size.height - (geometry.size.height / CGFloat(avgRatio))
                        Rectangle()
                            .size(width: geometry.size.width - 40, height: 2.5)
                            .offset(x: 0.0, y: heightOffset - 1.25)
                            .foregroundColor(.yellow)
                            .opacity(0.5)
                        Text("Avg \n\(String(Int(healthData.averageDeficitThisWeek)))")
                            .font(.system(size: 8))
                            .frame(maxWidth: 50)
                            .position(x: geometry.size.width - 20, y: 0.0)
                            .offset(x: 0.0, y: heightOffset)
                            .foregroundColor(.yellow)
                    }
                }
            }.onTapGesture {
                print("lol")
            }
        }
    }
    
    
    class BarViewModel: ObservableObject {
        @Published var barClicked: Day = Day(deficit: 0, activeCalories: 0, consumedCalories: 0)
    }
    
    struct BarView: View {
        @EnvironmentObject var barViewModel: BarViewModel
        var body: some View {
            ZStack {
                Color.myGray.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Active")
                    .foregroundColor(.white)
                Text(String(Int(barViewModel.barClicked.activeCalories)))
                    .font(.title)
                    .foregroundColor(.white)
                Text("Consumed")
                    .foregroundColor(.white)
                Text(String(Int(barViewModel.barClicked.consumedCalories)))
                    .font(.title)
                    .foregroundColor(.white)
                Text("Deficit")
                    .foregroundColor(.white)
                Text(String(Int(barViewModel.barClicked.deficit)))
                    .font(.title)
                    .foregroundColor(.white)

            }
            }
        }
    }
    
    struct IndexAndPercent {
        var index: Int
        var percent: CGFloat
    }
    
    // Here, I need to know the date of each, so that I can get the active calories burned and
    static func deficitsToPercents(daysAndDeficits: [Int:Double]) -> ([IndexAndPercent]?, Double) {
        // I think I'm ordering these because they come in backwards by default?
        var orderedDeficits: [Double] = []
        if daysAndDeficits.count > 0 {
            for i in stride(from: daysAndDeficits.count-1, through: 0, by: -1) {
                orderedDeficits.append(daysAndDeficits[i] ?? 0)
            }
        }
        // Get the top deficit, and account for if its a surplus
        guard var topDeficit = orderedDeficits.max() else { return (nil, 0) }
        topDeficit = max(orderedDeficits.max() ?? 0, abs(orderedDeficits.min() ?? 0))
        topDeficit = topDeficit >= 1000 ? topDeficit : 1000
        // Size the rest in relation to the top deficit
        let percents = orderedDeficits.map { CGFloat($0 / topDeficit) }
        var indicesAndPercents: [IndexAndPercent]? = []
        for i in stride(from: 0, to: percents.count, by: 1) {
            indicesAndPercents?.append(IndexAndPercent(index: i, percent: percents[i]))
        }
        return (indicesAndPercents, topDeficit)
    }
    
}

struct BarChart_Previews: PreviewProvider {
    static var previews: some View {
        BarChart()
            .environmentObject(HealthData(environment: .debug))
            .background(Color.myGray)
        
    }
}
