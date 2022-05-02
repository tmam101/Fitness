//
//  CalorieManager.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 1/5/22.
//

import Foundation
#if !os(macOS)
import HealthKit
#endif

class CalorieManager {
    var activeCalorieModifier: Double = 1
    var adjustActiveCalorieModifier: Bool = false
    var daysBetweenStartAndNow: Int = 0
    var fitness: FitnessCalculations? = nil
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    var minimumActiveCalories: Double = 200
    var minimumRestingCalories: Double = 2150
    var daysWithTotalDeficits: [Int: Day]? = [:]
    
    //TODO Should this just return weights?
    func getExpectedWeights() async -> [LineGraph.DateAndDouble] {
        let deficits = await self.getIndividualDeficits(forPastDays: daysBetweenStartAndNow)
        var datesAndValues: [LineGraph.DateAndDouble] = []
        for i in 0..<deficits.count {
            let dateIndex = deficits.count - 1 - i
            let date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -dateIndex), to: Date())!)
            let thisDaysDeficit = deficits[dateIndex] ?? 0
            if i == 0 {
                datesAndValues.append(LineGraph.DateAndDouble(date: date, double: thisDaysDeficit))
            } else {
                let previousCumulative = datesAndValues[i-1].double
                datesAndValues.append(LineGraph.DateAndDouble(date: date, double: thisDaysDeficit + previousCumulative))
            }
            if let value = datesAndValues.last {
                print("cumulative deficit: \(value)")
            } else {
                print("cumulative deficit error")
            }
        }
        var expectedWeights: [LineGraph.DateAndDouble] = datesAndValues.map { LineGraph.DateAndDouble(date: $0.date, double: (fitness?.startingWeight ?? 300) - ($0.double / 3500)) }
        expectedWeights = expectedWeights.map { LineGraph.DateAndDouble(date: Date.subtract(days: -1, from: $0.date), double: $0.double)}
        return expectedWeights
    }
    
