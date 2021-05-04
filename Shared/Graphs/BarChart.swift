//
//  BarChart.swift
//  Fitness
//
//  Created by Thomas Goss on 4/8/21.
//

import SwiftUI

struct Bar: View {
    var color: Color = .yellow
    var height: CGFloat = 100.0
    var body: some View {
        
        RoundedRectangle(cornerRadius: 7.0)
            .frame(height: height, alignment: .bottom)
            .foregroundColor(color)
    }
}

struct BarChart: View {
    @EnvironmentObject var healthKit: MyHealthKit
    
    var body: some View {
        let results = BarChart.deficitsToPercents(daysAndDeficits: healthKit.dailyDeficits)
        let percents = results.0
        let top = results.1
        let horizontalRatio = top / 1000
        
        GeometryReader { geometry in
            ZStack {
                HStack(alignment: .bottom) {
                    ForEach(percents ?? [], id: \.index) { indexAndPercent in
                        let height = geometry.size.height * (indexAndPercent.percent >= 0 ? indexAndPercent.percent : (indexAndPercent.percent * -1))
                        let isToday = indexAndPercent.index == percents!.count - 1
                        let isPositive = indexAndPercent.percent >= 0
                        let color: Color = isPositive ? (isToday ? .blue : .yellow) : .red
                        
                        Bar(color: color, height: height)
                    }
                }
                if horizontalRatio != 0 {
                    let heightOffset = geometry.size.height - (geometry.size.height / CGFloat(horizontalRatio))
                    Rectangle()
                        .size(width: geometry.size.width, height: 2.0)
                        .offset(x: 0.0, y: heightOffset)
                        .foregroundColor(.gray)
                }
            }
        }.padding()
    }
    
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
