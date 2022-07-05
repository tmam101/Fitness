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

struct FitnessViewWeightLossGraph: View {
    @EnvironmentObject var healthData: HealthData
    @Binding var deficitLineGraphDaysToShow: Double
    var sectionHeight: Double = 400
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading) {
                Text("Change Over Time")
                    .foregroundColor(.white)
                    .font(.title2)
                
                DeficitAndWeightStats(deficitLineGraphDaysToShow: $deficitLineGraphDaysToShow)
                    .environmentObject(healthData)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.myGray)
                    .cornerRadius(20)
                
                ZStack {
                    DeficitAndWeightLossGraph(daysAgoToReach: $deficitLineGraphDaysToShow)
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: sectionHeight)
                        .padding()
                        .background(Color.myGray)
                        .cornerRadius(20)
                }
                Slider(
                    value: $deficitLineGraphDaysToShow,
                    in: 1...Double(healthData.daysBetweenStartAndNow),
                    step: (deficitLineGraphDaysToShow < 100 ? 1 : 5) //todo this doesnt reach the first point. need to make sure it does
                )
                    .tint(.green)
                Text("past \(Int(deficitLineGraphDaysToShow)) days")
                    .foregroundColor(.green)
                HStack {
                    FitnessViewWeightLossGraphButton(deficitLineGraphDaysToShow: $deficitLineGraphDaysToShow, newValue: 7)
                    FitnessViewWeightLossGraphButton(deficitLineGraphDaysToShow: $deficitLineGraphDaysToShow, newValue: 30)
                    FitnessViewWeightLossGraphButton(deficitLineGraphDaysToShow: $deficitLineGraphDaysToShow, newValue: 100)
                    if healthData.days.count > 1 {
                        let weights = healthData.days
                            .mapValues { $0.realisticWeight }
                            .filter { $0.value != 0 }
                        let min = Double(weights.min { $0.value < $1.value }!.key) - 1
                        let max = Double(weights.max { $0.value < $1.value }!.key) - 1
                        FitnessViewWeightLossGraphButton(deficitLineGraphDaysToShow: $deficitLineGraphDaysToShow, newValue: min, label: "min")
                        FitnessViewWeightLossGraphButton(deficitLineGraphDaysToShow: $deficitLineGraphDaysToShow, newValue: max, label: "max")
                    }

                }
            }
        }
    }
    
    struct FitnessViewWeightLossGraphButton: View {
        @Binding var deficitLineGraphDaysToShow: Double
        var newValue: Double
        var label: String?
        
        var body: some View {
            Button(action: {
                deficitLineGraphDaysToShow = newValue
            }, label: {
                if (label != nil) {
                    Text(label!)
                        .padding()
                } else {
                    Text("\(Int(newValue)) days")
                        .padding()
                }
            })
                .foregroundColor(.green)
                .background(Color.myGray)
                .cornerRadius(20)
                .frame(maxWidth: .infinity)
        }
    }
}

struct FitnessViewWeightLossGraphPreview: View {
    @State var deficitLineGraphDaysToShow: Double = 30.0
    var body: some View {
        FitnessViewWeightLossGraph(deficitLineGraphDaysToShow: $deficitLineGraphDaysToShow)
            .environmentObject(HealthData(environment: .debug))
    }
}

struct FitnessViewWeightLossGraph_Previews: PreviewProvider {
    static var previews: some View {
        FitnessViewWeightLossGraphPreview()
            .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
    }
}

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
//            let realisticWeightsFiltered: [Double] = Array(healthData.days
//                .filter { $0.value.date >= dateToReach }
//                .mapValues { $0.realisticWeight }
//                .values)
            let count = healthData.days
                .filter { $0.value.date >= dateToReach }
                .count
            
            if expectedWeightsFiltered.count > 1 {
                let expectedWeightChange = (expectedWeightsFiltered[expectedWeightsFiltered.count - 2]) - (expectedWeightsFiltered.first ?? 0)
                let weightChange = (weightsFiltered.first ?? 0) - (weightsFiltered.last ?? 0)
                let expectedWeightString = String(format: "%.2f", expectedWeightChange)
                let weightString = String(format: "%.2f", weightChange)
                let realisticWeightChange = healthData.days[1]!.realisticWeight - healthData.days[count]!.realisticWeight
                let realisticWeightChangeString = String(format: "%.2f", realisticWeightChange)
                VStack (alignment: .leading) {
                    Text("Expected weight")
                        .foregroundColor(.yellow)
                    Text((expectedWeightChange >= 0 ? "+" : "") + "\(expectedWeightString)")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                
                VStack (alignment: .leading) {
                    Text("Realistic weight")
                        .foregroundColor(.green.opacity(0.5))
                    Text((realisticWeightChange >= 0 ? "+" : "") + "\(realisticWeightChangeString)")
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
