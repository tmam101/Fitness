//
//  ProgressCircle.swift
//  Trello
//
//  Created by Thomas Goss on 6/8/20.
//  Copyright © 2020 Thomas Goss. All rights reserved.
//

import Foundation
import SwiftUI

extension Double {
    func toRadians() -> Double {
        return self * Double.pi / 180
    }
    func toCGFloat() -> CGFloat {
        return CGFloat(self)
    }
}

// https://liquidcoder.com/swiftui-ring-animation/
struct RingShape: Shape {
    // Helper function to convert percent values to angles in degrees
    static func percentToAngle(percent: Double, startAngle: Double) -> Double {
        (percent / 100 * 360) + startAngle
    }
    private var percent: Double
    private var startAngle: Double
    private let drawnClockwise: Bool
    
    // This allows animations to run smoothly for percent values
    var animatableData: Double {
        get {
            return percent
        }
        set {
            percent = newValue
        }
    }
    
    init(percent: Double = 100, startAngle: Double = -90, drawnClockwise: Bool = false) {
        self.percent = percent
        self.startAngle = startAngle
        self.drawnClockwise = drawnClockwise
    }
    
    // This draws a simple arc from the start angle to the end angle
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let radius = min(width, height) / 2
        let center = CGPoint(x: width / 2, y: height / 2)
        let endAngle = Angle(degrees: RingShape.percentToAngle(percent: self.percent, startAngle: self.startAngle))
        return Path { path in
            path.addArc(center: center, radius: radius, startAngle: Angle(degrees: startAngle), endAngle: endAngle, clockwise: drawnClockwise)
        }
    }
}

struct PercentageRing: View {
    
    private static let ShadowColor: Color = Color.black.opacity(0.2)
    private static let ShadowRadius: CGFloat = 5
    private static let ShadowOffsetMultiplier: CGFloat = ShadowRadius + 2
    
    private let ringWidth: CGFloat
    private let percent: Double
    private let backgroundColor: Color
    private let foregroundColors: [Color]
    private let startAngle: Double = -90
    private var gradientStartAngle: Double {
        self.percent >= 100 ? relativePercentageAngle - 360 : startAngle
    }
    private var absolutePercentageAngle: Double {
        RingShape.percentToAngle(percent: self.percent, startAngle: 0)
    }
    private var relativePercentageAngle: Double {
        // Take into account the startAngle
        absolutePercentageAngle + startAngle
    }
    private var firstGradientColor: Color {
        self.foregroundColors.first ?? .black
    }
    private var lastGradientColor: Color {
        self.foregroundColors.last ?? .black
    }
    private var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: self.foregroundColors),
            center: .center,
            startAngle: Angle(degrees: self.gradientStartAngle),
            endAngle: Angle(degrees: relativePercentageAngle)
        )
    }
    
    init(ringWidth: CGFloat, percent: Double, backgroundColor: Color, foregroundColors: [Color]) {
        self.ringWidth = ringWidth
        self.percent = min(percent, 200)
        self.backgroundColor = backgroundColor
        self.foregroundColors = foregroundColors
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background for the ring
                RingShape()
                    .stroke(style: StrokeStyle(lineWidth: self.ringWidth))
                    .fill(self.backgroundColor)
                // Foreground
                if self.percent > 100 {
                RingShape(percent: self.percent, startAngle: self.startAngle)
                    .stroke(style: StrokeStyle(lineWidth: self.ringWidth, lineCap: .round))
                    .fill(self.ringGradient)
                    .onAppear() {
                        withAnimation(Animation.easeIn(duration: 2)) {
                            
                        }
                    }
                } else {
                    RingShape(percent: self.percent, startAngle: self.startAngle)
                        .stroke(style: StrokeStyle(lineWidth: self.ringWidth, lineCap: .round))
                        .fill(foregroundColors.first ?? Color.yellow)
                }
                // End of ring with drop shadow
                if self.getShowShadow(frame: geometry.size) {
                    Circle()
//                        .fill(self.ringGradient)
                        .fill((self.percent > 100 ? self.lastGradientColor : self.foregroundColors.last) ?? Color.yellow)
                        .frame(width: self.ringWidth, height: self.ringWidth, alignment: .center)
                        .offset(x: self.getEndCircleLocation(frame: geometry.size).0,
                                y: self.getEndCircleLocation(frame: geometry.size).1)
                        .shadow(color: PercentageRing.ShadowColor,
                                radius: PercentageRing.ShadowRadius,
                                x: self.getEndCircleShadowOffset().0,
                                y: self.getEndCircleShadowOffset().1)
                }
            }
        }
        // Padding to ensure that the entire ring fits within the view size allocated
