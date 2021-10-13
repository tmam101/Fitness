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
    @Published public var dailyActiveCalories: [Int:Float] = [:]
    
    @Published public var workouts: WorkoutInformation = WorkoutInformation(afterDate: "01.23.2021", environment: .debug)
    
    @Published public var activeCalorieModifier: Double = 1
    
    // Constants
    let minimumActiveCalories: Float = 200
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
        Task {
            self.environment = environment
            switch environment {
            case .release:
                await setValues(nil)
            case .debug:
                setValuesDebug(nil)
            }
        }
        
    }
    
    init(environment: AppEnvironmentConfig, _ completion: @escaping ((_ health: MyHealthKit) -> Void)) {
        Task {
            self.environment = environment
            switch environment {
            case .release:
                await setValues(completion)
            case .debug:
                setValuesDebug(completion)
            }
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
        self.dailyDeficits = [0: Float(300), 1: Float(1000), 2:Float(500), 3: Float(1200), 4: Float(-300), 5:Float(500),6: Float(300), 7: Float(-1000)]
        
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
    
    func getIndividualDeficits(forPastDays days: Int) async -> [Int:Float] {
        var deficits: [Int:Float] = [:]
        for i in 0...days {
            let deficit = await getDeficitForDay(daysAgo: i)
            deficits[i] = deficit
            if deficits.count == days + 1 {
                return deficits
            }
        }
        return [0:0]
    }
    
    func getIndividualActiveCalories(forPastDays days: Int) async -> [Int:Float] {
        var activeCalories: [Int:Float] = [:]
        for i in 0...days {
            let active = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            activeCalories[i] = Float(active)
            if activeCalories.count == days + 1 {
                return activeCalories
            }
        }
        return [0:0]
    }
    
    func setValues(_ completion: ((_ health: MyHealthKit) -> Void)?) async {
        self.activeCalorieModifier = 1
        setupDates()
        workouts = WorkoutInformation(afterDate: self.startDate ?? Date(), environment: environment ?? .release)
        fitness.getAllStats() // make this async?
        
        print("setting values")
        let tempAverageDeficitSinceStart = await getAverageDeficit(forPast: self.daysBetweenStartAndNow)
        
        let activeCalorieModifier = await getActiveCalorieModifier(weightLost: fitness.weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, averageDeficitSinceStart: tempAverageDeficitSinceStart ?? 0.0)
        self.activeCalorieModifier = activeCalorieModifier
        let averageDeficitSinceStart = await getAverageDeficit(forPast: self.daysBetweenStartAndNow)

        let deficitToReachToday = await getDeficitToReachIdeal()
        let averageWeeklyDeficitTomorrow = await getProjectedAverageDeficitForTomorrow(forPast: 6)
        let averageTotalDeficitTomorrow = await getProjectedAverageDeficitForTomorrow(forPast: self.daysBetweenStartAndNow)
        let averageDeficitThisWeek = await getAverageDeficit(forPast: 7)
        let averageDeficitThisMonth = await getAverageDeficit(forPast: 30)
        let averageDeficitToday = await getAverageDeficit(forPast: 0)
        let individualDeficits = await getIndividualDeficits(forPastDays: 7)
        let individualActiveCalories = await getIndividualActiveCalories(forPastDays: 7)
        
        DispatchQueue.main.async { [self] in
            self.dailyDeficits = individualDeficits
            self.dailyActiveCalories = individualActiveCalories
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
            
            
        }
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
    
    private func sumValueForDay(daysAgo: Int, forType type: HKQuantityTypeIdentifier) async -> Double {
        return await withUnsafeContinuation { continuation in
            guard let quantityType = HKObjectType.quantityType(forIdentifier: type) else {
                print("*** Unable to create a type ***")
                continuation.resume(returning: 0.0)
                return
            }
            let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -daysAgo), to: Date())!)
            let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startDate)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictEndDate, .strictStartDate])
            
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: HKUnit.kilocalorie()))
            }
            healthStore.execute(query)
        }
    }
    
    func getActiveCalorieModifier(weightLost: Float, daysBetweenStartAndNow: Int, averageDeficitSinceStart: Float) async -> Double {
        let weightLost = fitness.weightLost
        let caloriesLost = weightLost * 3500
        let currentCalorieCalculation = Float(daysBetweenStartAndNow) * averageDeficitSinceStart
        let modifier = caloriesLost / currentCalorieCalculation
        if modifier == Float.nan || modifier == Float.infinity {
            return 1
        }
        return Double(modifier)
    }
    
    func getDeficit(resting: Double, active: Double, eaten: Double) -> Double {
        return (resting + (active * activeCalorieModifier)) - eaten
    }
    
    //MARK: BURNED
    
    func getDeficitForDay(daysAgo: Int) async -> Float? {
        let resting = await sumValueForDay(daysAgo: daysAgo, forType: .basalEnergyBurned)
        let active = await sumValueForDay(daysAgo: daysAgo, forType: .activeEnergyBurned)
        let eaten = await sumValueForDay(daysAgo: daysAgo, forType: .dietaryEnergyConsumed)
        let realResting = max(resting, 2300)
        let realActive = max(active, 200)
        print("\(daysAgo) days ago: resting: \(realResting) active: \(realActive) eaten: \(eaten)")
        let deficit = self.getDeficit(resting: realResting, active: realActive, eaten: eaten)
        return Float(deficit)
    }
    
    //MARK: EATEN
    
    func getCaloriesEatenToday(completion: @escaping ((_ eaten: Double?) -> Void)) {
        sumValue(forPast: 0, forType: .dietaryEnergyConsumed, completion: completion)
    }
    
    func getAverageCaloriesEatenThisWeek() async -> Float? {
        let total = await getTotalCaloriesEaten(forPast: 7)
        return (Float(total) / 7)
    }
    
    func getProjectedAverageDeficitForTomorrow(forPast days: Int) async -> Float? {
        let pastDeficit = await getAverageDeficit(forPast: days)
        let dailyDeficit = await getAverageDeficit(forPast: 0)
        guard
            let pastDeficit = pastDeficit,
            let dailyDeficit = dailyDeficit else {
                return nil
            }
        let projectedAverageDeficitForTomorrow = ((pastDeficit * Float(days)) + dailyDeficit) / Float((days + 1))
        return projectedAverageDeficitForTomorrow
        
    }
    
    // async await
    
    func getDeficitToReachIdeal() async -> Float? {
        let averageDeficitForPast6Days = await getAverageDeficit(forPast: 6)
        let plan = (1000*7) - ((averageDeficitForPast6Days ?? 1) * 6)
        return plan
    }
    
    func getAverageDeficit(forPast days: Int) async -> Float? {
        let resting = await getRestingCaloriesBurned(forPast: days)
        let active = await getActiveCaloriesBurned(forPast: days)
        let eaten = await getTotalCaloriesEaten(forPast: days)
        let realDays: Double = Double(days == 0 ? 1 : days)
        let realResting = max(Double(minimumRestingCalories) * realDays, resting)
        let realActive = max(Double(minimumActiveCalories) * realDays, active)
        let deficit = getDeficit(resting: realResting, active: realActive, eaten: eaten)
        let average = deficit / realDays
        return Float(average)
    }
    
    func getActiveCaloriesBurned(forPast days: Int) async -> Double {
        return await sumValue(forPast: days, forType: .activeEnergyBurned)
    }
    
    func getTotalCaloriesEaten(forPast days: Int) async -> Double {
        return await sumValue(forPast: days, forType: .dietaryEnergyConsumed)
    }
    
    func getRestingCaloriesBurned(forPast days: Int) async -> Double {
        return await sumValue(forPast: days, forType: .basalEnergyBurned)
    }
    
    private func sumValue(forPast days: Int, forType type: HKQuantityTypeIdentifier) async -> Double {
        return await withUnsafeContinuation { continuation in
            guard let quantityType = HKObjectType.quantityType(forIdentifier: type) else {
                print("*** Unable to create a type ***")
                continuation.resume(returning: 0.0)
                return
            }
            let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date())
            let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictEndDate, .strictStartDate])
            
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                
                if error != nil {
                    continuation.resume(returning: 0.0)
                } else {
                    guard let result = result, let sum = result.sumQuantity() else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    continuation.resume(returning: sum.doubleValue(for: HKUnit.kilocalorie()))
                }
            }
            healthStore.execute(query)
        }
    }
}
