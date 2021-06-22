//
//  TextCollections.swift
//  Fitness
//
//  Created by Thomas Goss on 3/18/21.
//

import SwiftUI

struct WeightLossText: View {
    @EnvironmentObject var healthKit: MyHealthKit
    
    var body: some View {
        let weightLostString = String(format: "%.2f", healthKit.fitness.weightLost)
        let averageWeeklyLostString = String(format: "%.2f", healthKit.fitness.averageWeightLostPerWeek) + " / week"
        let averageMonthlyLostString = String(format: "%.2f", healthKit.fitness.averageWeightLostPerWeekThisMonth) + " / week"
        
        let averageDeficit = healthKit.averageDeficitSinceStart / 1000
        let averageWeightLoss = healthKit.fitness.averageWeightLostPerWeek / 2
//        let ratio = Int(((averageWeightLoss / averageDeficit) * 100 - 100).corrected())
        
        VStack(alignment: .leading) {
//            StatsText(color: .green3, title: "Compared to Deficit", stat: String(ratio) + "%")
            StatsText(color: .green3, title: "Total", title2: "vs " + String(format: "%.2f", healthKit.expectedWeightLossSinceStart), stat: weightLostString)
            StatsText(color: .green2, title: "Average", stat: averageWeeklyLostString)
            StatsText(color: .green1, title: "This Month", stat: averageMonthlyLostString)
        }
    }
}

struct LiftingText: View {
    @EnvironmentObject var healthKit: MyHealthKit
    
    var body: some View {
        LiftingTextInterior()
            .environmentObject(healthKit.fitness)
            .environmentObject(healthKit.workouts)
    }
}

private struct LiftingTextInterior: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var workouts: WorkoutInformation
    
    var body: some View {
        let currentWeight = fitness.currentWeight

        let squatORM = workouts.squatORM
        let squatRatio = CGFloat(squatORM / currentWeight)
        
        let benchORM = workouts.benchORM
        let benchRatio = CGFloat(benchORM / currentWeight)
        
        let benchString = String(Int(benchRatio * 100)) + "/\(Int(WorkoutInformation.benchBodyweightRatio * 100)) % bw"
        let squatString = String(Int(squatRatio * 100)) + "/\(Int(WorkoutInformation.squatBodyweightRatio * 100)) % bw"
        
        let benchTitle = "Bench" + (workouts.smithMachine ? " (Smith)" : "")
        let squatTitle = "Squat" + (workouts.smithMachine ? " (Smith)" : "")

        VStack(alignment: .leading) {
            StatsText(color: .purple, title: benchTitle, stat: benchString)
            StatsText(color: .pink, title: squatTitle, stat: squatString)
        }
    }
}

struct DeficitText: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var percentages: Bool = false
    
    var body: some View {
        let deficitToday: Int = Int(healthKit.deficitToday)
        let idealDeficit: Int = Int(healthKit.deficitToGetCorrectDeficit)
        let averageDeficit: Int = Int(healthKit.averageDeficitThisWeek)
        let totalDeficit: Int = Int(healthKit.averageDeficitSinceStart)
        
        // Non-percentages
        let averageDeficitString = String(averageDeficit) + "/1000"
        let deficitTodayString = String(deficitToday) + "/" + String(idealDeficit) + ""
        let totalDeficitString = String(totalDeficit) + "/1000"
        // Percentages
        let weightLostPercentString = String(healthKit.fitness.percentWeightLost) + "% lost"
        let averageDeficitPercentString = String(healthKit.percentWeeklyDeficit) + "% dfct"
        let deficitTodayPercentString = String(healthKit.percentDailyDeficit) + "% dfct tdy"
        
        if !self.percentages {
            VStack(alignment: .leading) {
                StatsText(color: .orange, title: "Total", stat: totalDeficitString)
                StatsText(color: .yellow, title: "Weekly", stat: averageDeficitString)
                StatsText(color: .blue, title: "Today", stat: deficitTodayString)
            }
        } else {
            VStack(alignment: .leading) {
                Text(weightLostPercentString)
                    .foregroundColor(.green)
                    .font(.subheadline)
                Text(averageDeficitPercentString)
                    .foregroundColor(.yellow)
                    .font(.subheadline)
                Text(deficitTodayPercentString)
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }
        }
    }
}
