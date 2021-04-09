//
//  FitnessApp.swift
//  Shared
//
//  Created by Thomas Goss on 1/20/21.
//

import SwiftUI

@main
struct FitnessApp: App {
    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}

struct AppView: View {
    @State var fitness = FitnessCalculations(environment: GlobalEnvironment.environment)
    @State var healthKit = MyHealthKit(environment: GlobalEnvironment.environment)
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
//                let deficits = [0,1,2,3,4,5,6].map { healthKit.getDeficitForDay(daysAgo: $0) { i in return i } }
//                let percents = BarChart.deficitsToPercents(daysAndDeficits: healthKit.dailyDeficits)
//                BarChart()
//                    .environmentObject(healthKit)
//                    .frame(width: 300, height: 200)
//                    .background(Color.myGray)
                FitnessView()
                    .environmentObject(fitness)
                    .environmentObject(healthKit)
            }
        }
    }
}

struct FitnessApp_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}

struct Deets: View {
    @EnvironmentObject var fitness: FitnessCalculations
    var body: some View {
        VStack {
            Text("Weight: \(Int(fitness.currentWeight))").foregroundColor(.white)
            Text("Goal Weight: \(Int(fitness.endingWeight))").foregroundColor(.white)
//            Button("Press") {
//                self.fitness.currentWeight = 220
//                self.fitness.getAllStats { _ in
//
//                }
//            }
        }
    }
}
