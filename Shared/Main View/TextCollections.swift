//
//  TextCollections.swift
//  Fitness
//
//  Created by Thomas Goss on 3/18/21.
//

import SwiftUI

struct WeightLossText: View {
    @EnvironmentObject var healthData: HealthData
    
    var body: some View {
        let weightLostString = String(format: "%.2f", healthData.weightManager.weightLost) //todo these arent in the model
        let averageWeeklyLostString = String(format: "%.2f", healthData.weightManager.averageWeightLostPerWeek) + " avg"
        let averageMonthlyLostString = String(format: "%.2f", healthData.weightManager.averageWeightLostPerWeekThisMonth) + " wkly avg"
        
//        let averageDeficit = healthData.averageDeficitSinceStart / 1000
//        let averageWeightLoss = healthData.fitness.averageWeightLostPerWeek / 2
//        let ratio = Int(((averageWeightLoss / averageDeficit) * 100 - 100).corrected())
        
        VStack(alignment: .leading) {
//            StatsText(color: .green3, title: "Compared to Deficit", stat: String(ratio) + "%")
            StatsText(color: .green3, title: "Total", stat: weightLostString)
            StatsText(color: .green2, title: "Week", stat: averageWeeklyLostString)
            StatsText(color: .green1, title: "Month", stat: averageMonthlyLostString)
        }
    }
}

struct LiftingText: View {
    @EnvironmentObject var healthData: HealthData
    
    var body: some View {
        LiftingTextInterior()
            .environmentObject(healthData.workoutManager)
    }
}

private struct LiftingTextInterior: View {
    @EnvironmentObject var fitness: WeightManager
    @EnvironmentObject var workouts: WorkoutManager
    
    var body: some View {
        let currentWeight = fitness.currentWeight

        let squatORM = workouts.squatORM
        let squatRatio = CGFloat(squatORM / currentWeight)
        
        let benchORM = workouts.benchORM
        let benchRatio = CGFloat(benchORM / currentWeight)
        
        let benchString = String(Int(benchRatio * 100)) + "/\(Int(WorkoutManager.benchBodyweightRatio * 100)) % bw"
        let squatString = String(Int(squatRatio * 100)) + "/\(Int(WorkoutManager.squatBodyweightRatio * 100)) % bw"
        
        let benchTitle = "Bench" + (workouts.smithMachine ? " (Smith)" : "")
        let squatTitle = "Squat" + (workouts.smithMachine ? " (Smith)" : "")

        VStack(alignment: .leading) {
            StatsText(color: .purple, title: benchTitle, stat: benchString)
            StatsText(color: .pink, title: squatTitle, stat: squatString)
        }
    }
}

struct DeficitText: View {
    @EnvironmentObject var healthData: HealthData
    var percentages: Bool = false
    
    var body: some View {
        let deficitToday: Int = Int(healthData.calorieManager.deficitToday)
        let idealDeficit: Int = Int(healthData.calorieManager.deficitToGetCorrectDeficit)
        let averageDeficit: Int = Int(healthData.calorieManager.averageDeficitThisWeek)
//        let totalDeficit: Int = Int(healthData.averageDeficitSinceStart)
        let monthlyDeficit: Int = Int(healthData.calorieManager.averageDeficitThisMonth)
        
        // Non-percentages
        let averageDeficitString = String(averageDeficit) + "/\(Int(healthData.goalDeficit))"
        let deficitTodayString = String(deficitToday) + "/" + String(idealDeficit) + ""
//        let totalDeficitString = String(totalDeficit) + "/1000"
        let monthDeficitString = String(monthlyDeficit) + "/\(Int(healthData.goalDeficit))"
        // Percentages
        let weightLostPercentString = String(healthData.weightManager.percentWeightLost) + "% lost"
        let averageDeficitPercentString = String(healthData.calorieManager.percentWeeklyDeficit) + "% dfct"
        let deficitTodayPercentString = String(healthData.calorieManager.percentDailyDeficit) + "% dfct tdy"
        
        if !self.percentages {
            VStack(alignment: .leading) {
//                StatsText(color: .orange, title: "Total", stat: totalDeficitString)
                StatsText(color: .orange, title: "Month", stat: monthDeficitString)
                StatsText(color: .yellow, title: "Week", stat: averageDeficitString)
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
