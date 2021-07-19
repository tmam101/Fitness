//
//  MyHealthKit.swift
//  Fitness
//
//  Created by Thomas Goss on 1/26/21.
//

import Foundation
import HealthKit
import WidgetKit
import SwiftUI

class MyHealthKit: ObservableObject {
    //MARK: PROPERTIES
    var environment: AppEnvironmentConfig?
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    @Published public var fitness = FitnessCalculations(environment: GlobalEnvironment.environment)
    // Deficits
    @Published public var deficitToday: Float = 0
    @Published public var averageDeficitThisWeek: Float = 0
    @Published public var averageDeficitThisMonth: Float = 0
    @Published public var averageDeficitSinceStart: Float = 0
    
    @Published public var deficitToGetCorrectDeficit: Float = 0
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
    @Published public var dailyDeficits: [Int:Float] = [:]
    
    @Published public var workouts: WorkoutInformation = WorkoutInformation(afterDate: "01.23.2021", environment: .debug)

    // Constants 
    let minimumActiveCalories: Float = 200
    let activeCalorieModifier: Double = 0.8
    let minimumRestingCalories: Float = 2300
    let goalDeficit: Float = 1000
    let goalEaten: Float = 1500
    let caloriesInPound: Float = 3500
    let startDateString = "01.23.2021"
    var startDate: Date?
    let endDateString = "05.01.2021"
    let formatter = DateFormatter()
    
    //MARK: INITIALIZATION
    init(environment: AppEnvironmentConfig) {
        self.environment = environment
        switch environment {
        case .release:
            setValues(nil)
        case .debug:
            setValuesDebug(nil)
        }
        
    }
    
