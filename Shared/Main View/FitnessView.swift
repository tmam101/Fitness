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
    @State var showLifts = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let sectionHeight: CGFloat = 400
                
                Group {
                    HStack {
                        StatsTitle(title: "Deficits")
                        if !healthData.hasLoaded {
                        Circle()
                            .fill()
                            .foregroundColor(.red)
                            .frame(width: 20)
                        }
                    }
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
                Text("Expected Weight This Week")
                    .foregroundColor(.white)
                    .font(.title2)
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
                    Text("Expected Weight vs Weight Over Time")
                        .foregroundColor(.white)
                        .font(.title2)

                    HStack {
                        let expectedWeights = healthData.expectedWeights
                        let weights = healthData.fitness.weights
                        let dateToReach = Date.subtract(days: Int(deficitLineGraphDaysToShow), from: Date())
                        let weightsFiltered = weights.filter { $0.date >= dateToReach }.map { $0.weight }
                        let expectedWeightsFiltered = expectedWeights.filter { $0.date >= dateToReach }.map { $0.double }
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
                }
                if showLifts {
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
