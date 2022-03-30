//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

struct DeficitsView: View {
    @EnvironmentObject var healthData: HealthData

    var body: some View {
        VStack {
            HStack {
                Text("\(Int(healthData.averageDeficitThisMonth))")
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                Text("\(Int(healthData.averageDeficitThisWeek))")
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity)
                Text("\(Int(healthData.deficitToday))")
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
            }
            DeficitRings()
                .environmentObject(healthData)
        }
    }
}

struct FitnessViewWatch: View {
    @EnvironmentObject var healthData: HealthData
//    @EnvironmentObject var watchConnectivityWatch: WatchConnectivityWatch
    @Environment(\.scenePhase) private var scenePhase
    var shouldShowText: Bool = true
    var lineWidth: CGFloat = 10
    var widget: Bool = false
    @State var isDisplayingOverlay = false
    @State var itWorked: String = "nothing"
    @State var deficitLineGraphDaysToShow: Double = 30.0

    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let sectionHeight: CGFloat = 75
                
                // Add calories eaten
//                    NavigationLink(destination: {
//                        NumberInput()
//                            .environmentObject(healthData)
//                    }) {
//                        Text("Add calories eaten")
//                    }
                Group {
                    StatsTitle(title: "Deficits")
                    DeficitsView()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: sectionHeight)
                        .environmentObject(healthData)
                        .background(Color.myGray)
                        .cornerRadius(20)
                }
                
                Group {
                    StatsTitle(title: "Deficits This Week")
                    BarChart(cornerRadius: 2, showCalories: false)
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: sectionHeight)
                        .background(Color.myGray)
                        .cornerRadius(20)
                        .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                }
                Group {
                    StatsTitle(title: "Expected Weight This Week")
                    DeficitLineGraph()
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: sectionHeight)
                        .background(Color.myGray)
                        .cornerRadius(20)
                }
                
                Text("Expected Weight vs Weight Over Time")
                    .foregroundColor(.white)
                
                DeficitAndWeightStats(deficitLineGraphDaysToShow: $deficitLineGraphDaysToShow)
                    .environmentObject(healthData)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.myGray)
                    .cornerRadius(20)
                
                ZStack {
                    DeficitAndWeightLossGraph(daysAgoToReach: $deficitLineGraphDaysToShow)
                        .environmentObject(healthData)
                        .environmentObject(healthData.fitness)
                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: sectionHeight)
                        .padding()
                        .background(Color.myGray)
                        .cornerRadius(20)
                }
                Slider(
                    value: $deficitLineGraphDaysToShow,
                    in: 5...Double(healthData.daysBetweenStartAndNow),
                    step: 5
                )
                    .tint(.green)
                Text("past \(Int(deficitLineGraphDaysToShow)) days")
                    .foregroundColor(.green)
//                Group {
//                    StatsTitle(title: "Weight Loss")
//                    StatsRow(text: { WeightLossText() }, rings: { WeightLossRings() })
//                        .environmentObject(healthData)
//                        .frame(minWidth: 0, maxWidth: .infinity)
//                        .onTapGesture {
//                            Task {
//                                healthData.activeCalorieModifier = 0.8
//                                healthData.adjustActiveCalorieModifier.toggle()
//                                await healthData.setValues(nil)
//                            }
//                        }
//                }
//                Group {
//                    StatsTitle(title: "Lifts")
//                    StatsRow(text: { LiftingText() }, rings: { LiftingRings() })
//                        .environmentObject(healthData)
//                        .frame(minWidth: 0, maxWidth: .infinity)
//                        .onTapGesture {
//                            healthData.workouts.smithMachine.toggle()
//                            healthData.workouts.calculate()
//                        }
//                }
//                ZStack {
//                    BenchGraph()
//                        .environmentObject(healthData.workouts)
//                        .environmentObject(healthData.fitness)
//                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: 200)
//                        .padding()
//                        .background(Color.myGray)
//                        .cornerRadius(20)
//                    SquatGraph()
//                        .environmentObject(healthData.workouts)
//                        .environmentObject(healthData.fitness)
//                        .padding()
//                }
                Group {
                    StatsTitle(title: "Mile Time")
                        .onTapGesture {
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
                        .background(Color.myGray)
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity)
                    RunningLineGraph()
                        .environmentObject(healthData)
                        .environmentObject(healthData.fitness)
                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: sectionHeight)
                        .padding()
                        .background(Color.myGray)
                        .cornerRadius(20)
                }
            }
            .padding()
        }
        .onChange(of: scenePhase) { _ in
            if scenePhase == .background {
                Task {
                    await healthData.setValues(nil)
                }
            }
        }
    }
}

struct FitnessViewWatch_Previews: PreviewProvider {
    static var previews: some View {
        FitnessViewWatch()
            .environmentObject(HealthData(environment: AppEnvironmentConfig.debug))
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 7 - 45 mm"))
    }
}
