//
//  BarChart.swift
//  Fitness
//
//  Created by Thomas Goss on 4/8/21.
//

import SwiftUI

struct Bar: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 7.0)
//        Rectangle()
            .foregroundColor(.yellow)
    }
}

struct BarChart: View {
    @EnvironmentObject var healthKit: MyHealthKit
//    @State var percents: [CGFloat] = [0.5, 1, 0.7]
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom) {
                ForEach(BarChart.deficitsToPercents(daysAndDeficits: healthKit.dailyDeficits) ?? [], id: \.self) { percent in
                Bar()
                    .frame(height: geometry.size.height * (percent < 0 ? 0 : percent), alignment: .bottom)
                }
            }
        }.padding()
    }
    
    static func deficitsToPercents(daysAndDeficits: [Int:Float]) -> [CGFloat]? {
//        let deficits = [700, 300, 400, 500, 1200, 500]
        var orderedDeficits: [Float] = []
        for i in 0..<daysAndDeficits.count {
            orderedDeficits.append(daysAndDeficits[i] ?? 0)
        }
        guard let topDeficit = orderedDeficits.max() else { return nil }
        let percents = orderedDeficits.map { CGFloat($0 / topDeficit) }
        return percents
    }

}

struct BarChart_Previews: PreviewProvider {
    static var previews: some View {
        BarChart()
            .environmentObject(MyHealthKit(environment: .debug))

    }
}
