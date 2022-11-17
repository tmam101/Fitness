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

//TODO: Should calorie information be stored on the collection of days instead? And then we would have a day manager, which would create that day object?
class CalorieManager: ObservableObject {
    
    //MARK: PROPERTIES
    var activeCalorieModifier: Double = 1
    var adjustActiveCalorieModifier: Bool = false
    var allowThreeDaysOfFasting = false
    var daysBetweenStartAndNow: Int = 0
    var fitness: WeightManager? = nil
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    var minimumActiveCalories: Double = 200
    var minimumRestingCalories: Double = 2150
    @Published var goalDeficit: Double = 500
    var days: Days = [:]
    var startingWeight: Double = 0
    
    @Published public var deficitToday: Double = 0
    @Published public var averageDeficitThisWeek: Double = 0
    @Published public var averageDeficitThisMonth: Double = 0
    @Published public var projectedAverageMonthlyDeficitTomorrow: Double = 0
    @Published public var averageDeficitSinceStart: Double = 0
    @Published public var deficitToGetCorrectDeficit: Double = 0
    @Published public var percentWeeklyDeficit: Int = 0
    @Published public var percentDailyDeficit: Int = 0
    @Published public var projectedAverageWeeklyDeficitForTomorrow: Double = 0
    @Published public var projectedAverageTotalDeficitForTomorrow: Double = 0
    @Published public var deficitsThisWeek: [Int:Double] = [:]
    @Published public var dailyActiveCalories: [Int:Double] = [:]
    @Published public var expectedWeights: [DateAndDouble] = []
    
    //MARK: SETUP
    
    func setup(overrideMinimumRestingCalories: Double? = nil, overrideMinimumActiveCalories: Double? = nil, shouldGetDays: Bool = true, startingWeight: Double, fitness: WeightManager, daysBetweenStartAndNow: Int, forceLoad: Bool = false) async {
        // Set values from settings
        self.minimumRestingCalories = overrideMinimumRestingCalories ?? Settings.get(key: .resting) as? Double ?? self.minimumRestingCalories
        self.minimumActiveCalories = overrideMinimumActiveCalories ?? Settings.get(key: .active) as? Double ?? self.minimumActiveCalories
        self.adjustActiveCalorieModifier = Settings.get(key: .useActiveCalorieModifier) as? Bool ?? self.adjustActiveCalorieModifier
        
        self.fitness = fitness
        self.goalDeficit = goalDeficit
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
        self.startingWeight = startingWeight
        if shouldGetDays {
            self.days = await getDays(forceReload: forceLoad, applyActiveCalorieModifier: self.adjustActiveCalorieModifier)
            await setValues(from: days)
        }
    }
    
    func setValues(from days: Days) async {
        if days.count < 30 { return }
        print("days: \(days)")
        self.deficitsThisWeek = days.filter { $0.key < 8 }.mapValues{ $0.deficit }
        self.deficitToday = days[0]?.deficit ?? 0
        self.deficitToGetCorrectDeficit = self.goalDeficit //todo
        self.averageDeficitThisWeek = ((days[1]?.runningTotalDeficit ?? 0) - (days[8]?.runningTotalDeficit ?? 0)) / 7
        self.percentWeeklyDeficit = Int((averageDeficitThisWeek / goalDeficit) * 100)
        self.averageDeficitThisMonth = ((days[1]?.runningTotalDeficit ?? 0) - (days[31]?.runningTotalDeficit ?? 0)) / 30
        self.percentDailyDeficit = percentDailyDeficit
        self.projectedAverageWeeklyDeficitForTomorrow = ((days[0]?.runningTotalDeficit ?? 0) - (days[7]?.runningTotalDeficit ?? 0)) / 7
        self.averageDeficitSinceStart = (days[0]?.runningTotalDeficit ?? 0) / Double(daysBetweenStartAndNow)
        self.projectedAverageMonthlyDeficitTomorrow = ((days[0]?.runningTotalDeficit ?? 0) - (days[30]?.runningTotalDeficit ?? 0)) / 30
        self.expectedWeights = Array(days.values).map { DateAndDouble(date: Date.subtract(days: -1, from: $0.date), double: startingWeight - ($0.runningTotalDeficit / 3500)) }.sorted { $0.date < $1.date }
    }
    
    // MARK: GET DAYS
    
