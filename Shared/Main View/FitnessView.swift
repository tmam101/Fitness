//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

struct GlobalEnvironment {
    static var environment = AppEnvironmentConfig.release
}

enum AppEnvironmentConfig {
    case debug
    case release
}

struct FitnessView: View {
    @EnvironmentObject var fitness: FitnessCalculations
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
                    .environmentObject(fitness)
                    .frame(minWidth: 0, maxWidth: .infinity)
                
                BarChart()
                    .environmentObject(healthKit)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
                    .background(Color.myGray)
                    .cornerRadius(20)
                
                StatsTitle(title: "Weight Loss")
                StatsRow(text: { WeightLossText() }, rings: { WeightLossRings() })
                    .environmentObject(healthKit)
                    .environmentObject(fitness)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .padding()
        }
    }
}

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView()
            .environmentObject(FitnessCalculations(environment: .debug))
            .environmentObject(MyHealthKit(environment: .debug))
    }
}
