//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

struct FitnessView: View {
    @EnvironmentObject var healthKit: MyHealthKit
    var shouldShowText: Bool = true
    var lineWidth: CGFloat = 10
    var widget: Bool = false
    @State var isDisplayingOverlay = false
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
                Group {
                    StatsTitle(title: "Deficits")
                    StatsRow(text: { DeficitText() }, rings: { DeficitRings()})
                        .environmentObject(healthKit)
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                Group {
                    Text("Deficits This Week")
                        .foregroundColor(.white)
                        .font(.title2)
                    BarChart()
                        .environmentObject(healthKit)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 400)
                        .background(Color.myGray)
                        .cornerRadius(20)
                        .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                }
                Group {
                    StatsTitle(title: "Weight Loss")
                    StatsRow(text: { WeightLossText() }, rings: { WeightLossRings() })
                        .environmentObject(healthKit)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .onTapGesture {
                            Task {
                                healthKit.activeCalorieModifier = 0.8
                                healthKit.adjustActiveCalorieModifier.toggle()
                                await healthKit.setValues(nil)
                            }
                        }
                }
                Group {
                    StatsTitle(title: "Lifts")
                    StatsRow(text: { LiftingText() }, rings: { LiftingRings() })
                        .environmentObject(healthKit)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .onTapGesture {
                            healthKit.workouts.smithMachine.toggle()
                            healthKit.workouts.calculate()
                        }
                }
                ZStack {
                    BenchGraph()
                        .environmentObject(healthKit.workouts)
                        .environmentObject(healthKit.fitness)
                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: 200)
                        .padding()
                        .background(Color.myGray)
                        .cornerRadius(20)
                    SquatGraph()
                        .environmentObject(healthKit.workouts)
                        .environmentObject(healthKit.fitness)
                        .padding()
                }
                Group {
                    StatsTitle(title: "Mile Time")
                        .onTapGesture {
                            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                            impactHeavy.impactOccurred()
                            isDisplayingOverlay = true
                        }
                        .sheet(isPresented: $isDisplayingOverlay, onDismiss: {
                            self.isDisplayingOverlay = false
                        }) {
                            MileSettings()
                                .environmentObject(healthKit)
                        }
                    MileTimeStats()
                        .environmentObject(healthKit)
//                        .padding([.top, .leading, .trailing])
                        .background(Color.myGray)
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity, idealHeight: 200)
                    RunningLineGraph()
                        .environmentObject(healthKit)
                        .environmentObject(healthKit.fitness)
                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: 400)
                        .padding()
                        .background(Color.myGray)
                        .cornerRadius(20)
                }
            }
            .padding()
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("entering foreground")
            Task {
                await healthKit.setValues(nil)
            }
        }
    }
}

struct MileTimeStats: View {
    @EnvironmentObject var healthKit: MyHealthKit

    var body: some View {
        let runs = Array(healthKit.runs.suffix(healthKit.numberOfRuns))
        let decrease = (runs.first?.averageMileTime ?? 0.0) - (runs.last?.averageMileTime ?? 0.0)
        Text("Time decrease: \(Time.doubleToString(double: decrease))")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MileSettings: View {
    @EnvironmentObject var healthKit: MyHealthKit
    
    var body: some View {
        ZStack {
            Color.myGray.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Runs to Display")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                HStack {
                    Button("-") {
                        if healthKit.numberOfRuns > 2 {
                            healthKit.numberOfRuns -= 1
                            UserDefaults.standard.set(healthKit.numberOfRuns, forKey: "numberOfRuns")
                        }
                    }.frame(width: 100, height: 100)
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                    Text("\(healthKit.numberOfRuns)")
                        .foregroundColor(.white)
                        .font(.system(size: 70))
                    Button("+") {
                        if healthKit.numberOfRuns <= healthKit.runs.count {
                        healthKit.numberOfRuns += 1
                        }
                        UserDefaults.standard.set(healthKit.numberOfRuns, forKey: "numberOfRuns")
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
            .environmentObject(MyHealthKit(environment: .debug))
    }
}
