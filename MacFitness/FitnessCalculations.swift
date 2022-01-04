//
//  FitnessCalculations.swift
//  Fitness
//
//  Created by Thomas Goss on 1/20/21.
//

import Foundation
import WidgetKit

class FitnessCalculations: ObservableObject {
    var environment: AppEnvironmentConfig?
    let startDateString = "01.23.2021"
    let endDateString = "05.01.2021"
    @Published var startingWeight: Double = 231.8
    @Published var currentWeight: Double = 231.8
    @Published var endingWeight: Double = 190
    let formatter = DateFormatter()
    @Published var progressToWeight: Double = 0
    @Published var progressToDate: Double = 0
    @Published var successPercentage: Double = 0
    @Published var weightLost: Double = 0
    @Published public var percentWeightLost: Int = 0
    @Published public var weightToLose: Double = 0
    @Published public var averageWeightLostPerWeek: Double = 0
    @Published public var weights: [Weight] = []
    @Published public var averageWeightLostPerWeekThisMonth: Double = 0
    
    @Published var shouldShowBars = true

    
    struct Weight {
        var weight: Double
        var date: Date
    }
    

    
    init(environment: AppEnvironmentConfig) {
        self.environment = environment
        switch environment {
        case .release:
            return
        case .debug:
            getAllStatsDebug(completion: nil)
        }
    }
    
    init(environment: AppEnvironmentConfig, completion: @escaping((_ fitness: FitnessCalculations) -> Void)) {
        self.environment = environment
        switch environment {
        case .release:
            return
        case .debug:
            getAllStatsDebug(completion: completion)
        }
    }
    
    
    func daysBetween(date1: Date, date2: Date) -> Int? {
        return Calendar
            .current
            .dateComponents([.day], from: date1, to: date2)
            .day
    }
    
    func getProgressToWeight() {
        let lost = startingWeight - currentWeight
        let totalToLose = startingWeight - endingWeight
        let progress = lost / totalToLose
        DispatchQueue.main.async {
            self.progressToWeight = progress
//            WidgetCenter.shared.reloadAllTimelines()
            self.getSuccess()
        }
    }
    
    private func getProgressToDate() {
        formatter.dateFormat = "MM.dd.yyyy"
        
        guard
            let endDate = formatter.date(from: endDateString),
            let startDate = formatter.date(from: startDateString)
        else { return }
        
        guard
            let daysBetweenStartAndEnd = daysBetween(date1: startDate, date2: endDate),
            let daysBetweenNowAndEnd = daysBetween(date1: Date(), date2: endDate)
        else { return }
        
        let progress = Float(daysBetweenStartAndEnd - daysBetweenNowAndEnd) / Float(daysBetweenStartAndEnd)
        DispatchQueue.main.async {
            self.progressToDate = progress
//            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func progressString(from float: Double) -> String {
        return String(format: "%.2f", float * 100)
    }
    
    private func getSuccess() {
        DispatchQueue.main.async {
            self.successPercentage = self.progressToWeight - self.progressToDate
//            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func getAllStatsDebug(completion: ((_ fitness: FitnessCalculations) -> Void)?) {
        self.progressToWeight = 0.65
        self.successPercentage = 0.75
        self.weightLost = 12
        self.weightToLose = 20
        self.percentWeightLost = 60
        let weeks = 10
        self.averageWeightLostPerWeek = self.weightLost / Float(weeks)
        self.averageWeightLostPerWeekThisMonth = 1.9
        completion?(self)
    }
    
    func getWeightFromAMonthAgo() {
        var index: Int = 0
        var days: Int = 0
        var finalWeight: Weight
        
        for i in stride(from: 0, to: self.weights.count, by: 1) {
            let weight = self.weights[i]
            let date = weight.date
            guard
            let dayCount = daysBetween(date1: date, date2: Date())
            else { return }
            print(dayCount)
            if dayCount >= 30 {
                index = i
                days = dayCount
                break
            }
        }
        let newIndex = index - 1
        let newDays = daysBetween(date1: self.weights[newIndex].date, date2: Date())!
        let between1 = abs(days - 30)
        let between2 = abs(newDays - 30)
        
        if between1 <= between2 {
            finalWeight = self.weights[index]
        } else {
            finalWeight = self.weights[newIndex]
            days = newDays
        }
        let difference = finalWeight.weight - self.weights.first!.weight
        let weeklyAverageThisMonth = (difference / Double(days)) * Double(7)
        self.averageWeightLostPerWeekThisMonth = Float(weeklyAverageThisMonth)
        
    }
}

