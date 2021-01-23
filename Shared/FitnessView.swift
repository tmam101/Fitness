//
//  FitnessView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/22/21.
//

import SwiftUI

struct FitnessView: View {
    @EnvironmentObject var fitness: FitnessCalculations
//    @State var progress: Float = FitnessCalculations().getProgressToWeight()
//    @State var progressTowardDate = FitnessCalculations().getProgressToDate()
    
    var body: some View {
        ZStack {
            ProgressCircle(progress: self.$fitness.progressToWeight, progressTowardDate: self.$fitness.progressToDate, successPercentage: self.$fitness.successPercentage)
                .padding()
                .background(Color.init(red: 28/255, green: 29/255, blue: 31/255))
            VStack {
//                Text(fitness.progressString(from: fitness.progressToWeight) + "% to weight")
//                Text(fitness.progressString(from: fitness.progressToDate) + "% to date")
                let success = fitness.successPercentage
                let successString = success > 0 ?
                    "+" + fitness.progressString(from: success) + "%" :
                    "-" + fitness.progressString(from: 0 - success) + "%"
                Text(successString)
                    .foregroundColor(.white)
            }
        }
    }
}

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView().environmentObject(FitnessCalculations())
    }
}
