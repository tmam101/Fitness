//
//  TodayViewModel.swift
//  Fitness
//
//  Created by Thomas on 3/31/23.
//

import Foundation

class TodayViewModel: ObservableObject {
    @Published var today: Day
    @Published var environment: AppEnvironmentConfig
    @Published var maxValue: Double = 1000
    @Published var minValue: Double = -1000
    @Published var yValues: [Double] = []
    @Published var deficitPercentage: CGFloat = 0
    @Published var protein: Double = 0
    @Published var proteinPercentage: Double = 0
    @Published var proteinGoalPercentage: CGFloat = 0
    @Published var activeCaloriePercentage: CGFloat = 0
    @Published var averagePercentage: CGFloat = 0
    @Published var weightChangePercentage: CGFloat = 0

    init(today: Day, environment: AppEnvironmentConfig) {
        self.today = today
        self.environment = environment
    }
    
    func reloadToday() {
        Task {
            var today: Day?
            switch environment {
            case .release:
                today = await HealthData.getToday()
            default:
                today = TestData.today
            }
            if let today {
                let maxValue = max(today.surplus, self.maxValue)
                let minValue = min(today.surplus, self.minValue)
                let lineEvery = Double(500)
                let topLine = Int(maxValue - (maxValue.truncatingRemainder(dividingBy: lineEvery)))
                let bottomLine = Int(minValue - (minValue.truncatingRemainder(dividingBy: lineEvery)))
                var yValues: [Double] = []
                for i in stride(from: bottomLine, through: topLine, by: Int(lineEvery)) {
                    yValues.append(Double(i))
                }
                self.yValues = yValues
                self.maxValue = maxValue
                self.minValue = minValue
                
                self.deficitPercentage = today.deficit / 1000
                self.protein = (today.protein * today.caloriesPerGramOfProtein) / today.consumedCalories
                self.proteinPercentage = protein.isNaN ? 0 : protein
                self.proteinGoalPercentage = proteinPercentage / 0.3
                self.activeCaloriePercentage = today.activeCalories / 900
                self.averagePercentage = (deficitPercentage + proteinGoalPercentage + activeCaloriePercentage) / 3
                self.weightChangePercentage = today.expectedWeightChangedBasedOnDeficit / (-2/7)
                self.today = today
            }
        }
    }
}
