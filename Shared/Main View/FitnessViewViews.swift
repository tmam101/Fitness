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
                Text("Weight Change Over Time")
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
                        let realisticWeights = healthData.days
                            .mapValues { $0.realisticWeight }
                            .filter { $0.value != 0 }
                        let min = Double(realisticWeights.min { $0.value < $1.value }!.key)
                        let max = Double(realisticWeights.max { $0.value < $1.value }!.key)
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
            let dateToReach = Date.subtract(days: Int(deficitLineGraphDaysToShow), from: Date())
            
            let weightsFiltered = healthData.weightManager.weights
                .map { Weight(weight: $0.weight, date: Date.subtract(days: 1, from: $0.date)) }
                .filter { $0.date >= dateToReach }

            let expectedWeightsFiltered = healthData.calorieManager.expectedWeights
                .map { DateAndDouble(date: Date.subtract(days: 1, from: $0.date), double: $0.double)}
                .filter { $0.date >= dateToReach }
            
            let count = healthData.days
                .filter { $0.value.date >= dateToReach }
                .count - 1
            
            if expectedWeightsFiltered.count > 1, count > 1 {
                let mostRecentRealisticWeight = { () -> DateAndDouble in
                    for i in 1..<count {
                        if let day = healthData.days[i] {
                            if day.realisticWeight != 0 {
                                return DateAndDouble(date: day.date, double: day.realisticWeight)
                            }
                        }
                    }
                    return DateAndDouble(date: Date(), double: 0.0)
                }()
                
                let expectedWeights = WeightsAndChanges(first: expectedWeightsFiltered[count - 1], last: expectedWeightsFiltered.first!)
                let actualWeights = WeightsAndChanges(first: DateAndDouble(date: weightsFiltered.first!.date, double: weightsFiltered.first!.weight),
                                                last: DateAndDouble(date: weightsFiltered.last!.date, double: weightsFiltered.last!.weight))
                let realisticWeights = WeightsAndChanges(first: mostRecentRealisticWeight, last: DateAndDouble(date: healthData.days[count]!.date, double: healthData.days[count]!.realisticWeight))
                
                ChangeView(title: "Expected", weightsAndChanges: expectedWeights, color: .yellow)
                ChangeView(title: "Realistic", weightsAndChanges: realisticWeights, color: .green.opacity(0.5))
                ChangeView(title: "Actual", weightsAndChanges: actualWeights, color: .green)
            }
        }
    }
    
    struct WeightsAndChanges {
        var first: DateAndDouble
        var last: DateAndDouble
        var change: Double {
            first.double - last.double
        }
        var changeString: String {
            "\(String(format: "%.2f", last.double)) -> \(String(format: "%.2f", first.double))"
        }
    }
    
    struct ChangeView: View {
        var title: String
        var weightsAndChanges: WeightsAndChanges
        var color: Color
        
        var body: some View {
            VStack (alignment: .leading) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.caption)
                
                Text((weightsAndChanges.change >= 0 ? "+" : "") + "\(String(format: "%.2f", weightsAndChanges.change))")
                    .foregroundColor(color)
                    .font(.title)
                
                Text(weightsAndChanges.changeString)
                    .font(.caption)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
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
