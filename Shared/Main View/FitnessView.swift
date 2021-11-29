//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

struct FitnessView: View {
    @EnvironmentObject var healthData: HealthData
    var shouldShowText: Bool = true
    var lineWidth: CGFloat = 10
    var widget: Bool = false
    @State var isDisplayingOverlay = false
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
                let x = UserDefaults.standard.value(forKey: "numberOfRuns") as? Int ?? 0
                Group {
                    #if os(watchOS)
                    StatsTitle(title: "\(x)")
                    #endif
                    #if os(iOS)
                    StatsTitle(title: "Deficits")
                    #endif
                    StatsRow(text: { DeficitText() }, rings: { DeficitRings()})
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                Group {
                    Text("Deficits This Week")
                        .foregroundColor(.white)
                        .font(.title2)
                    BarChart()
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 400)
                        .background(Color.myGray)
                        .cornerRadius(20)
                        .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                }
                Group {
                    StatsTitle(title: "Weight Loss")
                    StatsRow(text: { WeightLossText() }, rings: { WeightLossRings() })
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .onTapGesture {
                            Task {
                                healthData.activeCalorieModifier = 0.8
                                healthData.adjustActiveCalorieModifier.toggle()
                                await healthData.setValues(nil)
                            }
                        }
                }
                Group {
                    StatsTitle(title: "Lifts")
                    StatsRow(text: { LiftingText() }, rings: { LiftingRings() })
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .onTapGesture {
                            healthData.workouts.smithMachine.toggle()
                            healthData.workouts.calculate()
                        }
                }
                ZStack {
                    BenchGraph()
                        .environmentObject(healthData.workouts)
                        .environmentObject(healthData.fitness)
                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: 200)
                        .padding()
                        .background(Color.myGray)
                        .cornerRadius(20)
                    SquatGraph()
                        .environmentObject(healthData.workouts)
                        .environmentObject(healthData.fitness)
                        .padding()
                }
                Group {
                    StatsTitle(title: "Mile Time")
                        .onTapGesture {
#if !os(watchOS)
                            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                            impactHeavy.impactOccurred()
#endif
                            isDisplayingOverlay = true
                        }
                        .sheet(isPresented: $isDisplayingOverlay, onDismiss: {
                            self.isDisplayingOverlay = false
                        }) {
                            MileSettings()
                                .environmentObject(healthData)
                        }
                    MileTimeStats()
                        .environmentObject(healthData)
//                        .padding([.top, .leading, .trailing])
                        .background(Color.myGray)
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity)
                    RunningLineGraph()
                        .environmentObject(healthData)
                        .environmentObject(healthData.fitness)
                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: 400)
                        .padding()
                        .background(Color.myGray)
                        .cornerRadius(20)
                }
            }
            .padding()
        }
#if !os(watchOS)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("entering foreground")
            Task {
                await healthData.setValues(nil)
            }
        }
#endif
    }
}

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
                            UserDefaults.standard.set(healthData.numberOfRuns, forKey: "numberOfRuns")
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
                        UserDefaults.standard.set(healthData.numberOfRuns, forKey: "numberOfRuns")
                    }.frame(width: 100, height: 100)
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                }
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

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView()
            .environmentObject(HealthData(environment: .debug))
    }
}
