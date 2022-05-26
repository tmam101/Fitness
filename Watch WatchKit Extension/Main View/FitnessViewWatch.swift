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
                Text("\(Int(healthData.calorieManager.averageDeficitThisMonth))")
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                Text("\(Int(healthData.calorieManager.averageDeficitThisWeek))")
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity)
                Text("\(Int(healthData.calorieManager.deficitToday))")
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
            }
            DeficitRings()
                .environmentObject(healthData)
        }
    }
}

struct Rings: View {
    @EnvironmentObject var healthData: HealthData

    var body: some View {
        TodayRingWithMonthly()
            .environmentObject(healthData)
            .padding()
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
    @State var runsToShow: Double = 5.0


    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let sectionHeight: CGFloat = 75
                Group {
                    StatsTitle(title: "Deficits")
                    Rings()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 150)
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
                    
                    if healthData.runManager.runs.count > 1 {
                        MileTimeStats(runsToShow: $runsToShow)
                            .environmentObject(healthData)
                            .background(Color.myGray)
                            .cornerRadius(20)
                            .frame(maxWidth: .infinity)
                        RunningLineGraph(runsToShow: $runsToShow)
                            .environmentObject(healthData)
                            .frame(minWidth: 0, maxWidth: .infinity, idealHeight: sectionHeight)
                            .padding()
                            .background(Color.myGray)
                            .cornerRadius(20)
                        Slider(
                            value: $runsToShow,
                            in: 1...Double(healthData.runManager.runs.count),
                            step: 1 //todo this doesnt reach the first point. need to make sure it does
                        )
                            .tint(.blue)
                        Text("past \(Int(runsToShow)) runs")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
        .onChange(of: scenePhase) { _ in
            if scenePhase == .background {
                Task {
                    await healthData.setValues(completion: nil)
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