//    func getdaysWithTotalDeficits() async -> [Int: Day] {
//        let days = await getIndividualStatistics(forPastDays: daysBetweenStartAndNow)
//    }
//
//    func getTotalDeficitByDay(days: [Int:Day]) async -> [Int:Double] {
//        let deficits = days.mapValues { $0.deficit }
//        var datesAndValues: [LineGraph.DateAndDouble] = []
//        for i in 0..<deficits.count {
//            let dateIndex = deficits.count - 1 - i
//            let date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -dateIndex), to: Date())!)
//            let thisDaysDeficit = deficits[dateIndex] ?? 0
//            if i == 0 {
//                datesAndValues.append(LineGraph.DateAndDouble(date: date, double: thisDaysDeficit))
//            } else {
//                let previousCumulative = datesAndValues[i-1].double
//                datesAndValues.append(LineGraph.DateAndDouble(date: date, double: thisDaysDeficit + previousCumulative))
//            }
//            if let value = datesAndValues.last {
//                print("cumulative deficit: \(value)")
//            } else {
//                print("cumulative deficit error")
//            }
//        }
//        var expectedWeights: [LineGraph.DateAndDouble] = datesAndValues.map { LineGraph.DateAndDouble(date: $0.date, double: (fitness?.startingWeight ?? 300) - ($0.double / 3500)) }
//        expectedWeights = expectedWeights.map { LineGraph.DateAndDouble(date: Date.subtract(days: -1, from: $0.date), double: $0.double)}
//        return expectedWeights
//    }
    
    func setup(fitness: FitnessCalculations, daysBetweenStartAndNow: Int, forceLoad: Bool = false) async {
        if let r = Settings.get(key: .resting) as? Double { //todo widget cant access user defaults
            self.minimumRestingCalories = r
        }
        if let active = Settings.get(key: .active) as? Double {
            self.minimumActiveCalories = active
        }
        if let useActiveCalorieModifier = Settings.get(key: .useActiveCalorieModifier) as? Bool {
            self.adjustActiveCalorieModifier = useActiveCalorieModifier
        }
        self.fitness = fitness
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
        if adjustActiveCalorieModifier {
            await setActiveCalorieModifier(1)
//            let tempAverageDeficitSinceStart = await getAverageDeficit(forPast: self.daysBetweenStartAndNow)
//            let activeCalorieModifier = await getActiveCalorieModifier(weightLost: fitness.weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, averageDeficitSinceStart: tempAverageDeficitSinceStart ?? 0.0)
            let startDate = Date.subtract(days: daysBetweenStartAndNow, from: Date())
            let startingWeight = fitness.weight(at: startDate)
            let weightLost = startingWeight - (fitness.weights.first?.weight ?? 0)
            let activeCalorieModifier = await getActiveCalorieModifier(weightLost: weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, forceLoad: forceLoad)
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
    
    private func getDaysFromSettings() -> [Int:Day]? {
        if let data = Settings.get(key: .days) as? Data {
            do {
                let unencoded = try JSONDecoder().decode([Int:Day].self, from: data)
                return unencoded
            } catch {
                print("error getDaysFromSettings")
                return nil
            }
        }
        return nil
    }
    
    func getDays(forceReload: Bool) async -> [Int:Day] {
        // If we've saved all days' info today, only reload today's data
        var days = self.getDaysFromSettings() ?? [:]
        var haveLoadedDaysToday = Date.sameDay(date1: Date(), date2: days[0]?.date ?? Date.distantPast)
        if forceReload { haveLoadedDaysToday = false }
        
        // Catch error where sometimes days will be loaded with empty information. Enforce reloading of days.
        for i in 0..<days.count {
            if days[i]?.consumedCalories == 0 && i < days.count - 2 {
                if days[i+1]?.consumedCalories == 0 &&
                    days[i+2]?.consumedCalories == 0 {
                    haveLoadedDaysToday = false
                    break
                }
            }
        }
        
        if haveLoadedDaysToday && days.count > 5 {
            // Reload this week's calories
            var thisWeek = await getIndividualStatistics(forPastDays: 7)
            let earliestDeficit = (days[8]?.runningTotalDeficit ?? 0) + (thisWeek[7]?.deficit ?? 0)
            thisWeek[7]?.runningTotalDeficit = earliestDeficit
            for i in stride(from: 6, through: 0, by: -1) {
                let deficit = (thisWeek[i+1]?.runningTotalDeficit ?? 0) + (thisWeek[i]?.deficit ?? 0)
                thisWeek[i]?.runningTotalDeficit = deficit
            }
            for i in 0...7 {
                days[i] = thisWeek[i]
            }
        } else {
            // Reload all days if we haven't loaded any days yet today
            days = await getEveryDay()
        }
        return days
    }
    
    private func getEveryDay() async -> [Int:Day] {
        var dayInformation: [Int:Day] = [:]
        for i in stride(from: daysBetweenStartAndNow, through: 0, by: -1) {
            let active = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            let resting = await sumValueForDay(daysAgo: i, forType: .basalEnergyBurned)
            let realActive = max(self.minimumActiveCalories, active)
            let realResting = max(self.minimumRestingCalories, resting)
            
            let eaten = await sumValueForDay(daysAgo: i, forType: .dietaryEnergyConsumed)
            let deficit = await getDeficitForDay(daysAgo: i) ?? 0
            let date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -i), to: Date())!)
            let runningTotalDeficit = i == daysBetweenStartAndNow ? deficit : dayInformation[i+1]!.runningTotalDeficit + deficit
            let expectedWeight = (fitness?.startingWeight ?? 0) - (i == daysBetweenStartAndNow ? 0 : (dayInformation[i+1]!.runningTotalDeficit / 3500)) //todo delete?
            
            let day = Day(date: date,
                          daysAgo: i,
                          deficit: deficit,
                          activeCalories: realActive,
                          restingCalories: realResting,
                          consumedCalories: eaten,
                          runningTotalDeficit: runningTotalDeficit,
                          expectedWeight: expectedWeight)
            
            //Catch error where sometimes days will be loaded with empty information. Enforce reloading of days.
            if i < daysBetweenStartAndNow - 1 {
                if dayInformation[i]?.consumedCalories == 0 &&
                    dayInformation[i+1]?.consumedCalories == 0 &&
                    dayInformation[i+2]?.consumedCalories == 0 {
                    return [:]
                }
            }
            dayInformation[i] = day
            print("day \(i): \(day)")
            if dayInformation.count == daysBetweenStartAndNow + 1 {
                return dayInformation
            }
        }
        return [:]
    }
    
    func getIndividualStatistics(forPastDays days: Int) async -> [Int:Day] {
        var dayInformation: [Int:Day] = [:]
        // todo running total deficit is accumulating backwards
        for i in 0...days { // todo real active here???????
            let active = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            let resting = await sumValueForDay(daysAgo: i, forType: .basalEnergyBurned)
            let realActive = max(self.minimumActiveCalories, active)
            let realResting = max(self.minimumRestingCalories, resting)
            
            let eaten = await sumValueForDay(daysAgo: i, forType: .dietaryEnergyConsumed)
            let deficit = await getDeficitForDay(daysAgo: i) ?? 0
            let date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -i), to: Date())!)
            let runningTotalDeficit = i == 0 ? deficit : dayInformation[i-1]!.runningTotalDeficit + deficit // TODO: make sure these deficits are correct
            let day = Day(date: date, daysAgo: i, deficit: deficit, activeCalories: realActive, restingCalories: realResting, consumedCalories: eaten, runningTotalDeficit: runningTotalDeficit)
            dayInformation[i] = day
            print("day \(i): \(day)")
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
    
    func getActiveCalorieModifier(weightLost: Double, daysBetweenStartAndNow: Int, forceLoad: Bool = false) async -> Double {
        let individualStatisticsData = Settings.get(key: .individualStatisticsData) as? Data
        var individualStatistics: [Int:Day]? = nil
        if individualStatisticsData == nil || forceLoad {
            individualStatistics = await self.getIndividualStatistics(forPastDays: daysBetweenStartAndNow)
        } else {
            if let unencoded = try? JSONDecoder().decode([Int:Day].self, from: individualStatisticsData!) {
                print(unencoded)
                individualStatistics = unencoded
                if individualStatistics![0]?.date != Calendar.current.startOfDay(for: Date()) {
                    individualStatistics = await self.getIndividualStatistics(forPastDays: daysBetweenStartAndNow)
                }
            }
        }
                
//        let weightLost = fitness?.weightLost ?? 0
        let lastWeight = fitness?.weights.first
        let caloriesLost = weightLost * 3500
        do {
            let encodedData = try JSONEncoder().encode(individualStatistics!)
            Settings.set(key: .individualStatisticsData, value: encodedData)
        } catch { }
        individualStatistics = individualStatistics!.filter {
            let days = $0.key - 1
            let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date())
            let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
            return startDate <= lastWeight?.date ?? Date()
        }
        let active = Array(individualStatistics!.values)
            .map { $0.activeCalories }
            .reduce(0, { x, y in x + y })
