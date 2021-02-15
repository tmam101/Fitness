//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI
extension Color {
    static let myGray = Color.init(red: 28/255, green: 29/255, blue: 31/255)
}
struct FitnessView: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var healthKit: MyHealthKit
    
    var body: some View {
        ZStack {
            ProgressCircle().environmentObject(fitness)
                .padding()
                .background(Color.myGray)
            CalorieCircle().environmentObject(healthKit)
                .padding()
                .padding()
            VStack {
//                Text(String(format: "%.2f", healthKit.burned ?? 0))
                Text(String(healthKit.remaining) + " cal ")
                    .foregroundColor(.white)
                    .font(.caption)
//                Text(String(format: "%.2f", healthKit.eaten ?? 0))
//                Text(String(fitness.currentWeight)).foregroundColor(.white)
                Text(String(format: "%.2f", (fitness.startingWeight - fitness.currentWeight)) + " lost")
                    .foregroundColor(.white)
                    .font(.caption)
//                Text(fitness.progressString(from: fitness.progressToWeight) + "% to weight")
//                Text(fitness.progressString(from: fitness.progressToDate) + "% to date")
                let success = fitness.successPercentage
                let successString = success > 0 ?
                    "+" + fitness.progressString(from: success) + "%" :
                    "-" + fitness.progressString(from: 0 - success) + "%"
                Text(successString)
                    .foregroundColor(.white)
                    .font(.caption)
            }
        }
    }
}

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView().environmentObject(FitnessCalculations()).environmentObject(MyHealthKit())
    }
}
