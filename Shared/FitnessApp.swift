//
//  FitnessApp.swift
//  Shared
//
//  Created by Thomas Goss on 1/20/21.
//

import SwiftUI

@main
struct FitnessApp: App {
    @State var healthKit = MyHealthKit(environment: GlobalEnvironment.environment)
    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(healthKit)
        }
    }
}

struct AppView: View {
    @EnvironmentObject var healthKit: MyHealthKit
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
//                LineGraph(color: .yellow)
//                    .frame(width: 200, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
//                    .background(Color.black.opacity(0.5))
//                let deficits = [0,1,2,3,4,5,6].map { healthKit.getDeficitForDay(daysAgo: $0) { i in return i } }
//                let percents = BarChart.deficitsToPercents(daysAndDeficits: healthKit.dailyDeficits)
//                BarChart()
//                    .environmentObject(healthKit)
//                    .frame(width: 300, height: 200)
//                    .background(Color.myGray)
                FitnessView()
                    .environmentObject(healthKit)
            }
        }
    }
}

struct FitnessApp_Previews: PreviewProvider {
    
    static var previews: some View {
        AppView()
            .environmentObject(MyHealthKit(environment: .debug))
    }
}

//struct Deets: View {
//    @EnvironmentObject var fitness: FitnessCalculations
//    var body: some View {
//        VStack {
//            Text("Weight: \(Int(fitness.currentWeight))").foregroundColor(.white)
//            Text("Goal Weight: \(Int(fitness.endingWeight))").foregroundColor(.white)
////            Button("Press") {
////                self.fitness.currentWeight = 220
////                self.fitness.getAllStats { _ in
////
////                }
////            }
//        }
//    }
//}