    init(environment: AppEnvironmentConfig, _ completion: @escaping ((_ health: MyHealthKit) -> Void)) {
        self.environment = environment
        switch environment {
        case .release:
            setValues(completion)
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
        self.dailyDeficits = [0: Float(300), 1: Float(200), 2:Float(500), 3: Float(1200), 4: Float(-300), 5:Float(500),6: Float(300), 7: Float(200)]
                
        let averageWeightLossSinceStart = (231.8 - Double(221)) / (Double(daysBetweenStartAndNow) / Double(7)) // TODO calculate with real values
        let expectedAverageWeightLossSinceStart = ((averageDeficitSinceStart) / 3500) * 7
        self.averageWeightLossSinceStart = Float(averageWeightLossSinceStart)
        self.expectedAverageWeightLossSinceStart = expectedAverageWeightLossSinceStart
        self.averageDeficitSinceStart = 750
        completion?(self)
    }
    
    func setupDates() {
        guard let startDate = Date.dateFromString(startDateString),
              let endDate = Date.dateFromString(endDateString),
              let daysBetweenStartAndEnd = Date.daysBetween(date1: startDate, date2: endDate),
              let daysBetweenStartAndNow = Date.daysBetween(date1: startDate, date2: Date()),
              let daysBetweenNowAndEnd = Date.daysBetween(date1: Date(), date2: endDate)
        else { return }
        
        self.startDate = startDate
        self.daysBetweenStartAndEnd = daysBetweenStartAndEnd
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
        self.daysBetweenNowAndEnd = daysBetweenNowAndEnd
    }
    
    func getIndividualDeficits(forPastDays days: Int, completion: @escaping ([Int:Float]) -> Void) {
        var deficits: [Int:Float] = [:]
        for i in 0...days {
            self.getDeficitForDay(daysAgo: i) { deficit in
                deficits[i] = deficit
                if deficits.count == days + 1 {
                    completion(deficits)
                }
            }
        }
    }
    
    func setValues(_ completion: ((_ health: MyHealthKit) -> Void)?) {
        setupDates()
        workouts = WorkoutInformation(afterDate: self.startDate ?? Date(), environment: environment ?? .release)
        fitness.getAllStats()
        
        print("setting values")
        
        self.getDeficitToReachIdeal { deficitToReachToday in
        self.getProjectedAverageDeficitForTomorrow(forPast: 6) { averageWeeklyDeficitTomorrow in
        self.getProjectedAverageDeficitForTomorrow(forPast: self.daysBetweenStartAndNow) { averageTotalDeficitTomorrow in
        self.getAverageDeficit(forPast: 7) { averageDeficitThisWeek in
        self.getAverageDeficit(forPast: 30) { averageDeficitThisMonth in
        self.getAverageDeficit(forPast: 0) { averageDeficitToday in
        self.getAverageDeficit(forPast: self.daysBetweenStartAndNow) { averageDeficitSinceStart in
        self.getIndividualDeficits(forPastDays: 7) { individualDeficits in
//        self.getDeficitForDay(daysAgo: 1) { yesterdaysDeficit in
        DispatchQueue.main.async { [self] in
            self.dailyDeficits = individualDeficits
            // Deficits
            self.deficitToday = averageDeficitToday ?? 0
            self.deficitToGetCorrectDeficit = deficitToReachToday ?? 0
            self.averageDeficitThisWeek = averageDeficitThisWeek ?? 0
            self.percentWeeklyDeficit = Int((self.averageDeficitThisWeek / goalDeficit) * 100)
            self.averageDeficitThisMonth = averageDeficitThisMonth ?? 0
            self.percentDailyDeficit = Int((self.deficitToday / self.deficitToGetCorrectDeficit) * 100)
            self.projectedAverageWeeklyDeficitForTomorrow = averageWeeklyDeficitTomorrow ?? 0
            self.projectedAverageTotalDeficitForTomorrow = averageTotalDeficitTomorrow ?? 0
                        
            let expectedAverageWeightLossSinceStart = ((averageDeficitSinceStart ?? 1) / 3500) * 7
            self.averageWeightLossSinceStart = Float(averageWeightLossSinceStart)
            self.expectedAverageWeightLossSinceStart = expectedAverageWeightLossSinceStart
            self.averageDeficitSinceStart = averageDeficitSinceStart ?? 0
            self.expectedWeightLossSinceStart = ((averageDeficitSinceStart ?? 1) * Float(self.daysBetweenStartAndNow)) / Float(3500)
            // todo line graph comparing weight loss to calorie deficit
            completion?(self)
            
        }}}}}}}}}
            }
    
    //MARK: PRIVATE
    private func sumValue(forPast days: Int, forType type: HKQuantityTypeIdentifier, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: type) else {
            print("*** Unable to create a type ***")
            return
        }
        let now = days == 0 ?
            Date() :
            Calendar.current.startOfDay(for: Date())
        let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictEndDate, .strictStartDate])

        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.kilocalorie()))
        }
        healthStore.execute(query)
    }
    
    private func sumValueForDay(daysAgo: Int, forType type: HKQuantityTypeIdentifier, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: type) else {
            print("*** Unable to create a type ***")
            return
        }
        let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -daysAgo), to: Date())!)
        let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startDate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictEndDate, .strictStartDate])

        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.kilocalorie()))
        }
        healthStore.execute(query)
    }
    
    func getActiveCalorieModifier() {
        // todo
    }
    
    func getDeficit(resting: Double, active: Double, eaten: Double) -> Double {
        return (resting + (active * activeCalorieModifier)) - eaten
    }
    
    func getAverageDeficit(forPast days: Int, completion: @escaping ((_ eaten: Float?) -> Void)) {
        self.getRestingCaloriesBurned(forPast: days) { resting in
        self.getActiveCaloriesBurned(forPast: days) { active in
        self.getTotalCaloriesEaten(forPast: days) { eaten in
            let realDays: Double = Double(days == 0 ? 1 : days)
            let realResting = max(Double(self.minimumRestingCalories) * realDays, resting)
            let realActive = max(Double(self.minimumActiveCalories) * realDays, active)
            let deficit = self.getDeficit(resting: realResting, active: realActive, eaten: eaten)
            let average = deficit / realDays
            completion(Float(average))
        }}}
    }
        
    //MARK: BURNED
    
    func getRestingCaloriesBurned(forPast days: Int, completion: @escaping (Double) -> Void) {
        sumValue(forPast: days, forType: .basalEnergyBurned, completion: completion)
    }
    
    func getActiveCaloriesBurned(forPast days: Int, completion: @escaping (Double) -> Void) {
        sumValue(forPast: days, forType: .activeEnergyBurned, completion: completion)
    }
    
    func getAverageCaloriesBurnedThisWeek(completion: @escaping ((_ eaten: Float?) -> Void)) {
        getActiveCaloriesBurned(forPast: 7) { total in
            completion(Float(total) / 7)
        }
    }
    
    func getAverageRestingCaloriesBurnedThisWeek(completion: @escaping ((_ eaten: Float?) -> Void)) {
        getRestingCaloriesBurned(forPast: 7) { total in
            completion(Float(total) / 7)
        }
    }
    
    func getDeficitForDay(daysAgo: Int, completion: @escaping ((_ eaten: Float?) -> Void)) {
        sumValueForDay(daysAgo: daysAgo, forType: .basalEnergyBurned) { resting in
        self.sumValueForDay(daysAgo: daysAgo, forType: .activeEnergyBurned) { active in
        self.sumValueForDay(daysAgo: daysAgo, forType: .dietaryEnergyConsumed) { eaten in
            let realResting = max(resting, 2300)
            let realActive = max(active, 200)
            print("\(daysAgo) days ago: resting: \(realResting) active: \(realActive) eaten: \(eaten)")
            let deficit = self.getDeficit(resting: realResting, active: realActive, eaten: eaten)
            completion(Float(deficit))
        }}}
    }
    
    //MARK: EATEN
    
    func getCaloriesEatenToday(completion: @escaping ((_ eaten: Double?) -> Void)) {
        sumValue(forPast: 0, forType: .dietaryEnergyConsumed, completion: completion)
    }
    
    func getTotalCaloriesEaten(forPast days: Int, completion: @escaping (Double) -> Void) {
        sumValue(forPast: days, forType: .dietaryEnergyConsumed, completion: completion)
    }
    
    func getAverageCaloriesEatenThisWeek(completion: @escaping ((_ eaten: Float?) -> Void)) {
        getTotalCaloriesEaten(forPast: 7) { total in
            completion(Float(total) / 7)
        }
    }
    
    func getDeficitToReachIdeal(completion: @escaping ((_ eaten: Float?) -> Void)) {
        self.getAverageDeficit(forPast: 6) { averageDeficitForPast6Days in
            let plan = (1000*7) - ((averageDeficitForPast6Days ?? 1) * 6)
            completion(plan)
        }
    }
    
    func getProjectedAverageDeficitForTomorrow(forPast days: Int, completion: @escaping ((_ eaten: Float?) -> Void)) {
        self.getAverageDeficit(forPast: days) { pastDeficit in
        self.getAverageDeficit(forPast: 0) { dailyDeficit in
            guard
                let pastDeficit = pastDeficit,
                let dailyDeficit = dailyDeficit else {
                completion(nil)
                return
            }
            let projectedAverageDeficitForTomorrow = ((pastDeficit * Float(days)) + dailyDeficit) / Float((days + 1))
            completion(projectedAverageDeficitForTomorrow)

        }}
    }
    
}
