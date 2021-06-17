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
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
                StatsTitle(title: "Deficits")
                HStack {
                    StatsRow(text: { DeficitText() }, rings: { DeficitRings()})
                        .environmentObject(healthKit)
                        .frame(minWidth: 0, maxWidth: .infinity)
                    BarChart()
                        .environmentObject(healthKit)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200)
                        .background(Color.myGray)
                        .cornerRadius(20)
                        .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                }
                
                StatsTitle(title: "Weight Loss")
                StatsRow(text: { WeightLossText() }, rings: { WeightLossRings() })
                    .environmentObject(healthKit)
                    .frame(minWidth: 0, maxWidth: .infinity)
                
                StatsTitle(title: "Lifts")
                StatsRow(text: { LiftingText() }, rings: { LiftingRings() })
                    .environmentObject(healthKit)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .onTapGesture {
                        healthKit.workouts.smithMachine.toggle()
                        healthKit.workouts.calculate()
                    }
                ZStack {
                    BenchGraph()
                        .environmentObject(healthKit.workouts)
                        .frame(minWidth: 0, maxWidth: .infinity, idealHeight: 200)
                        .padding()
                        .background(Color.myGray)
                        .cornerRadius(20)
                    SquatGraph()
                        .environmentObject(healthKit.workouts)
                        .padding()
                }
            }
            .padding()
        }
    }
}

struct BenchGraph: View {
    @EnvironmentObject var workouts: WorkoutInformation
    
    var body: some View {
        LineGraph(weights: workouts.benchORMs, color: .purple)
    }
}

struct SquatGraph: View {
    @EnvironmentObject var workouts: WorkoutInformation
    
    var body: some View {
        LineGraph(weights: workouts.squatORMs, color: .pink)
    }
}

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView()
            .environmentObject(MyHealthKit(environment: .debug))
    }
}
