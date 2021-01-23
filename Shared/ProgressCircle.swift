//
//  ProgressCircle.swift
//  Trello
//
//  Created by Thomas Goss on 6/8/20.
//  Copyright © 2020 Thomas Goss. All rights reserved.
//

import Foundation
import SwiftUI

struct ProgressCircle: View {
    @Binding var progress: Float
    @Binding var progressTowardDate: Float
    @Binding var successPercentage: Float
//    @EnvironmentObject var fitness: FitnessCalculations
    var lineWidth: CGFloat = 10.0
    
    var body: some View {
        VStack {
        ZStack {
            // Background
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.1)
                .foregroundColor(successPercentage > 0 ? .green : .red)
            // Progress Toward Date
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progressTowardDate, 1.0)))
                .stroke(lineWidth: lineWidth)
                .opacity(0.4)
                .foregroundColor(successPercentage > 0 ? .green : .red)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear)
            // Progress
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
//                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .stroke(lineWidth: lineWidth)
                .foregroundColor(successPercentage > 0 ? .green : .red)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear)
            if progress > progressTowardDate {
                Circle()
                    .trim(from: CGFloat(progressTowardDate - 0.002), to: CGFloat(progressTowardDate + 0.002))
                    .stroke(lineWidth: lineWidth)
                    .opacity(1)
                    .foregroundColor(Color.black)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear)
            }
        }
        }
    }
}

struct ProgressCircle_Previews: PreviewProvider {
    struct ProgressCirclePreview: View {
        @State var progressValue: Float = 0.6
        @State var progressTowardDate: Float = 0.5
        @EnvironmentObject var fitness: FitnessCalculations
        var body: some View {
            VStack {
                ProgressCircle(progress: $fitness.progressToWeight, progressTowardDate: $fitness.progressToDate, successPercentage: $fitness.successPercentage)
                    .frame(width: 150.0, height: 150.0)
                    .padding(40.0)
                Button(action: {self.progressValue += 0.1}, label: {Text("\(self.progressValue)")})
            }
        }
    }
    
    static var previews: some View {
        ProgressCirclePreview()
    }
}
