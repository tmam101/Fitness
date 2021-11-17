//
//  MyHealthKit.swift
//  Fitness
//
//  Created by Thomas Goss on 1/26/21.
//

import Foundation
import SwiftUI

class MyHealthKit: ObservableObject {
    //MARK: PROPERTIES
    var environment: AppEnvironmentConfig?
    
    @Published public var fitness = FitnessCalculations(environment: GlobalEnvironment.environment)
    // Deficits
    @Published public var deficitToday: Double = 0
    @Published public var averageDeficitThisWeek: Double = 0
    @Published public var averageDeficitThisMonth: Double = 0
    @Published public var averageDeficitSinceStart: Double = 0
    
    @Published public var deficitToGetCorrectDeficit: Double = 0
    @Published public var percentWeeklyDeficit: Int = 0
    @Published public var percentDailyDeficit: Int = 0
    @Published public var projectedAverageWeeklyDeficitForTomorrow: Float = 0
    @Published public var projectedAverageTotalDeficitForTomorrow: Float = 0
    
    @Published public var averageWeightLossSinceStart: Float = 0
    @Published public var expectedAverageWeightLossSinceStart: Float = 0
    
    @Published public var expectedWeightLossSinceStart: Float = 0
    
    // Days
    @Published public var daysBetweenStartAndEnd: Int = 0
    @Published public var daysBetweenStartAndNow: Int = 0
    @Published public var daysBetweenNowAndEnd: Int = 0
    @Published public var deficitsThisWeek: [Int:Float] = [:]
    
    @Published public var workouts: WorkoutInformation = WorkoutInformation(afterDate: "01.23.2021", environment: .debug)

    
    // Constants
    let minimumActiveCalories: Double = 200
    let minimumRestingCalories: Double = 2300
    let goalDeficit: Double = 1000
    let goalEaten: Double = 1500
    let caloriesInPound: Double = 3500
    let startDateString = "01.23.2021"
    let endDateString = "05.01.2021"
    let formatter = DateFormatter()
    
    //MARK: INITIALIZATION
    init(environment: AppEnvironmentConfig) {
        self.environment = environment
        switch environment {
        case .release:
            return
        case .debug:
            setValuesDebug(nil)
        }
        
    }
    
    init(environment: AppEnvironmentConfig, _ completion: @escaping ((_ health: MyHealthKit) -> Void)) {
        self.environment = environment
        switch environment {
        case .release:
            return
        case .debug:
            setValuesDebug(completion)
        }
    }
    
    func setValuesDebug(_ completion: ((_ health: MyHealthKit) -> Void)?) {
        // Deficits
        self.deficitToday = 800
        self.deficitToGetCorrectDeficit = 1200
        self.averageDeficitThisWeek = 750
        self.percentWeeklyDeficit = Int((self.averageDeficitThisWeek / goalDeficit) * 100)
        self.averageDeficitThisMonth = 850
        self.percentDailyDeficit = Int((self.deficitToday / self.deficitToGetCorrectDeficit) * 100)
        self.projectedAverageWeeklyDeficitForTomorrow = 900
        self.projectedAverageTotalDeficitForTomorrow = 760
        self.deficitsThisWeek = [0: Double(300), 1: Double(200), 2:Double(500), 3: Double(1200), 4: Double(-300), 5:Double(500),6: Double(300), 7: Double(200)]
        
//            let expectedWeightLossThisMonth: Float = ((averageDeficitThisMonth ?? 1) * 30) / caloriesInPound
        
        let averageWeightLossSinceStart = (231.8 - Double(221)) / (Double(daysBetweenStartAndNow) / Double(7)) // TODO calculate with real values
        let expectedAverageWeightLossSinceStart = ((averageDeficitSinceStart) / 3500) * 7
        self.averageWeightLossSinceStart = Float(averageWeightLossSinceStart)
        self.expectedAverageWeightLossSinceStart = expectedAverageWeightLossSinceStart
        self.averageDeficitSinceStart = 750
        completion?(self)
    }
    
    func setupDates() {
        formatter.dateFormat = "MM.dd.yyyy"
        guard
            let endDate = formatter.date(from: endDateString),
            let startDate = formatter.date(from: startDateString)
        else { return }
        
        workouts = WorkoutInformation(afterDate: startDate, environment: environment ?? .release)
        
        guard
            let daysBetweenStartAndEnd = daysBetween(date1: startDate, date2: endDate),
            let daysBetweenStartAndNow = daysBetween(date1: startDate, date2: Date()),
            let daysBetweenNowAndEnd = daysBetween(date1: Date(), date2: endDate)
        else { return }
        
        self.daysBetweenStartAndEnd = daysBetweenStartAndEnd
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
        self.daysBetweenNowAndEnd = daysBetweenNowAndEnd
    }
    
    func daysBetween(date1: Date, date2: Date) -> Int? {
        return Calendar
            .current
            .dateComponents([.day], from: date1, to: date2)
            .day
    }
    
    func getDeficit(resting: Double, active: Double, eaten: Double) -> Double {
        return (resting + active) - eaten
    }
    
}
