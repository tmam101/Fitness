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

// TODO
public class HealthService {
var environment: AppEnvironmentConfig
    
    init(environment: AppEnvironmentConfig) {
        self.environment = environment
    }
    
    func sumValueForDay() {
        
    }
}

public enum HealthKitType: CaseIterable {
    case dietaryProtein
    case activeEnergyBurned
    case basalEnergyBurned
    case dietaryEnergyConsumed
    
    var value: HKQuantityType? {
        switch self {
        case .dietaryProtein:
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)
        case .activeEnergyBurned:
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        case .basalEnergyBurned:
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)
        case .dietaryEnergyConsumed:
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)
        }
    }
    
    var unit: HKUnit {
        switch self {
        case .dietaryProtein:
                .gram()
        case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed:
                .kilocalorie()
        }
    }
}

// TODO Use or delete
public class HealthKitSomething {
    var type: HealthKitType
    var amount: Decimal
    
    init(type: HealthKitType, amount: Decimal) {
        self.type = type
        self.amount = amount
    }
    
    func healthSample(start: Date = Date(), end: Date = Date()) -> HKQuantitySample? {
        // Ensure start and end come in the proper order, or it will crash
        let dates = [start, end].sorted(.longestAgoToMostRecent)
        guard let start = dates.first, let end = dates.last else { return nil }
        let quantity = HKQuantity(unit: type.unit,
                                  doubleValue: NSDecimalNumber(decimal: amount).doubleValue)
        guard let value = type.value else { return nil }
        let sample = HKQuantitySample(type: value,
                                      quantity: quantity,
                                      start: start,
                                      end: end)
        return sample
    }
}

//TODO: Should calorie information be stored on the collection of days instead? And then we would have a day manager, which would create that day object?
class CalorieManager: ObservableObject {
    
    //MARK: PROPERTIES
    var activeCalorieModifier: Decimal = 1
    var adjustActiveCalorieModifier: Bool = false
    var allowThreeDaysOfFasting = false
    var daysBetweenStartAndNow: Int = 0
    var weightManager: WeightManager? = nil
    var oldestWeight: Weight?
    var newestWeight: Weight?
    var minimumActiveCalories: Decimal = 200
    var minimumRestingCalories: Decimal = 2150
    @Published var goalDeficit: Decimal = 500
    var days: Days = [:]
    var startingWeight: Decimal = 0 // TODO deprecated
    
    @Published public var percentWeeklyDeficit: Int = 0
    @Published public var percentDailyDeficit: Int = 0
    
    //MARK: SETUP
    var healthStorage: HealthStorageProtocol
    
    init(environment: AppEnvironmentConfig) {
        healthStorage = environment.healthStorage
    }
    
    func setup(overrideMinimumRestingCalories: Decimal? = nil, overrideMinimumActiveCalories: Decimal? = nil, shouldGetDays: Bool = true, startingWeight: Decimal, weightManager: WeightManager, daysBetweenStartAndNow: Int, forceLoad: Bool = false) async {
        // Set values from settings
        self.minimumRestingCalories = overrideMinimumRestingCalories ?? Settings.get(key: .resting) as? Decimal ?? self.minimumRestingCalories
        self.minimumActiveCalories = overrideMinimumActiveCalories ?? Settings.get(key: .active) as? Decimal ?? self.minimumActiveCalories
        self.adjustActiveCalorieModifier = Settings.get(key: .useActiveCalorieModifier) as? Bool ?? self.adjustActiveCalorieModifier
        
        self.weightManager = weightManager
        self.goalDeficit = goalDeficit
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
        self.startingWeight = startingWeight
        if shouldGetDays {
            self.days = await getDays(forceReload: true, applyActiveCalorieModifier: self.adjustActiveCalorieModifier)
        }
    }
    
    // TODO why two setup funcs?
    func setup(overrideMinimumRestingCalories: Decimal? = nil, overrideMinimumActiveCalories: Decimal? = nil, shouldGetDays: Bool = true, oldestWeight: Weight, newestWeight: Weight, daysBetweenStartAndNow: Int, forceLoad: Bool = false) async {
        // Set values from settings
        self.minimumRestingCalories = overrideMinimumRestingCalories ?? Settings.get(key: .resting) as? Decimal ?? self.minimumRestingCalories
        self.minimumActiveCalories = overrideMinimumActiveCalories ?? Settings.get(key: .active) as? Decimal ?? self.minimumActiveCalories
        self.adjustActiveCalorieModifier = Settings.get(key: .useActiveCalorieModifier) as? Bool ?? self.adjustActiveCalorieModifier
        
        self.oldestWeight = oldestWeight
        self.newestWeight = newestWeight
        self.goalDeficit = goalDeficit
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
        self.startingWeight = oldestWeight.weight // TODO
        if shouldGetDays {
            self.days = await getDays(forceReload: true, applyActiveCalorieModifier: self.adjustActiveCalorieModifier)
        }
    }
    
