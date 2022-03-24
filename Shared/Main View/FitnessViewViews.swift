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
                        await healthData.setValues(nil)
                    }
                }
            }.background(.blue)
        }
    }
}
#endif

struct MileTimeStats: View {
    @EnvironmentObject var healthData: HealthData

    var body: some View {
        let runs = Array(healthData.runs.suffix(healthData.numberOfRuns))
        let decrease = (runs.first?.averageMileTime ?? 0.0) - (runs.last?.averageMileTime ?? 0.0)
        let timeDecrease = Time.doubleToString(double: decrease)
        VStack(alignment: .leading) {
        Text("Decrease")
            .foregroundColor(.white)
//            .frame(maxWidth: .infinity)
        Text("\(timeDecrease)")
            .foregroundColor(.blue)
            .font(.title2)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
    }
}

struct MileSettings: View {
    @EnvironmentObject var healthData: HealthData
    
    var body: some View {
        ZStack {
            Color.myGray.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Runs to Display")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                HStack {
                    Button("-") {
                        if healthData.numberOfRuns > 2 {
                            healthData.numberOfRuns -= 1
                            Settings.set(key: .numberOfRuns, value: healthData.numberOfRuns)
                        }
                    }.frame(width: 100, height: 100)
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                    Text("\(healthData.numberOfRuns)")
                        .foregroundColor(.white)
                        .font(.system(size: 70))
                    Button("+") {
                        if healthData.numberOfRuns <= healthData.runs.count {
                        healthData.numberOfRuns += 1
                        }
                        Settings.set(key: .numberOfRuns, value: healthData.numberOfRuns)
                    }.frame(width: 100, height: 100)
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                }
//                NavigationView {
//                    ScrollView {
//                        ForEach(healthData.runs, id: \.date) { run in
//                            NavigationLink("\(run.averageMileTime)", destination: Text("\(run.averageMileTime)"))
//                        }
//                    }
//                }
            }
        }
    }
}

struct BenchGraph: View {
    @EnvironmentObject var workouts: WorkoutInformation
    @EnvironmentObject var fitness: FitnessCalculations
    
    var body: some View {
        LiftingLineGraph(oneRepMaxes: workouts.benchORMs, color: .purple)
            .environmentObject(fitness)
    }
}

struct SquatGraph: View {
    @EnvironmentObject var workouts: WorkoutInformation
    @EnvironmentObject var fitness: FitnessCalculations
    
    var body: some View {
        LiftingLineGraph(oneRepMaxes: workouts.squatORMs, color: .pink)
            .environmentObject(fitness)
    }
}
