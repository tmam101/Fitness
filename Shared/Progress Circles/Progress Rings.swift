//
//  ProgressCircle.swift
//  Trello
//
//  Created by Thomas Goss on 6/8/20.
//  Copyright © 2020 Thomas Goss. All rights reserved.
//

import Foundation
import SwiftUI

struct MonthlyAverageWeightLossCircle: View {
    @EnvironmentObject var fitness: FitnessCalculations
    var lineWidth: CGFloat = 10.0
    var color = Color.green1
    
    var body: some View {
        let average = CGFloat(fitness.averageWeightLostPerWeekThisMonth / 2)
        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: average, opacity: 1, lineWidth: lineWidth)

    }
}
struct WeeklyAverageDeficitCircle: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var lineWidth: CGFloat = 10.0
    var color = Color.yellow
    var body: some View {
        let deficit = healthKit.averageDeficitThisWeek
        let projectedTomorrow = healthKit.projectedAverageWeeklyDeficitForTomorrow
        let percent: CGFloat = CGFloat(deficit / 1000)
        let projected: CGFloat = CGFloat(projectedTomorrow / 1000)
        
        BackgroundCircle(color: color, lineWidth: lineWidth)
        if projected >= percent {
            GenericCircle(color: color, starting: 0.0, ending: projected, opacity: 0.4, lineWidth: lineWidth)
        }
        GenericCircle(color: color, starting: 0.0, ending: percent, opacity: 1, lineWidth: lineWidth)
        if projected < percent {
            GenericCircle(color: .red, starting: projected, ending: percent, opacity: 1, lineWidth: lineWidth)
        }
    }
}

struct DailyDeficitCircle: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var lineWidth: CGFloat = 10
    var color = Color.blue
    
    var body: some View {
        let deficit = healthKit.deficitToday
        let idealDeficit = healthKit.deficitToGetCorrectDeficit
        let percent: CGFloat = CGFloat((deficit / (idealDeficit == 0 ? 1 : idealDeficit)))
        
        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: percent, opacity: 1, lineWidth: lineWidth)
    }
}

struct TotalWeightLossCircle: View {
    @EnvironmentObject var fitness: FitnessCalculations
    var lineWidth: CGFloat = 10.0
    var color = Color.green2
    
    var body: some View {
        VStack {
            ZStack {
                // Background
                BackgroundCircle(color: color, lineWidth: lineWidth)
                
                // Progress Toward Date
//                GenericCircle(color: color, starting: 0.0, ending: CGFloat(min(fitness.progressToDate, 1.0)), opacity: 0.4, lineWidth: lineWidth)
                
                // Progress
                GenericCircle(color: color, starting: 0.0, ending: CGFloat(min(fitness.progressToWeight, 1.0)), opacity: 1, lineWidth: lineWidth)
                
//                if fitness.progressToWeight > fitness.progressToDate {
//                    Circle()
//                        .trim(from: CGFloat(fitness.progressToDate - 0.002), to: CGFloat(fitness.progressToDate + 0.002))
//                        .stroke(lineWidth: lineWidth)
//                        .opacity(1)
//                        .foregroundColor(Color.white)
//                        .rotationEffect(Angle(degrees: 270.0))
//                        .animation(.linear)
//                }
            }
        }
    }
}

struct AverageTotalDeficitCircle: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var lineWidth: CGFloat = 10.0
    var color = Color.orange

    var body: some View {
        let avg = healthKit.averageDeficitSinceStart
        let projectedTomorrow = healthKit.projectedAverageTotalDeficitForTomorrow
        let percent = CGFloat(avg / 1000)
        let projected: CGFloat = CGFloat(projectedTomorrow / 1000)

        BackgroundCircle(color: color, lineWidth: lineWidth)
        if projected >= percent {
            GenericCircle(color: color, starting: 0, ending: projected, opacity: 0.4, lineWidth: lineWidth)
        }
        GenericCircle(color: color, starting: 0, ending: percent, opacity: 1, lineWidth: lineWidth)
        if projected < percent {
            GenericCircle(color: .red, starting: projected, ending: percent, opacity: 1, lineWidth: lineWidth)
        }
    }
}

struct WeightLossAccuracyCircle: View {
    @EnvironmentObject var healthKit: MyHealthKit
    @EnvironmentObject var fitness: FitnessCalculations
    var lineWidth: CGFloat = 10.0
    var color = Color.green3
    
    var body: some View {
        let averageDeficit = healthKit.averageDeficitSinceStart / 1000
        let averageWeightLoss = fitness.averageWeightLostPerWeek / 2
        let ratio = CGFloat(averageWeightLoss / averageDeficit).corrected()
        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: ratio, opacity: 1, lineWidth: lineWidth)
    }
}

struct AverageTotalWeightLossCircle: View {
    @EnvironmentObject var healthKit: MyHealthKit
    @EnvironmentObject var fitness: FitnessCalculations
    var lineWidth: CGFloat = 10.0
    var color = Color.green1
    
    var body: some View {
        let averageWeightLoss = CGFloat(fitness.averageWeightLostPerWeek / 2)
        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: averageWeightLoss, opacity: 1, lineWidth: lineWidth)
    }
}

//struct AverageCircle: View {
//    @EnvironmentObject var healthKit: MyHealthKit
//    var lineWidth: CGFloat = 10.0
//
//    var body: some View {
////        let netAverage = healthKit.netAverage ?? 0
////        let percent: Double = Double(netAverage / 1500) * 100
//        let deficit = healthKit.averageDeficit
//        let percent: Double = Double(deficit / 1000) * 100
//        let backgroundColor = Color.yellow.opacity(0.1)
//        PercentageRing(ringWidth: lineWidth, percent: percent, backgroundColor: backgroundColor, foregroundColors: [Color.yellow, Color.red])
//    }
//}

