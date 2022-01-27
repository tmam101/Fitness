//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

struct FitnessView: View {
    @EnvironmentObject var healthData: HealthData
//    @EnvironmentObject var watchConnectivityIphone: WatchConnectivityIphone
    @Environment(\.scenePhase) private var scenePhase
    var shouldShowText: Bool = true
    var lineWidth: CGFloat = 10
    var widget: Bool = false
    @State var isDisplayingOverlay = false
    @State var deficitLineGraphDaysToShow: Double = 30.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let sectionHeight: CGFloat = 400
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
                    BarChart(showCalories: true)
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
                DeficitLineGraph()
                    .environmentObject(healthData)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200)
                    .background(Color.myGray)
                    .cornerRadius(20)
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
                        in: 0...Double(healthData.daysBetweenStartAndNow),
                        step: 5
                    )
                        .tint(.green)
                    Text("past \(Int(deficitLineGraphDaysToShow)) days")
                        .foregroundColor(.green)
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
                            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                            impactHeavy.impactOccurred()
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

struct FitnessView_Previews: PreviewProvider {
    
    static var previews: some View {
        AppView()
            .environmentObject(HealthData(environment: .debug))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
//            .environmentObject(WatchConnectivityIphone())
    }
}