    // MARK: GET DAYS
    
    /// Retrieves days in an efficient way. If we've saved all days' info today, only reload this week's days. If not, reload all days.
    func getDays(forceReload: Bool = false, applyActiveCalorieModifier: Bool = false) async -> Days {
        var days: [Int: Day] = self.days
        if days.isEmpty {
            days = Settings.getDays() ?? [:]
        }
//        let needToReloadAllDays = forceReload || catchError(in: days) || days.count < 7
        days = forceReload ? await getEveryDay() : await loadNecessaryDays(days: days)
//        if catchError(in: days) {
//            return [:]
//        }
        Settings.setDays(days: days)
        
        // Apply active calorie modifier if necessary
//        let settingsIndicateActiveCalorieModifier = Settings.get(key: .useActiveCalorieModifier) as? Bool ?? false
//        if false {
////        if applyActiveCalorieModifier || settingsIndicateActiveCalorieModifier {
//            await setActiveCalorieModifier(1)
//            let startDate = Date.subtract(days: daysBetweenStartAndNow, from: Date())
//            let startingWeight = fitness?.weight(at: startDate) ?? 0
//            let weightLost = startingWeight - (fitness?.weights.first?.weight ?? 0)
//            var activeCalorieModifier = await getActiveCalorieModifier(days: days, weightLost: weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, forceLoad: false)
//            activeCalorieModifier = min(1.0, activeCalorieModifier)
//            Settings.set(key: .activeCalorieModifier, value: activeCalorieModifier)
//            for i in stride(from: days.count - 1, through: 0, by: -1) {
//                let newActive = (days[i]?.activeCalories ?? 0) * activeCalorieModifier
//                let difference = (days[i]?.activeCalories ?? 0) - newActive
//                let newTotalDeficit = (days[i]?.deficit ?? 0) - difference
//                days[i]?.activeCalories = newActive
//                days[i]?.deficit = newTotalDeficit
//                if i < days.count - 1 {
//                    let newRunningDeficit = (days[i+1]?.runningTotalDeficit ?? 0) + (days[i]?.deficit ?? 0)
//                    days[i]?.runningTotalDeficit = newRunningDeficit
//                } else {
//                    let newRunningDeficit = (days[i]?.deficit ?? 0)
//                    days[i]?.runningTotalDeficit = newRunningDeficit
//                }
//            }
//        }
        return days
    }
    
    // TODO Does this make sense? Because it goes based off of keys, but those don't change as time goes on
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
            return await reload(days: &days, fromDay: min(daysBetweenStartAndNow, 7))
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
    
    var dietaryProtein: HKQuantityType? {
        return HKObjectType.quantityType(forIdentifier: .dietaryProtein)
    }
    
    /// Get day information for the past amount of days. Runningtotaldeficit will start from the first day here.
    func getDays(forPastDays numberOfDays: Int, dealWithWeights: Bool = true) async -> Days {
        var days: Days = [:]
        for i in 0...numberOfDays {
            days[i] = Day(daysAgo: i)
        }
        await days.forEveryDay(.longestAgoToMostRecent) { [self] day in
            let i = day.daysAgo
            day.protein = await sumValueForDay(daysAgo: i, forType: .dietaryProtein)
            day.measuredActiveCalories = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            day.measuredRestingCalories = await sumValueForDay(daysAgo: i, forType: .basalEnergyBurned)
            day.activeCalories = max(self.minimumActiveCalories, day.measuredActiveCalories)
            day.restingCalories = max(self.minimumRestingCalories, day.measuredRestingCalories)
            
            day.consumedCalories = await sumValueForDay(daysAgo: i, forType: .dietaryEnergyConsumed)
            day.date = Date().subtracting(days: i)
            
            let runningTotalDeficit = i == numberOfDays ? day.deficit : days[i+1]!.runningTotalDeficit + day.deficit
            day.runningTotalDeficit = runningTotalDeficit
        }
        return days
    }
    
//    func catchError() {
        //Catch error where sometimes days will be loaded with empty information. Enforce reloading of days.
        // TODO put somehwere else
//            if !allowThreeDaysOfFasting {
//                if i < daysBetweenStartAndNow - 1 {
//                    if days[i]?.consumedCalories == 0 &&
//                        days[i+1]?.consumedCalories == 0 &&
//                        days[i+2]?.consumedCalories == 0 {
//                        return [:]
//                    }
//                }
//            }
//            print("day \(i): \(day)")
//    }
    
