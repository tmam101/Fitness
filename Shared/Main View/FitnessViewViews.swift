//
//  FitnessViewViews.swift
//  Fitness
//
//  Created by Thomas Goss on 1/8/22.
//

import SwiftUI

#if !os(macOS)
struct NumberInput: View {
    @State var num: String = "0"
    @EnvironmentObject var healthData: HealthData
    
    var body: some View {
        VStack {
            TextField("0", text: $num)
            Button("Done") {
                Task {
                    guard let double = Double(num) else { return }
                    let savedCalories = await healthData.saveCaloriesEaten(calories: double)
                    if savedCalories {
                        await healthData.setValues(completion: nil)
                    }
                }
            }.background(.blue)
        }
    }
}
#endif

struct DeficitAndWeightStats: View {
    @EnvironmentObject var healthData: HealthData
    @Binding var deficitLineGraphDaysToShow: Double
    
    var body: some View {
        HStack {
            let expectedWeights = healthData.calorieManager.expectedWeights
            let weights = healthData.weightManager.weights
            let dateToReach = Date.subtract(days: Int(deficitLineGraphDaysToShow), from: Date())
            let weightsFiltered = weights.filter { $0.date >= dateToReach }.map { $0.weight }
            let expectedWeightsFiltered = expectedWeights.filter { $0.date >= dateToReach }.map { $0.double }
            if expectedWeightsFiltered.count > 1 {
                let expectedWeightChange = (expectedWeightsFiltered[expectedWeightsFiltered.count - 2]) - (expectedWeightsFiltered.first ?? 0)
                let weightChange = (weightsFiltered.first ?? 0) - (weightsFiltered.last ?? 0)
                let expectedWeightString = String(format: "%.2f", expectedWeightChange)
                let weightString = String(format: "%.2f", weightChange)
                
                VStack (alignment: .leading) {
                    Text("Expected weight")
                        .foregroundColor(.yellow)
                    Text((expectedWeightChange >= 0 ? "+" : "") + "\(expectedWeightString)")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                VStack (alignment: .leading) {
                    Text("Weight")
                        .foregroundColor(.green)
                    Text((weightChange >= 0 ? "+" : "") + "\(weightString)")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

//todo this isnt displaying correctly
struct MileTimeStats: View {
    @EnvironmentObject var healthData: HealthData
    @Binding var runsToShow: Double
    var body: some View {
        let runs = Array(healthData.runManager.runs.suffix(Int(runsToShow)))
        let decrease = (runs.first?.averageMileTime ?? 0.0) - (runs.last?.averageMileTime ?? 0.0)
        let timeDecrease = Time.doubleToString(double: decrease)
        VStack(alignment: .leading) {
        Text("Decrease")
                .foregroundColor(.white)
            //            .frame(maxWidth: .infinity)
            Text("\(timeDecrease)")
                .foregroundColor(.blue)
#if os(iOS)
                .font(.title2)
#endif
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
    }
}

struct BenchGraph: View {
    @EnvironmentObject var workouts: WorkoutManager
    @EnvironmentObject var fitness: WeightManager
    
    var body: some View {
        LiftingLineGraph(oneRepMaxes: workouts.benchORMs, color: .purple)
            .environmentObject(fitness)
    }
}

struct SquatGraph: View {
    @EnvironmentObject var workouts: WorkoutManager
    @EnvironmentObject var fitness: WeightManager
    
    var body: some View {
        LiftingLineGraph(oneRepMaxes: workouts.squatORMs, color: .pink)
            .environmentObject(fitness)
    }
}