    /// Retrieves days in an efficient way. If we've saved all days' info today, only reload this week's days. If not, reload all days.
    func getDays(forceReload: Bool = false, applyActiveCalorieModifier: Bool = false) async -> Days {
        var days: [Int: Day] = self.days
        if days.isEmpty {
            days = Settings.getDays() ?? [:]
        }
        let needToReloadAllDays = forceReload || catchError(in: days) || days.count < 7
        days = needToReloadAllDays ? await getEveryDay() : await loadNecessaryDays(days: days)
        if catchError(in: days) { return [:] }
        Settings.setDays(days: days)
        
        // Apply active calorie modifier if necessary
        let settingsIndicateActiveCalorieModifier = Settings.get(key: .useActiveCalorieModifier) as? Bool ?? false
        if applyActiveCalorieModifier || settingsIndicateActiveCalorieModifier {
            await setActiveCalorieModifier(1)
            let startDate = Date.subtract(days: daysBetweenStartAndNow, from: Date())
            let startingWeight = fitness?.weight(at: startDate) ?? 0
            let weightLost = startingWeight - (fitness?.weights.first?.weight ?? 0)
            var activeCalorieModifier = await getActiveCalorieModifier(days: days, weightLost: weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, forceLoad: false)
            activeCalorieModifier = min(1.0, activeCalorieModifier)
            Settings.set(key: .activeCalorieModifier, value: activeCalorieModifier)
            for i in stride(from: days.count - 1, through: 0, by: -1) {
                let newActive = (days[i]?.activeCalories ?? 0) * activeCalorieModifier
                let difference = (days[i]?.activeCalories ?? 0) - newActive
                let newTotalDeficit = (days[i]?.deficit ?? 0) - difference
                days[i]?.activeCalories = newActive
                days[i]?.deficit = newTotalDeficit
                if i < days.count - 1 {
                    let newRunningDeficit = (days[i+1]?.runningTotalDeficit ?? 0) + (days[i]?.deficit ?? 0)
                    days[i]?.runningTotalDeficit = newRunningDeficit
                } else {
                    let newRunningDeficit = (days[i]?.deficit ?? 0)
                    days[i]?.runningTotalDeficit = newRunningDeficit
                }
            }
        }
        return days
    }
    
    /// Only load as many new days as necessary, and push the existing days back appropriately.
    private func loadNecessaryDays(days: Days) async -> Days {
        var days = days
        
        let howManyDaysAgoWasLastRecorded: Int? = (Array(days.keys) as [Int])
            .sorted { $0 < $1 }
            .first
        
        guard let howManyDaysAgoWasLastRecorded = howManyDaysAgoWasLastRecorded else {
            return await getDays(forPastDays: daysBetweenStartAndNow)
        }

        // If we've already loaded days today, just reload the last week
        if howManyDaysAgoWasLastRecorded == 0 {
            return await reload(days: &days, fromDay: 7)
        }
        
        // Increment days
        // For example, if we haven't loaded days in two days, days[0] moves to days[2], days[1] moves to days[3], and so forth.
        var newDays: Days = [:]
        for i in 0..<days.count {
            newDays[i+howManyDaysAgoWasLastRecorded] = days[i]
        }
        
        // Reload days until that point
        return await reload(days: &newDays, fromDay: max(7, howManyDaysAgoWasLastRecorded))
    }
    
    /// Retrieve all day information from healthkit.
    private func getEveryDay() async -> Days {
        return await getDays(forPastDays: daysBetweenStartAndNow)
    }
    
