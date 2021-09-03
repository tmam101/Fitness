//
//  RingCollections.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 3/18/21.
//

import Foundation
import SwiftUI

struct DeficitRings: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        ZStack() {
            AverageTotalDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthKit)
                .padding(paddingSize)
            WeeklyAverageDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
            DailyDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
        }
    }
}

struct WeightLossRings: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        
        ZStack {
            TotalWeightLossCircle(lineWidth: lineWidth, color: .green1)
                .environmentObject(healthKit)
                .padding(paddingSize)
            AverageTotalWeightLossCircle(lineWidth: lineWidth, color: .green1)
                .environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
            MonthlyAverageWeightLossCircle(lineWidth: lineWidth, color: .green1)
                .environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
        }
    }
}

struct LiftingRings: View {
    @EnvironmentObject var healthKit: MyHealthKit

    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        
        ZStack {
            BenchPressRing(lineWidth: lineWidth, color: .purple)
                .environmentObject(healthKit.fitness)
                .environmentObject(healthKit.workouts)
            SquatRing(lineWidth: lineWidth, color: .pink)
                .environmentObject(healthKit.fitness)
                .environmentObject(healthKit.workouts)
                .padding(paddingSize)
        }
    }
}

struct AllRings: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        
        ZStack {
            AverageTotalDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthKit)
                .padding(paddingSize)
            WeeklyAverageDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
            DailyDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            TotalWeightLossCircle(lineWidth: lineWidth, color: .green3)
                .environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            AverageTotalWeightLossCircle(lineWidth: lineWidth, color: .green2)
                .environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            MonthlyAverageWeightLossCircle(lineWidth: lineWidth, color: .green1)
                .environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
        }
    }
}
