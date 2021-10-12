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
    let day = TodaysDate()
    var body: some View {
        HStack {
            ForEach((0...7).reversed(), id: \.self) {
                Text(String(day.day(subtracting: $0).first ?? "?"))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .font(.caption)
                }

        }
    }
}

struct Bar: View {
    var cornerRadius: CGFloat = 7.0
    var color: Color = .yellow
    var height: CGFloat = 100.0
    var body: some View {
        
        RoundedRectangle(cornerRadius: cornerRadius)
            .frame(height: height, alignment: .bottom)
            .foregroundColor(color)
        
//            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
//                print(value.location)
//            })
//            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onEnded { value in
//                print(value.location)
//            })
//            .onLongPressGesture(minimumDuration: 0, maximumDistance: 0, pressing: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>, perform: <#T##() -> Void#>)
    
    }
}

struct CalorieTexts: View {
    @EnvironmentObject var healthKit: MyHealthKit
    
    var body: some View {
        HStack {
            ForEach((0...7).reversed(), id: \.self) {
                Text(String(Int(healthKit.dailyDeficits[$0] ?? 0.0)))
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct BarChart: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var cornerRadius: CGFloat = 7.0
    
    var body: some View {
        VStack {
            CalorieTexts()
                .padding([.trailing], 50)
                .padding([.leading], 10)
            
            BarsAndLines(cornerRadius: cornerRadius).environmentObject(healthKit)
                .frame(maxHeight: .infinity)
            
            DaysLetters()
                .padding([.trailing], 50)
                .padding([.leading], 10)

        }
        .padding([.leading, .bottom, .top])
    }
    
    struct BarsAndLines: View {
        @EnvironmentObject var healthKit: MyHealthKit
        var cornerRadius: CGFloat = 7.0
        
        var body: some View {
            let results = BarChart.deficitsToPercents(daysAndDeficits: healthKit.dailyDeficits)
            let percents = results.0
            let top = results.1
            let horizontalRatio = top / 1000
            let avgRatio = top / (healthKit.averageDeficitThisWeek == 0 ? 1 : healthKit.averageDeficitThisWeek)
            let tmrwRatio = top / (healthKit.projectedAverageWeeklyDeficitForTomorrow == 0 ? 1 : healthKit.projectedAverageWeeklyDeficitForTomorrow)
            
            GeometryReader { geometry in
                ZStack {
                    HStack(alignment: .bottom) {
                        ForEach(percents ?? [], id: \.index) { indexAndPercent in
                            let height = geometry.size.height * (indexAndPercent.percent >= 0 ? indexAndPercent.percent : (indexAndPercent.percent * -1))
                            let isToday = indexAndPercent.index == percents!.count - 1
                            let isPositive = indexAndPercent.percent >= 0
                            let color: Color = isPositive ? (isToday ? .yellow : .yellow) : .red
                            
                            Bar(cornerRadius: cornerRadius, color: color, height: height)
                                .opacity(isToday ? 0.5 : 1)
                        }
                    }.padding(.trailing, 50)
                    .padding([.leading], 10)

                    
                    if horizontalRatio != 0 {
                        let heightOffset = geometry.size.height - (geometry.size.height / CGFloat(horizontalRatio))
                        Rectangle()
                            .size(width: geometry.size.width - 40, height: 5.0)
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
                        Text("Avg \n\(String(Int(healthKit.averageDeficitThisWeek)))")
//                            .font(.caption)
                            .font(.system(size: 8))
                            .frame(maxWidth: 50)
                            .position(x: geometry.size.width - 20, y: 0.0)
                            .offset(x: 0.0, y: heightOffset)
                            .foregroundColor(.yellow)
                    }
//                    if tmrwRatio != 0 {
//                        let heightOffset = geometry.size.height - (geometry.size.height / CGFloat(tmrwRatio))
//                        Rectangle()
//                            .size(width: geometry.size.width - 40, height: 5.0)
//                            .offset(x: 0.0, y: heightOffset - 2.5)
//                            .foregroundColor(.orange)
//                            .opacity(0.5)
//                        Text("Tmrw \n\(String(Int(healthKit.projectedAverageWeeklyDeficitForTomorrow)))")
////                            .font(.caption)
//                            .font(.system(size: 8))
//                            .frame(maxWidth: 50)
//                            .position(x: geometry.size.width - 20, y: 0.0)
//                            .offset(x: 0.0, y: heightOffset)
//                            .foregroundColor(.orange)
//                    }
                }
            }
//            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
//                print(value.location)
//            })
        }
    }
    
//    struct NegativeBars: View {
//        @EnvironmentObject var healthKit: MyHealthKit
//        var cornerRadius: CGFloat = 7.0
//
//        var body: some View {
//            let results = BarChart.deficitsToPercents(daysAndDeficits: healthKit.dailyDeficits)
//            let percents = results.0
//            let top = results.1
//            let horizontalRatio = top / 1000
//
//            GeometryReader { geometry in
//                ZStack {
//                    HStack(alignment: .bottom) {
//                        ForEach(percents ?? [], id: \.index) { indexAndPercent in
//                            let height = geometry.size.height * (indexAndPercent.percent >= 0 ? indexAndPercent.percent : (indexAndPercent.percent * -1))
//                            let isToday = indexAndPercent.index == percents!.count - 1
//                            let isPositive = indexAndPercent.percent >= 0
//                            let color: Color = isPositive ? (isToday ? .blue : .yellow) : .red
//                            if !isPositive {
//                            Bar(cornerRadius: cornerRadius, color: color, height: height).opacity(1)
//                            } else {
//                                Bar(cornerRadius: cornerRadius, color: color, height: 0).opacity(0)
//                            }
//                        }
//                    }.padding(.trailing, 50)
//                }
//            }
//        }
//    }
    
    struct IndexAndPercent {
        var index: Int
        var percent: CGFloat
    }
    
    static func deficitsToPercents(daysAndDeficits: [Int:Float]) -> ([IndexAndPercent]?, Float) {
        var orderedDeficits: [Float] = []
        if daysAndDeficits.count > 0 {
            for i in stride(from: daysAndDeficits.count-1, through: 0, by: -1) {
                orderedDeficits.append(daysAndDeficits[i] ?? 0)
            }
        }
        guard var topDeficit = orderedDeficits.max() else { return (nil, 0) }
        topDeficit = max(orderedDeficits.max() ?? 0, abs(orderedDeficits.min() ?? 0))
        topDeficit = topDeficit >= 1000 ? topDeficit : 1000
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
            .environmentObject(MyHealthKit(environment: .debug))
            .background(Color.myGray)

    }
}