//class CircleLayers {
//    var layers: [CircleLayer] = []
//
//    init(layers: [CircleLayer]) {
//        self.layers = layers
//    }
//}
//
//class CircleLayer {
//    let id = UUID()
//    var starting: CGFloat = 0.0
//    var percent: CGFloat = 0
//    var color: Color = .red
//    var opacity: Double = 0
//
//    init(starting: CGFloat, percent: CGFloat, color: Color, opacity: Double) {
//        self.starting = starting
//        self.percent = percent
//        self.color = color
//        self.opacity = opacity
//    }
//
//    init(percent: CGFloat, color: Color, opacity: Double) {
//        self.percent = percent
//        self.color = color
//        self.opacity = opacity
//    }
//}

//struct GenericCircle: View {
//    @EnvironmentObject var healthKit: MyHealthKit
//    var lineWidth: CGFloat = 10.0
//    var layers: CircleLayers
//
//    var body: some View {
//        // Background
////        ZStack {
//        Circle()
//            .stroke(lineWidth: lineWidth)
//            .opacity(0.1)
//            .foregroundColor(layers.layers.first?.color ?? .yellow)
//            ForEach(layers.layers, id: \.id) { layer in
////            let layer = layers.layers[index]
//                withAnimation {
//                    Circle()
//                        .trim(from: layer.starting, to: layer.percent)
//                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
//                        .foregroundColor(layer.color.opacity(layer.opacity))
//                        .rotationEffect(Angle(degrees: 270.0))
//                        .animation(.easeOut(duration: 1))
//                }
////            Circle()
////                .trim(from: layer.starting, to: layer.percent)
////                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
////                .foregroundColor(layer.color.opacity(layer.opacity))
////                .rotationEffect(Angle(degrees: 270.0))
////                .animation(.easeOut(duration: 1))
//            }.transition(.slide)
////        }
//    }
//}

//struct AverageCircle2: View {
//    @EnvironmentObject var healthKit: MyHealthKit
//    var lineWidth: CGFloat = 10.0
//
//    func setup() -> [CircleLayer] {
//        var layers: [CircleLayer] = []
//        var deficit = healthKit.averageDeficitThisWeek
//        var projectedTomorrow = healthKit.projectedAverageWeeklyDeficitForTomorrow
//        var percent = CGFloat(deficit / 1000)
//        var projected = CGFloat(projectedTomorrow / 1000)
//        if projected >= percent {
//            layers.append(CircleLayer(percent: projected, color: .yellow, opacity: 0.4))
//        }
//        layers.append(CircleLayer(percent: percent, color: .yellow, opacity: 1))
//        if projected < percent {
//            layers.append(CircleLayer(starting: projected, percent: percent, color: .red, opacity: 1))
//        }
//        return layers
//    }
//
//    var body: some View {
//        GenericCircle(layers: CircleLayers(layers: setup()))
//            .environmentObject(healthKit)
//    }
//}

//struct AverageCircle: View {
//    @EnvironmentObject var healthKit: MyHealthKit
//    var lineWidth: CGFloat = 10.0
//
//    var body: some View {
//        let deficit = healthKit.averageDeficitThisWeek
//        let projectedTomorrow = healthKit.projectedAverageWeeklyDeficitForTomorrow
//        let percent: CGFloat = CGFloat(deficit / 1000)
//        let projected: CGFloat = CGFloat(projectedTomorrow / 1000)
//        Circle()
//            .stroke(lineWidth: lineWidth)
//            .opacity(0.1)
//            .foregroundColor(.yellow)
//        if projected >= percent {
//        Circle()
//            .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: projected)
//            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
//            .foregroundColor(Color.yellow.opacity(0.4))
//            .rotationEffect(Angle(degrees: 270.0))
//            .animation(.easeOut(duration: 1))
//        }
//        Circle()
//            .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: percent)
//            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
//            .foregroundColor(.yellow)
//            .rotationEffect(Angle(degrees: 270.0))
//            .animation(.easeOut(duration: 1))
//        if projected < percent {
//            Circle()
//                .trim(from: projected, to: percent)
//                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
////                .opacity(0.8)
//                .foregroundColor(Color.red)
//                .rotationEffect(Angle(degrees: 270.0))
//                .animation(.easeOut(duration: 10))
//        }
//    }
//}

//struct CalorieCircle: View {
//    @EnvironmentObject var healthKit: MyHealthKit
//    var lineWidth: CGFloat = 10.0
//
//    var body: some View {
////        let eaten = healthKit.eaten ?? 0
////        let netToEat = (healthKit.netToEat ?? 1) == 0 ? 1 : (healthKit.netToEat ?? 1)
////        let percent: Double = Double(eaten / netToEat) * 100
//        let deficit = healthKit.deficitToday
//        let idealDeficit = healthKit.deficitToGetCorrectDeficit
//        let percent: Double = Double((deficit / idealDeficit)) * 100
//        PercentageRing(ringWidth: lineWidth, percent: percent, backgroundColor: Color.blue.opacity(0.1), foregroundColors: [Color.blue, Color.red])
//    }
//
//}

//struct ProgressCircle_Previews: PreviewProvider {
//    struct ProgressCirclePreview: View {
//        var body: some View {
//            VStack {
//                TotalWeightLossCircle().environmentObject(FitnessCalculations())
//                    .frame(width: 150.0, height: 150.0)
//                    .padding(40.0)
//            }
//        }
//    }
//
//    static var previews: some View {
//        ProgressCirclePreview()
//    }
//}
