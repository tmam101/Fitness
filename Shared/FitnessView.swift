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
    var shouldShowText: Bool = true
    var lineWidth: CGFloat = 10
    var widget: Bool = false
    
    var body: some View {
        let paddingSize = lineWidth + 2
        ScrollView {
        ZStack {
            ProgressCircle(lineWidth: lineWidth).environmentObject(fitness)
                .padding(paddingSize)
                .background(Color.myGray)
            AverageAllTimeCircle(lineWidth: lineWidth).environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
            AverageCircle(lineWidth: lineWidth).environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            CalorieCircle(lineWidth: lineWidth).environmentObject(healthKit)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            if shouldShowText {
                HealthText()
                    .environmentObject(fitness)
                    .environmentObject(healthKit)
            }
        }
            if !widget {
            VStack(alignment: .leading) {
                let calorieWidth = healthKit.averageDeficitSinceStart / 1000
                let weightWidth = healthKit.expectedAverageWeightLossSinceStart / 2
                if (calorieWidth != 0) && (weightWidth != 0) {
                let ratio = weightWidth / calorieWidth
                let ratioInt = Int(ratio * 100)
                let text = "Weight loss is \(ratioInt)% of expected"
                Text(text)
                    .foregroundColor(.green)
                }
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .frame(width: CGFloat(calorieWidth) * 400, height: 10)
                    .foregroundColor(.orange)
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .frame(width: CGFloat(weightWidth) * 400, height: 10)
                    .foregroundColor(.green)
            }
        }
    }
    }
}

struct HealthText: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var healthKit: MyHealthKit
    var percentages: Bool = false
    
    var body: some View {
        let deficitToday: Int = Int(healthKit.deficitToday)
        let idealDeficit: Int = Int(healthKit.deficitToGetCorrectDeficit)
        let averageDeficit: Int = Int(healthKit.averageDeficitThisWeek)
        let totalDeficit: Int = Int(healthKit.averageDeficitSinceStart)
        
        // Non-percentages
        let weightLostString = String(format: "%.2f", fitness.weightLost) + " lost"
        let averageDeficitString = String(averageDeficit) + "/1000 deficit weekly"
        let deficitTodayString = String(deficitToday) + "/" + String(idealDeficit) + " deficit today"
        let totalDeficitString = String(totalDeficit) + "/1000 deficit total"
        // Percentages
        let weightLostPercentString = String(fitness.percentWeightLost) + "% lost"
        let averageDeficitPercentString = String(healthKit.percentWeeklyDeficit) + "% dfct"
        let deficitTodayPercentString = String(healthKit.percentDailyDeficit) + "% dfct tdy"
        
        if !self.percentages {
            VStack(alignment: .leading) {
                Text(weightLostString)
                    .foregroundColor(.green)
                    .font(.subheadline)
                Text(totalDeficitString)
                    .foregroundColor(.orange)
                    .font(.subheadline)
                Text(averageDeficitString)
                    .foregroundColor(.yellow)
                    .font(.subheadline)
                Text(deficitTodayString)
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }
        } else {
            VStack(alignment: .leading) {
                Text(weightLostPercentString)
                    .foregroundColor(.green)
                    .font(.subheadline)
                Text(averageDeficitPercentString)
                    .foregroundColor(.yellow)
                    .font(.subheadline)
                Text(deficitTodayPercentString)
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }
        }
    }
}

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView().environmentObject(FitnessCalculations()).environmentObject(MyHealthKit())
    }
}
