//
//  ProgressCircle.swift
//  Trello
//
//  Created by Thomas Goss on 6/8/20.
//  Copyright © 2020 Thomas Goss. All rights reserved.
//

import Foundation
import SwiftUI

struct CalorieCircle: View {
    @EnvironmentObject var healthKit: MyHealthKit
//    @State var burned: Float = 300
//    @State var eaten: Float = 1500
    var lineWidth: CGFloat = 10.0
    
    var body: some View {
        Circle()
            .stroke(lineWidth: lineWidth)
            .opacity(0.1)
            .foregroundColor(.blue)
        Circle()
            .trim(from: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, to: CGFloat((healthKit.eaten ?? 0) / ((healthKit.burned ?? 0) + 1500)))
            .stroke(lineWidth: lineWidth)
            .foregroundColor(((healthKit.eaten ?? 0) / ((healthKit.burned ?? 0) + 1500)) > 1 ? .red : .blue)
            .rotationEffect(Angle(degrees: 270.0))
            .animation(.linear)
        Circle()
            .trim(from: CGFloat((healthKit.progress ?? 0.002) - 0.002), to: CGFloat((healthKit.progress ?? 0) + 0.002))
            .stroke(lineWidth: lineWidth)
            .opacity(1)
            .foregroundColor(Color.white)
            .rotationEffect(Angle(degrees: 270.0))
            .animation(.linear)
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
                    .foregroundColor(fitness.successPercentage > 0 ? .green : .red)
                // Progress Toward Date
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(fitness.progressToDate, 1.0)))
                    .stroke(lineWidth: lineWidth)
                    .opacity(0.4)
                    .foregroundColor(fitness.successPercentage > 0 ? .green : .red)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear)
                // Progress
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(fitness.progressToWeight, 1.0)))
                    //                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(fitness.successPercentage > 0 ? .green : .red)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear)
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
//        @State var progressValue: Float = 0.6
//        @State var progressTowardDate: Float = 0.5
//        @EnvironmentObject var fitness: FitnessCalculations
        var body: some View {
            VStack {
                ProgressCircle().environmentObject(FitnessCalculations())
                    .frame(width: 150.0, height: 150.0)
                    .padding(40.0)
//                Button(action: {self.progressValue += 0.1}, label: {Text("\(self.progressValue)")})
            }
        }
    }
    
    static var previews: some View {
        ProgressCirclePreview()
    }
}
