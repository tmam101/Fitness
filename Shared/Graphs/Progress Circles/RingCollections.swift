//
//  RingCollections.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 3/18/21.
//

import Foundation
import SwiftUI

struct DeficitRings: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        ZStack() {
            MonthlyDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
            WeeklyAverageDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
            DailyDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
        }
    }
}

struct WeightLossRings: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        
        ZStack {
            TotalWeightLossCircle(lineWidth: lineWidth, color: .green3)
                .environmentObject(healthData)
                .padding(paddingSize)
            AverageTotalWeightLossCircle(lineWidth: lineWidth, color: .green2)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
            MonthlyAverageWeightLossCircle(lineWidth: lineWidth, color: .green1)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
        }
    }
}

struct LiftingRings: View {
    @EnvironmentObject var healthData: HealthData

    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        
        ZStack {
            BenchPressRing(lineWidth: lineWidth, color: .purple)
                .environmentObject(healthData.fitness)
                .environmentObject(healthData.workouts)
            SquatRing(lineWidth: lineWidth, color: .pink)
                .environmentObject(healthData.fitness)
                .environmentObject(healthData.workouts)
                .padding(paddingSize)
        }
    }
}

struct AllRings: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        
        ZStack {
            AverageTotalDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
            WeeklyAverageDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
            DailyDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            TotalWeightLossCircle(lineWidth: lineWidth, color: .green3)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            AverageTotalWeightLossCircle(lineWidth: lineWidth, color: .green2)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            MonthlyAverageWeightLossCircle(lineWidth: lineWidth, color: .green1)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
        }
    }
}