//        .padding(self.ringWidth / 2)
    }
    
    private func getEndCircleLocation(frame: CGSize) -> (CGFloat, CGFloat) {
        // Get angle of the end circle with respect to the start angle
        let angleOfEndInRadians: Double = relativePercentageAngle.toRadians()
        let offsetRadius = min(frame.width, frame.height) / 2
        return (offsetRadius * cos(angleOfEndInRadians).toCGFloat(), offsetRadius * sin(angleOfEndInRadians).toCGFloat())
    }
    
    private func getEndCircleShadowOffset() -> (CGFloat, CGFloat) {
        let angleForOffset = absolutePercentageAngle + (self.startAngle + 90)
        let angleForOffsetInRadians = angleForOffset.toRadians()
        let relativeXOffset = cos(angleForOffsetInRadians)
        let relativeYOffset = sin(angleForOffsetInRadians)
        let xOffset = relativeXOffset.toCGFloat() * PercentageRing.ShadowOffsetMultiplier
        let yOffset = relativeYOffset.toCGFloat() * PercentageRing.ShadowOffsetMultiplier
        return (xOffset, yOffset)
    }
    
    private func getShowShadow(frame: CGSize) -> Bool {
        let circleRadius = min(frame.width, frame.height) / 2
        let remainingAngleInRadians = (360 - absolutePercentageAngle).toRadians().toCGFloat()
        if self.percent >= 100 {
            return true
        } else if circleRadius * remainingAngleInRadians <= self.ringWidth {
            return true
        }
        return false
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

struct AverageAllTimeCircle: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var lineWidth: CGFloat = 10.0

    var body: some View {
        let avg = healthKit.averageDeficitSinceStart
        let projectedTomorrow = healthKit.projectedAverageTotalDeficitForTomorrow
        let percent = CGFloat(avg / 1000)
        let projected: CGFloat = CGFloat(projectedTomorrow / 1000)
        Circle()
            .stroke(lineWidth: lineWidth)
            .opacity(0.1)
            .foregroundColor(.orange)
        if projected >= percent {
        Circle()
            .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: projected)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .foregroundColor(Color.orange.opacity(0.4))
            .rotationEffect(Angle(degrees: 270.0))
            .animation(.easeOut(duration: 1))
        }
        Circle()
            .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: percent)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .foregroundColor(.orange)
            .rotationEffect(Angle(degrees: 270.0))
            .animation(.easeOut(duration: 1))
        if projected < percent {
            Circle()
                .trim(from: projected, to: percent)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
//                .opacity(0.8)
                .foregroundColor(Color.red)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(Animation.easeOut(duration: 1).delay(1000))
        }
    }
}

