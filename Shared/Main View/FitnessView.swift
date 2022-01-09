//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

func isWatch() -> Bool {
    var isWatch = false
#if os(watchOS)
    isWatch = true
#endif
    return isWatch
}

struct FitnessView: View {
    @EnvironmentObject var healthData: HealthData
    @EnvironmentObject var watchConnectivityIphone: WatchConnectivityIphone
    @Environment(\.scenePhase) private var scenePhase
    var shouldShowText: Bool = true
    var lineWidth: CGFloat = 10
    var widget: Bool = false
    @State var isDisplayingOverlay = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let isWatch = isWatch()
                let sectionHeight: CGFloat = isWatch ? 150 : 400
//                Text("watch message: \(watchConnectivityIphone.messageString)")
//                    .foregroundColor(.white)
                
                // Add calories eaten
//                if isWatch {
//                    HStack {
//                        Group {
//                            Text("+")
//                                .foregroundColor(.black)
//                        }
//                        .frame(minWidth: 50, minHeight: 50)
//                        .background(Color.white)
//                        .cornerRadius(20)
//
//                        Text("Add calories eaten")
//                            .foregroundColor(.white)
//                    }
//                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 75)
//                    .background(Color.myGray)
//                    .cornerRadius(20)
//                    .onTapGesture {
//                        // TODO
//                        print("clicked")
//                        NavigationLink(destination: Text("H")) {
//                            Label("Title", systemImage: "folder")
//                        }
//                    }
//                }
                
                if isWatch {
                    NavigationLink(destination: {
                        NumberInput()
                            .environmentObject(healthData)
                    }) {
                        Text("Add calories eaten")
//                            .foregroundColor(.white)
//                            .frame(minWidth: 50, minHeight: 50)
//                            .background(.gray)
//                            .cornerRadius(20)
                    }
                }
                
                Group {
                    StatsTitle(title: "Deficits")
                    StatsRow(text: { DeficitText() }, rings: { DeficitRings()})
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                Group {
                    Text("Deficits This Week")
                        .foregroundColor(.white)
                        .font(.title2)
                    BarChart(showCalories: !isWatch)
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: sectionHeight)
                        .background(Color.myGray)
                        .cornerRadius(20)
                        .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
//                        .if(!healthData.hasLoaded) { view in
//                            view.redacted(reason: .placeholder)
//                        }
//                        .if(healthData.hasLoaded) { view in
//                            view.unredacted()
//                        }
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