    /// Reload the end of the days list. This takes into account the running total deficit.
    // TODO Test
    func reload(days: inout Days, fromDay daysAgo: Int) async -> Days {
        let reloadedDays = await getDays(forPastDays: daysAgo)
        let earliestDeficit = (days[daysAgo + 1]?.runningTotalDeficit ?? 0) + (reloadedDays[daysAgo]?.deficit ?? 0)
        reloadedDays[daysAgo]?.runningTotalDeficit = earliestDeficit
        reloadedDays[daysAgo]?.expectedWeight = startingWeight - (earliestDeficit / 3500) // TODO Reloaded expected weights are different from the initial calculation
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
//    func catchError(in days: Days) -> Bool {
//        if !allowThreeDaysOfFasting {
//            for i in 0..<days.count {
//                if days[i]?.consumedCalories == 0 && i < days.count - 2 {
//                    if days[i+1]?.consumedCalories == 0 &&
//                        days[i+2]?.consumedCalories == 0 {
//                        return true
//                    }
//                }
//            }
//        }
//        if days.count != self.daysBetweenStartAndNow + 1 {
//            return true
//        }
//        return false
//    }
    
    //MARK: ACTIVE CALORIE MODFIER
    
    // TODO Test, and use
//    func getActiveCalorieModifier(days: Days, weightLost: Decimal, daysBetweenStartAndNow: Int, forceLoad: Bool = false) async -> Decimal {
//        let lastWeight = weightManager?.weights.first
//        let caloriesLost = weightLost * 3500
//        let filtered = days.subset(from: days.oldestDay?.date, through: lastWeight?.date)
//        let active = filtered.sum(property: .activeCalories)
//        let resting = filtered.sum(property: .restingCalories)
//        let eaten = filtered.sum(property: .consumedCalories)
//        
//        var modifier = (caloriesLost + eaten - resting) / active
//        if !forceLoad {
//            if modifier < 0 {
//                modifier = await getActiveCalorieModifier(days: filtered, weightLost: weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, forceLoad: true)
//            }
//        }
//        return modifier
//    }
//    
//    func setActiveCalorieModifier(_ modifier: Decimal) async {
//        return await withUnsafeContinuation { continuation in
//            DispatchQueue.main.async { [self] in
//                self.activeCalorieModifier = modifier
//                continuation.resume()
//            }
//        }
//    }
    
    //MARK: SUM VALUE FOR DAY
    func sumValueForDay(daysAgo: Int, forType type: HealthKitType) async -> Decimal {
        return await withUnsafeContinuation { continuation in
            let predicate = specificDayPredicate(daysAgo: daysAgo)
           
            healthStorage.statisticsQuery(type: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { [self] _, result, _ in
                continuation.resume(returning: convertSumToDecimal(sum: result?.sumQuantity(), type: type))
            }
        }
    }
    
    func pastDaysPredicate(days: Int) -> NSPredicate {
        let endDate = days == 0 ? Date() : Calendar.current.startOfDay(for: Date()) // why?
        let startDate = Date.subtract(days: days, from: endDate)
        return predicate(startDate: startDate, endDate: endDate)
    }
    
    func specificDayPredicate(daysAgo: Int) -> NSPredicate? {
        let startDate = Date.subtract(days: daysAgo, from: Date())
        guard let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startDate) 
        else { return nil }
        return predicate(startDate: startDate, endDate: endDate)
    }
    
    func predicate(startDate: Date, endDate: Date) -> NSPredicate {
        HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictEndDate, .strictStartDate])
    }
    
    func convertSumToDecimal(sum: HKQuantity?, type: HealthKitType) -> Decimal {
        guard let sum, sum.is(compatibleWith: type.unit) else {
            return 0.0
        }
        return Decimal(sum.doubleValue(for: type.unit))
    }
    
    //MARK: SAVING CALORIES EATEN
    
    func saveCaloriesEaten(calories: Decimal) async -> Bool {
        return await withUnsafeContinuation { [self] continuation in
            guard let calorieCountSample = healthSample(amount: calories, type: .dietaryEnergyConsumed) else {
                continuation.resume(returning: false)
                return
            }
            
            healthStorage.save(calorieCountSample) { (success, error) in
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
    
    func healthSample(amount: Decimal, type: HealthKitType, start: Date = Date(), end: Date = Date()) -> HKQuantitySample? {
        // Ensure start and end come in the proper order, or it will crash
        let dates = [start, end].sorted(.longestAgoToMostRecent)
        guard let start = dates.first, let end = dates.last else { return nil }
        let quantity = HKQuantity(unit: type.unit,
                                  doubleValue: Double(amount))
        guard let value = type.value else { return nil }
        let sample = HKQuantitySample(type: value,
                                      quantity: quantity,
                                      start: start,
                                      end: end)
        return sample
    }
}
