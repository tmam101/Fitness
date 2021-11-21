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
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10.0
    var color = Color.green1
    
    var body: some View {
        let average = CGFloat(healthData.fitness.averageWeightLostPerWeekThisMonth / 2)
        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: average, opacity: 1, lineWidth: lineWidth)

    }
}
struct WeeklyAverageDeficitCircle: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10.0
    var color = Color.yellow
    var body: some View {
        let deficit = healthData.averageDeficitThisWeek
        let projectedTomorrow = healthData.projectedAverageWeeklyDeficitForTomorrow
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
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10
    var color = Color.blue
    
    var body: some View {
        let deficit = healthData.deficitToday
        let idealDeficit = healthData.deficitToGetCorrectDeficit
        let percent: CGFloat = CGFloat((deficit / (idealDeficit == 0 ? 1 : idealDeficit)))
        
        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: percent, opacity: 1, lineWidth: lineWidth)
    }
}

struct TotalWeightLossCircle: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10.0
    var color = Color.green2
    
    var body: some View {
        VStack {
            ZStack {
                // Background
                BackgroundCircle(color: color, lineWidth: lineWidth)
                            
                // Progress
                GenericCircle(color: color, starting: 0.0, ending: CGFloat(min(healthData.fitness.progressToWeight, 1.0)), opacity: 1, lineWidth: lineWidth)
            }
        }
    }
}

struct MonthlyDeficitCircle: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10.0
    var color = Color.orange

    var body: some View {
        let avg = healthData.averageDeficitThisMonth
        let projectedTomorrow = healthData.projectedAverageMonthlyDeficitTomorrow
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

struct AverageTotalDeficitCircle: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10.0
    var color = Color.orange

    var body: some View {
        let avg = healthData.averageDeficitSinceStart
        let projectedTomorrow = healthData.projectedAverageTotalDeficitForTomorrow
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
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10.0
    var color = Color.green3
    
    var body: some View {
        let averageDeficit = healthData.averageDeficitSinceStart / 1000
        let averageWeightLoss = healthData.fitness.averageWeightLostPerWeek / 2
        let ratio = CGFloat(averageWeightLoss / averageDeficit).corrected()
        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: ratio, opacity: 1, lineWidth: lineWidth)
    }
}

struct AverageTotalWeightLossCircle: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10.0
    var color = Color.green1
    
    var body: some View {
        let averageWeightLoss = CGFloat(healthData.fitness.averageWeightLostPerWeek / 2)
        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: averageWeightLoss, opacity: 1, lineWidth: lineWidth)
    }
}

struct BenchPressRing: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var workouts: WorkoutInformation

    var lineWidth: CGFloat = 10.0
    var color = Color.green1
    
    var body: some View {
        let startingBench = workouts.firstBenchORM 
        let startingWeight = fitness.startingWeight
        let startingRatio = CGFloat(startingBench / startingWeight) / CGFloat(WorkoutInformation.benchBodyweightRatio) // 80
        
        let benchORM = workouts.benchORM 
        let currentWeight = fitness.currentWeight
        let ratio = CGFloat(benchORM / currentWeight) / CGFloat(WorkoutInformation.benchBodyweightRatio) // 90
        
        let corrected = (ratio - startingRatio) / (1 - startingRatio)
        let c2 = corrected < 0 ? 0 : corrected
        
        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: c2, opacity: 1, lineWidth: lineWidth)
    }
}

struct SquatRing: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var workouts: WorkoutInformation


    var lineWidth: CGFloat = 10.0
    var color = Color.green1
    
    var body: some View {
        let startingSquat = workouts.firstSquatORM
        let startingWeight = fitness.startingWeight
        let startingRatio = CGFloat(startingSquat / startingWeight) / CGFloat(WorkoutInformation.squatBodyweightRatio)
        
        let squatORM = workouts.squatORM
        let currentWeight = fitness.currentWeight
        let ratio = CGFloat(squatORM / currentWeight) / CGFloat(WorkoutInformation.squatBodyweightRatio)
        
        let corrected = (ratio - startingRatio) / (1 - startingRatio)
        let c2 = corrected < 0 ? 0 : corrected

        BackgroundCircle(color: color, lineWidth: lineWidth)
        GenericCircle(color: color, starting: 0.0, ending: c2, opacity: 1, lineWidth: lineWidth)
    }
}
