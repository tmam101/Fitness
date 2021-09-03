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
                StatsRow(text: { DeficitText() }, rings: { DeficitRings()})
                    .environmentObject(healthKit)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .onTapGesture {
                        healthKit.setValues(nil)
                    }
                BarChart()
                    .environmentObject(healthKit)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 200)
                    .background(Color.myGray)
                    .cornerRadius(20)
                    .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                    .padding(.bottom, 30)
                
                StatsTitle(title: "Weight Loss")
                StatsRow(text: { WeightLossText() }, rings: { WeightLossRings() })
                    .environmentObject(healthKit)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.bottom, 30)
                
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
            }
            .padding()
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("entering foreground")
            healthKit.setValues(nil)
        }
    }
}

struct BenchGraph: View {
    @EnvironmentObject var workouts: WorkoutInformation
    @EnvironmentObject var fitness: FitnessCalculations

    var body: some View {
        LineGraph(oneRepMaxes: workouts.benchORMs, color: .purple)
            .environmentObject(fitness)
    }
}

struct SquatGraph: View {
    @EnvironmentObject var workouts: WorkoutInformation
    @EnvironmentObject var fitness: FitnessCalculations

    var body: some View {
        LineGraph(oneRepMaxes: workouts.squatORMs, color: .pink)
            .environmentObject(fitness)
    }
}

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView()
            .environmentObject(MyHealthKit(environment: .debug))
    }
}