//        let deficits = Array(individualStatistics!.values)
//            .map { $0.deficit }
//            .reduce(0, { x, y in x + y })
        let resting = Array(individualStatistics!.values)
            .map { $0.restingCalories }
            .reduce(0, { x, y in x + y })
        let eaten = Array(individualStatistics!.values)
            .map { $0.consumedCalories }
            .reduce(0, { x, y in x + y })
//        let active = await getActiveCaloriesBurned(forPast: daysBetweenStartAndNow)
//        let resting = await sumValue(forPast: daysBetweenStartAndNow, forType: .basalEnergyBurned)
//        let eaten = await sumValue(forPast: daysBetweenStartAndNow, forType: .dietaryEnergyConsumed)
//        let realResting = max(Double(minimumRestingCalories) * Double(daysBetweenStartAndNow), resting) // It's probably because I'm not checking every day for < 200 active cals, I'm just making sure the average is above it
//        let realActive = max(Double(minimumActiveCalories) * Double(daysBetweenStartAndNow), active)
        // todo have to account for minimum values here
        //        (active * x) + resting - eaten = caloriesLost
        //        caloriesLost + eaten = activeX + resting
        //        caloriesLost + eaten - resting = activeX
        //        x = (caloriesLost + eaten - resting) / active
        var modifier = (caloriesLost + eaten - resting) / active
        if !forceLoad {
            if modifier < 0 {
                modifier = await getActiveCalorieModifier(weightLost: weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, forceLoad: true)
            }
        }
        return modifier
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
        let deficit = await getCumulativeDeficit(forPast: days) ?? 0
        let realDays: Double = Double(days == 0 ? 1 : days)
        let average = deficit / realDays
        return average
    }
    
    func getCumulativeDeficit(forPast days: Int) async -> Double? {
        let resting = await getRestingCaloriesBurned(forPast: days)
        let active = await getActiveCaloriesBurned(forPast: days)
        let eaten = await getTotalCaloriesEaten(forPast: days)
        let realDays: Double = Double(days == 0 ? 1 : days)
        let realResting = max(Double(minimumRestingCalories) * realDays, resting)
        let realActive = max(Double(minimumActiveCalories) * realDays, active)
        let deficit = getDeficit(resting: realResting, active: realActive, eaten: eaten)
        print("days ago \(days) cumulative deficit \(deficit)")
        return deficit
    }
    
    func getActiveCaloriesBurned(forPast days: Int) async -> Double {
//        return await max(sumValue(forPast: days, forType: .activeEnergyBurned), Double(days + 1) * minimumActiveCalories) // todo when summing these things, we don't account for the minimum of 200 active calories

        return await sumValue(forPast: days, forType: .activeEnergyBurned) // todo when summing these things, we don't account for the minimum of 200 active calories
    }
    
    func getTotalCaloriesEaten(forPast days: Int) async -> Double {
        return await sumValue(forPast: days, forType: .dietaryEnergyConsumed)
    }
    
    func getRestingCaloriesBurned(forPast days: Int) async -> Double {
//        return await max(sumValue(forPast: days, forType: .basalEnergyBurned), Double(days+1) * minimumActiveCalories)

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