    /// Get day information for the past amount of days. Runningtotaldeficit will start from the first day here.
    func getDays(forPastDays days: Int, dealWithWeights: Bool = true) async -> Days {
        var dayInformation: Days = [:]
        for i in stride(from: days, through: 0, by: -1) {
            let active = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            let resting = await sumValueForDay(daysAgo: i, forType: .basalEnergyBurned)
            let realActive = max(self.minimumActiveCalories, active)
            let realResting = max(self.minimumRestingCalories, resting)
            
            let eaten = await sumValueForDay(daysAgo: i, forType: .dietaryEnergyConsumed)
            let deficit = await getDeficitForDay(daysAgo: i) ?? 0
            let date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -i), to: Date())!)
            let runningTotalDeficit = i == days ? deficit : dayInformation[i+1]!.runningTotalDeficit + deficit
            let expectedWeight = dealWithWeights ? ((fitness?.startingWeight ?? 0) - (i == days ? 0 : (dayInformation[i+1]!.runningTotalDeficit / 3500))) : 0 //todo delete?
            let expectedWeightChangedBasedOnDeficit = 0 - (deficit / 3500)
            
            let day = Day(date: date,
                          daysAgo: i,
                          deficit: deficit,
                          activeCalories: realActive,
                          realActiveCalories: active,
                          restingCalories: realResting,
                          realRestingCalories: resting,
                          consumedCalories: eaten,
                          runningTotalDeficit: runningTotalDeficit,
                          expectedWeight: expectedWeight,
                          expectedWeightChangedBasedOnDeficit: expectedWeightChangedBasedOnDeficit)
            
            //Catch error where sometimes days will be loaded with empty information. Enforce reloading of days.
            if !allowThreeDaysOfFasting {
                if i < daysBetweenStartAndNow - 1 {
                    if dayInformation[i]?.consumedCalories == 0 &&
                        dayInformation[i+1]?.consumedCalories == 0 &&
                        dayInformation[i+2]?.consumedCalories == 0 {
                        return [:]
                    }
                }
            }
            dayInformation[i] = day
            print("day \(i): \(day)")
            if dayInformation.count == days + 1 {
                return dayInformation
            }
        }
        return [:]
    }
    
    /// Reload the end of the days list. This takes into account the running total deficit.
    func reload(days: inout Days, fromDay daysAgo: Int) async -> Days {
        var reloadedDays = await getDays(forPastDays: daysAgo)
        let earliestDeficit = (days[daysAgo + 1]?.runningTotalDeficit ?? 0) + (reloadedDays[daysAgo]?.deficit ?? 0)
        reloadedDays[daysAgo]?.runningTotalDeficit = earliestDeficit
        reloadedDays[daysAgo]?.expectedWeight = startingWeight - (earliestDeficit / 3500)
        for i in stride(from: daysAgo - 1, through: 0, by: -1) {
            let deficit = (reloadedDays[i+1]?.runningTotalDeficit ?? 0) + (reloadedDays[i]?.deficit ?? 0)
            reloadedDays[i]?.runningTotalDeficit = deficit
            reloadedDays[i]?.expectedWeight = startingWeight - (deficit / 3500)
        }
        for i in 0...daysAgo {
            days[i] = reloadedDays[i]
        }
        return days
    }
    
    // MARK: CATCH ERRORS
    //TODO: Prevent this error from occurring
    /// Catch error where sometimes days will be loaded with empty information.
    func catchError(in days: Days) -> Bool {
        if !allowThreeDaysOfFasting {
            for i in 0..<days.count {
                if days[i]?.consumedCalories == 0 && i < days.count - 2 {
                    if days[i+1]?.consumedCalories == 0 &&
                        days[i+2]?.consumedCalories == 0 {
                        return true
                    }
                }
            }
        }
        if days.count != self.daysBetweenStartAndNow + 1 {
            return true
        }
        return false
    }
    
    //MARK: ACTIVE CALORIE MODFIER
    
    func getActiveCalorieModifier(days: Days, weightLost: Double, daysBetweenStartAndNow: Int, forceLoad: Bool = false) async -> Double {
        let lastWeight = fitness?.weights.first
        let caloriesLost = weightLost * 3500
        
        let filtered = days.upTo(date: lastWeight?.date ?? Date())
        let active = filtered.sum(property: .activeCalories)
        let resting = filtered.sum(property: .restingCalories)
        let eaten = filtered.sum(property: .consumedCalories)
        
        var modifier = (caloriesLost + eaten - resting) / active
        if !forceLoad {
            if modifier < 0 {
                modifier = await getActiveCalorieModifier(days: filtered, weightLost: weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, forceLoad: true)
            }
        }
        return modifier
    }
    
    func setActiveCalorieModifier(_ modifier: Double) async {
        return await withUnsafeContinuation { continuation in
            DispatchQueue.main.async { [self] in
                self.activeCalorieModifier = modifier
                continuation.resume()
            }
        }
    }
    
    //MARK: GET DEFICIT
    
    func getDeficit(resting: Double, active: Double, eaten: Double) -> Double {
        return (resting + (active * activeCalorieModifier)) - eaten
    }
        
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
    
    //MARK: SUMVALUE
        
    func sumValue(forPast days: Int, forType type: HKQuantityTypeIdentifier) async -> Double {
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
    
    //MARK: SAVING CALORIES EATEN
    
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
                
                if let error {
                    continuation.resume(returning: false)
                    print("Error Saving Steps Count Sample: \(error.localizedDescription)")
                } else {
                    continuation.resume(returning: true)
                    print("Successfully saved Steps Count Sample")
                }
            }
        }
    }
}
