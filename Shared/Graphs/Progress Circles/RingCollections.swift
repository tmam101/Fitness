//
//  RingCollections.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 3/18/21.
//

import Foundation
import SwiftUI

struct OverallRing: View {
    @State var today: Day
    var lineWidth: CGFloat = 10
    var fontSize: CGFloat = 40
    var includeTitle: Bool = true
    var includeSubBody: Bool = true
    var shouldPad: Bool = true
    
    var body: some View {
        let deficitPercentage = today.deficit / 1000
        let protein = (today.protein * today.caloriesPerGramOfProtein) / today.consumedCalories
        let proteinPercentage = protein.isNaN ? 0 : protein
        let proteinGoalPercentage = proteinPercentage / 0.3
        let activeCaloriePercentage = today.activeCalories / 900
        let overallPercentage = (deficitPercentage + proteinGoalPercentage + activeCaloriePercentage) / 3
        let overallItem = RingViewModel(titleText: "Overall Score", bodyText: String(Int(overallPercentage * 100)) + "%", subBodyText: "overall", percentage: overallPercentage, bodyTextColor: .white, gradient: [.yellow, .purple, .orange], lineWidth: lineWidth, fontSize: fontSize, includeTitle: includeTitle, includeSubBody: includeSubBody, shouldPad: shouldPad)

        RingView(vm: overallItem)
//            .mainBackground()
    }
}

struct TodayRingWithMonthly: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth
        
        ZStack() {
            VStack {
                Text("\(Int(healthData.calorieManager.deficitToday))")
                    .foregroundColor(.white)
                    .font(.system(size: 9))
                    .fontWeight(.bold)
                Text("\(Int(healthData.days[0]?.realActiveCalories ?? 200))")
                    .foregroundColor(.orange)
                    .font(.system(size: 8))
                    .fontWeight(.bold)
            }
            MonthlyDeficitCircle(lineWidth: lineWidth / 2)
                .environmentObject(healthData)
//                .padding(paddingSize)
            WeeklyAverageDeficitCircle(lineWidth: lineWidth / 2)
                .environmentObject(healthData)
                .padding(lineWidth / 2 + 1)
//                .padding(paddingSize)
            TodayCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
//                .padding(paddingSize)
                .padding(lineWidth / 2 + 1)
                .padding(paddingSize)

        }
    }
}

struct TodayRing: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10
    
    var body: some View {
        
        ZStack() {
            VStack {
                Text("\(Int(healthData.calorieManager.deficitToday))")
                .foregroundColor(.white)
                .font(.system(size: 11))
            }
            TodayCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
//                .padding(paddingSize)

        }
    }
}

struct DeficitRings: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10
    var useNewDailyCircle = false
    var body: some View {
        let paddingSize = lineWidth + 2
        ZStack() {
            MonthlyDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
            WeeklyAverageDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
            if useNewDailyCircle {
                TodayRing().environmentObject(healthData)
                    .padding(paddingSize)
                    .padding(paddingSize)
                    .padding(paddingSize)
            } else {
                DailyDeficitCircle(lineWidth: lineWidth)
                    .environmentObject(healthData)
                    .padding(paddingSize)
                    .padding(paddingSize)
                    .padding(paddingSize)
            }
        }
    }
}

struct WeightLossRings: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        
        ZStack {
            TotalWeightLossCircle(lineWidth: lineWidth, color: .green3)
                .environmentObject(healthData)
                .padding(paddingSize)
            AverageTotalWeightLossCircle(lineWidth: lineWidth, color: .green2)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
            MonthlyAverageWeightLossCircle(lineWidth: lineWidth, color: .green1)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
        }
    }
}

//struct LiftingRings: View {
//    @EnvironmentObject var healthData: HealthData
//
//    var lineWidth: CGFloat = 10
//    
//    var body: some View {
//        let paddingSize = lineWidth + 2
//        
//        ZStack {
//            BenchPressRing(lineWidth: lineWidth, color: .purple)
//                .environmentObject(healthData.workouts)
//            SquatRing(lineWidth: lineWidth, color: .pink)
//                .environmentObject(healthData.workouts)
//                .padding(paddingSize)
//        }
//    }
//}

struct AllRings: View {
    @EnvironmentObject var healthData: HealthData
    var lineWidth: CGFloat = 10
    
    var body: some View {
        let paddingSize = lineWidth + 2
        
        ZStack {
            AverageTotalDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
            WeeklyAverageDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
            DailyDeficitCircle(lineWidth: lineWidth)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            TotalWeightLossCircle(lineWidth: lineWidth, color: .green3)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            AverageTotalWeightLossCircle(lineWidth: lineWidth, color: .green2)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
            MonthlyAverageWeightLossCircle(lineWidth: lineWidth, color: .green1)
                .environmentObject(healthData)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
                .padding(paddingSize)
        }
    }
}

//struct RingCollections_Previews: PreviewProvider {
//    static var previews: some View {
//        Text("hey")
//    }
//}
//struct RingCollections_Previews: PreviewProvider {
//    static var previews: some View {
//        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
//
//            TodayRingWithMonthly()
//                .environmentObject(HealthData(environment: .debug))
//        }
////        .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 7 - 45 mm"))
//    }
//}
