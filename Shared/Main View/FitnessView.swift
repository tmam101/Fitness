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
    @State var runsToShow: Double = 5.0
    @State var showLifts = false
    @State var showWeightRings = false
    @State var showWeeklyDeficitLine = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let sectionHeight: CGFloat = 400
                
                //MARK: DEFICIT RINGS
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
                
                // MARK: DEFICIT BAR CHART
                Group {
                    Text("Deficits This Week")
                        .foregroundColor(.white)
                        .font(.title2)
                    SwiftUIBarChart()
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: sectionHeight)
                        .mainBackground()
//                    BarChart(showCalories: true)
//                        .environmentObject(healthData)
//                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: sectionHeight)
//                        .mainBackground()
//                        .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                }
                
                //MARK: DEFICIT LINE GRAPH
                if showWeeklyDeficitLine {
                    Group {
                        Text("Expected Weight This Week")
                            .foregroundColor(.white)
                            .font(.title2)
                        DeficitLineGraph()
                            .environmentObject(healthData)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200)
                            .mainBackground()
                    }
                }
                Group {
                    if showWeightRings {
                        //MARK: WEIGHT Loss
                        StatsTitle(title: "Weight Loss")
                        StatsRow(text: { WeightLossText() }, rings: { WeightLossRings() })
                            .environmentObject(healthData)
                            .frame(minWidth: 0, maxWidth: .infinity)
                    }
                    FitnessViewWeightLossGraph(deficitLineGraphDaysToShow: $deficitLineGraphDaysToShow)
                        .environmentObject(healthData)
                }
                
                //MARK: MILE TIME
                Group {
                    StatsTitle(title: "Mile Time")
                    MileTimeStats(runsToShow: $runsToShow)
                        .environmentObject(healthData)
                        .mainBackground()
                        .frame(maxWidth: .infinity)
                    RunningLineGraph(runsToShow: $runsToShow)
                        .environmentObject(healthData)
                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: sectionHeight)
                        .padding()
                        .mainBackground()
                    if healthData.runManager.runs.count > 1 {
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
                    await healthData.setValues(completion: nil) //todo add force load here?
                }
            }
        }
    }
}

struct FitnessView_Previews: PreviewProvider {
    
    static var previews: some View {
        FitnessPreviewProvider.MainPreview()
//        AppView()
//            .environmentObject(HealthData(environment: .debug))
//            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
//        //            .environmentObject(WatchConnectivityIphone())
    }
}

public struct FitnessPreviewProvider {
    static func MainPreview() -> some View {
        return AppView()
            .environmentObject(HealthData(environment: .debug))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
    }
}