struct AverageCircle: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var lineWidth: CGFloat = 10.0

    var body: some View {
        let deficit = healthKit.averageDeficitThisWeek
        let projectedTomorrow = healthKit.projectedAverageWeeklyDeficitForTomorrow
        let percent: CGFloat = CGFloat(deficit / 1000)
        let projected: CGFloat = CGFloat(projectedTomorrow / 1000)
        Circle()
            .stroke(lineWidth: lineWidth)
            .opacity(0.1)
            .foregroundColor(.yellow)
        if projected >= percent {
        Circle()
            .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: projected)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .foregroundColor(Color.yellow.opacity(0.4))
            .rotationEffect(Angle(degrees: 270.0))
            .animation(.easeOut(duration: 1))
        }
        Circle()
            .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: percent)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .foregroundColor(.yellow)
            .rotationEffect(Angle(degrees: 270.0))
            .animation(.easeOut(duration: 1))
        if projected < percent {
            Circle()
                .trim(from: projected, to: percent)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
//                .opacity(0.8)
                .foregroundColor(Color.red)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.easeOut(duration: 10))
        }
    }
}

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

struct CalorieCircle: View {
    @EnvironmentObject var healthKit: MyHealthKit
//    @State var burned: Float = 300
//    @State var eaten: Float = 1500
    var lineWidth: CGFloat = 10

    var body: some View {
        let deficit = healthKit.deficitToday
        let idealDeficit = healthKit.deficitToGetCorrectDeficit
        let percent: CGFloat = CGFloat((deficit / (idealDeficit == 0 ? 1 : idealDeficit)))
        Circle()
            .stroke(lineWidth: lineWidth)
            .opacity(0.1)
            .foregroundColor(.blue)
        Circle()
            .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: percent)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .foregroundColor(.blue)
//            .foregroundColor(((healthKit.eaten ?? 0) / ((healthKit.burned ?? 0) + 1500)) > 1 ? .red : .blue)
            .rotationEffect(Angle(degrees: 270.0))
            .animation(.easeOut(duration: 1))
//        Circle()
//            .trim(from: CGFloat((healthKit.progress ?? 0.002) - 0.002), to: CGFloat((healthKit.progress ?? 0) + 0.002))
//            .stroke(lineWidth: lineWidth)
//            .opacity(1)
//            .foregroundColor(Color.white)
//            .rotationEffect(Angle(degrees: 270.0))
//            .animation(.linear)
    }
}

struct ProgressCircle: View {
//    @Binding var progress: Float
//    @Binding var progressTowardDate: Float
//    @Binding var successPercentage: Float
    @EnvironmentObject var fitness: FitnessCalculations
    var lineWidth: CGFloat = 10.0
    
    var body: some View {
        VStack {
            ZStack {
                // Background
                Circle()
                    .stroke(lineWidth: lineWidth)
                    .opacity(0.1)
                    .foregroundColor(.green)
//                    .foregroundColor(fitness.successPercentage > 0 ? .green : .red)
                // Progress Toward Date
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(fitness.progressToDate, 1.0)))
//                    .stroke(lineWidth: lineWidth)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .opacity(0.4)
                    .foregroundColor(.green)
//                    .foregroundColor(fitness.successPercentage > 0 ? .green : .red)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.easeOut(duration: 1))

                // Progress
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(fitness.progressToWeight, 1.0)))
                                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
//                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(.green)
//                    .foregroundColor(fitness.successPercentage > 0 ? .green : .red)
                    .rotationEffect(Angle(degrees: 270.0))
//                    .animation(.linear)
                    .animation(.easeOut(duration: 1))
                if fitness.progressToWeight > fitness.progressToDate {
                    Circle()
                        .trim(from: CGFloat(fitness.progressToDate - 0.002), to: CGFloat(fitness.progressToDate + 0.002))
                        .stroke(lineWidth: lineWidth)
                        .opacity(1)
                        .foregroundColor(Color.white)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear)
                }
            }
        }
    }
}

struct ProgressCircle_Previews: PreviewProvider {
    struct ProgressCirclePreview: View {
        var body: some View {
            VStack {
                ProgressCircle().environmentObject(FitnessCalculations())
                    .frame(width: 150.0, height: 150.0)
                    .padding(40.0)
            }
        }
    }
    
    static var previews: some View {
        ProgressCirclePreview()
    }
}
