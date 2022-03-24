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

struct FitnessViewMac: View {
    @EnvironmentObject var healthData: HealthData
//    @EnvironmentObject var watchConnectivityWatch: WatchConnectivityWatch
    var shouldShowText: Bool = true
    var lineWidth: CGFloat = 10
    var widget: Bool = false
    @State var isDisplayingOverlay = false
    @State var itWorked: String = "nothing"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let sectionHeight: CGFloat = 150
            
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
    }
}
