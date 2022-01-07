//
//  CalorieManager.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 1/5/22.
//

import Foundation
import HealthKit

class CalorieManager {
    var activeCalorieModifier: Double = 1
    var adjustActiveCalorieModifier: Bool = true
    var daysBetweenStartAndNow: Int = 0
    var fitness: FitnessCalculations? = nil
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    let minimumActiveCalories: Double = 200
    let minimumRestingCalories: Double = 2200
    
    func setup(fitness: FitnessCalculations, daysBetweenStartAndNow: Int) async {
        self.fitness = fitness
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
        if adjustActiveCalorieModifier {
            await setActiveCalorieModifier(1)
            let tempAverageDeficitSinceStart = await getAverageDeficit(forPast: self.daysBetweenStartAndNow)
            let activeCalorieModifier = await getActiveCalorieModifier(weightLost: fitness.weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, averageDeficitSinceStart: tempAverageDeficitSinceStart ?? 0.0)
            await setActiveCalorieModifier(activeCalorieModifier)
        }
    }
   
    func setActiveCalorieModifier(_ modifier: Double) async {
        return await withUnsafeContinuation { continuation in
            DispatchQueue.main.async { [self] in
                self.activeCalorieModifier = modifier
                continuation.resume()
            }
        }
    }
        
    
    func getIndividualDeficits(forPastDays days: Int) async -> [Int:Double] {
        var deficits: [Int:Double] = [:]
        for i in 0...days {
            let deficit = await getDeficitForDay(daysAgo: i)
            deficits[i] = deficit
            if deficits.count == days + 1 {
                return deficits
            }
        }
        return [0:0]
    }
    
    func getIndividualActiveCalories(forPastDays days: Int) async -> [Int:Double] {
        var activeCalories: [Int:Double] = [:]
        for i in 0...days {
            let active = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            activeCalories[i] = active
            if activeCalories.count == days + 1 {
                return activeCalories
            }
        }
        return [0:0]
    }
    
    func getIndividualStatistics(forPastDays days: Int) async -> [Int:Day] {
        var dayInformation: [Int:Day] = [:]
        for i in 0...days {
            let active = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            let deficit = await getDeficitForDay(daysAgo: i) ?? 0
            let eaten = await sumValueForDay(daysAgo: i, forType: .dietaryEnergyConsumed)
            let day = Day(deficit: deficit, activeCalories: active, consumedCalories: eaten)
            dayInformation[i] = day
            if dayInformation.count == days + 1 {
                return dayInformation
            }
        }
        return [:]

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
    
    func sumValueForDay(daysAgo: Int, forType type: HKQuantityTypeIdentifier) async -> Double {
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
    
    //todo debug this. go back to previous commit and see whats different
    func getActiveCalorieModifier(weightLost: Double, daysBetweenStartAndNow: Int, averageDeficitSinceStart: Double) async -> Double {
        let weightLost = fitness?.weightLost ?? 0
        let caloriesLost = weightLost * 3500
        let active = await getActiveCaloriesBurned(forPast: daysBetweenStartAndNow) // todo apply modifier here? 208057
        let currentCalorieCalculation = Double(daysBetweenStartAndNow) * averageDeficitSinceStart // 835200
        let resting = currentCalorieCalculation - active
        // todo the modifier is only supposed to apply to active calories!
        let modifier = (caloriesLost - resting) / active
        if modifier == Double.nan || modifier == Double.infinity {
            return 1
        }
        return Double(modifier)
    }
    
    func getDeficit(resting: Double, active: Double, eaten: Double) -> Double {
        return (resting + (active * activeCalorieModifier)) - eaten
    }
    
    //MARK: BURNED
    
    func getDeficitForDay(daysAgo: Int) async -> Double? {
        let resting = await sumValueForDay(daysAgo: daysAgo, forType: .basalEnergyBurned)
        let active = await sumValueForDay(daysAgo: daysAgo, forType: .activeEnergyBurned)
        let eaten = await sumValueForDay(daysAgo: daysAgo, forType: .dietaryEnergyConsumed)
        let realResting = max(resting, self.minimumRestingCalories)
        let realActive = max(active, self.minimumActiveCalories)
        print("\(daysAgo) days ago: resting: \(realResting) active: \(realActive) eaten: \(eaten)")
        let deficit = self.getDeficit(resting: realResting, active: realActive, eaten: eaten)
        return deficit
    }
    
    //MARK: EATEN
    
    func getCaloriesEatenToday(completion: @escaping ((_ eaten: Double?) -> Void)) {
        sumValue(forPast: 0, forType: .dietaryEnergyConsumed, completion: completion)
    }
    
    func getAverageCaloriesEatenThisWeek() async -> Double? {
        let total = await getTotalCaloriesEaten(forPast: 7)
        return total / 7
    }
    
    func getProjectedAverageDeficitForTomorrow(forPast days: Int) async -> Double? {
        let pastDeficit = await getAverageDeficit(forPast: days)
        let dailyDeficit = await getAverageDeficit(forPast: 0)
        guard
            let pastDeficit = pastDeficit,
            let dailyDeficit = dailyDeficit else {
                return nil
            }
        let projectedAverageDeficitForTomorrow = ((pastDeficit * Double(days)) + dailyDeficit) / (Double(days) + 1)
        return projectedAverageDeficitForTomorrow
        
    }
    
    // async await
    
    func getDeficitToReachIdeal() async -> Double? {
        let averageDeficitForPast6Days = await getAverageDeficit(forPast: 6)
        let plan = (1000*7) - ((averageDeficitForPast6Days ?? 1) * 6)
        return plan
    }
    
    func getAverageDeficit(forPast days: Int) async -> Double? {
        let resting = await getRestingCaloriesBurned(forPast: days)
        let active = await getActiveCaloriesBurned(forPast: days)
        let eaten = await getTotalCaloriesEaten(forPast: days)
        let realDays: Double = Double(days == 0 ? 1 : days)
        let realResting = max(Double(minimumRestingCalories) * realDays, resting)
        let realActive = max(Double(minimumActiveCalories) * realDays, active)
        let deficit = getDeficit(resting: realResting, active: realActive, eaten: eaten)
        let average = deficit / realDays
        return average
    }
    
    func getActiveCaloriesBurned(forPast days: Int) async -> Double {
        return await sumValue(forPast: days, forType: .activeEnergyBurned) // todo when summing these things, we don't account for the minimum of 200 active calories
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
    
    func saveCaloriesEaten(calories: Double) async -> Bool {
        return await withUnsafeContinuation { continuation in
            guard let caloriesEatenType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
                continuation.resume(returning: false)
                return
            }
            
            let calorieCountUnit:HKUnit = HKUnit.kilocalorie()
            let caloriesEatenQuantity = HKQuantity(unit: calorieCountUnit,
                                                   doubleValue: calories)
            
            let calorieCountSample = HKQuantitySample(type: caloriesEatenType,
                                                      quantity: caloriesEatenQuantity,
                                                      start: Date(),
                                                      end: Date())
            
            HKHealthStore().save(calorieCountSample) { (success, error) in
                
                if let error = error {
                    continuation.resume(returning: false)
                    print("Error Saving Steps Count Sample: \(error.localizedDescription)")
                } else {
                    continuation.resume(returning: true)
                    print("Successfully saved Steps Count Sample")
                }
            }
            //
        }
    }
}
