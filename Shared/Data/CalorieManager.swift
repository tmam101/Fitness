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

class CalorieManager: ObservableObject {
    
    //MARK: PROPERTIES
    var activeCalorieModifier: Double = 1
    var adjustActiveCalorieModifier: Bool = false
    var daysBetweenStartAndNow: Int = 0
    var fitness: WeightManager? = nil
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    var minimumActiveCalories: Double = 200
    var minimumRestingCalories: Double = 2150
    @Published var goalDeficit: Double = 500
    var days: [Int: Day] = [:]
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
    @Published public var expectedWeights: [LineGraph.DateAndDouble] = []

    
    //MARK: SETUP
    
    func setup(startingWeight: Double, fitness: WeightManager, daysBetweenStartAndNow: Int, forceLoad: Bool = false) async {
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
        self.goalDeficit = goalDeficit
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
        self.startingWeight = startingWeight
        self.days = await getDays(forceReload: forceLoad, applyActiveCalorieModifier: self.adjustActiveCalorieModifier)
    
        await setValues(from: days)
    }
    
    func setValues(from days: [Int:Day]) async {
        if days.count < 30 { return }
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
        self.expectedWeights = Array(days.values).map { LineGraph.DateAndDouble(date: Date.subtract(days: -1, from: $0.date), double: startingWeight - ($0.runningTotalDeficit / 3500)) }.sorted { $0.date < $1.date }
    }
    
    //MARK: EXPECTED WEIGHTS
    
    //TODO Should this just return weights?
    func getExpectedWeights() async -> [LineGraph.DateAndDouble] {
        let days = await self.getDays(forceReload: false)
        var datesAndValues: [LineGraph.DateAndDouble] = []
        for i in 0..<days.count {
            let dateIndex = days.count - 1 - i
            let date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -dateIndex), to: Date())!)
            let thisDaysDeficit = days[dateIndex]?.deficit ?? 0
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
    
    // MARK: GET DAYS
    
    /// Retrieves days in an efficient way. If we've saved all days' info today, only reload this week's days. If not, reload all days.
    func getDays(forceReload: Bool = false, applyActiveCalorieModifier: Bool = false) async -> [Int:Day] {
        var days: [Int: Day] = self.days
        if days.isEmpty {
            days = Settings.getDays() ?? [:]
        }
        let haveLoadedDaysToday = Date.sameDay(date1: Date(), date2: days[0]?.date ?? Date.distantPast)
        let needToReloadAllDays = forceReload || catchError(in: days) || !haveLoadedDaysToday || days.count < 7
        days = needToReloadAllDays ? await getEveryDay() : await reload(days: &days, fromDay: 7)
        if catchError(in: days) { return [:] }
        
        Settings.setDays(days: days)
        // Active calorie modifier
        let settingsIndicateActiveCalorieModifier = Settings.get(key: .useActiveCalorieModifier) as? Bool ?? false
        if applyActiveCalorieModifier || settingsIndicateActiveCalorieModifier {
            await setActiveCalorieModifier(1)
            let startDate = Date.subtract(days: daysBetweenStartAndNow, from: Date())
            let startingWeight = fitness?.weight(at: startDate) ?? 0
            let weightLost = startingWeight - (fitness?.weights.first?.weight ?? 0)
            let activeCalorieModifier = await getActiveCalorieModifier(days: days, weightLost: weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, forceLoad: false)
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
    
    /// Retrieve all day information from healthkit.
    private func getEveryDay() async -> [Int:Day] {
        return await getDays(forPastDays: daysBetweenStartAndNow)
    }
    
    /// Get day information for the past amount of days. Runningtotaldeficit will start from the first day here.
    func getDays(forPastDays days: Int) async -> [Int:Day] {
        var dayInformation: [Int:Day] = [:]
        for i in stride(from: days, through: 0, by: -1) {
            let active = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            let resting = await sumValueForDay(daysAgo: i, forType: .basalEnergyBurned)
            let realActive = max(self.minimumActiveCalories, active)
            let realResting = max(self.minimumRestingCalories, resting)
            
            let eaten = await sumValueForDay(daysAgo: i, forType: .dietaryEnergyConsumed)
            let deficit = await getDeficitForDay(daysAgo: i) ?? 0
            let date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -i), to: Date())!)
            let runningTotalDeficit = i == days ? deficit : dayInformation[i+1]!.runningTotalDeficit + deficit
            let expectedWeight = (fitness?.startingWeight ?? 0) - (i == days ? 0 : (dayInformation[i+1]!.runningTotalDeficit / 3500)) //todo delete?
            
            let day = Day(date: date,
                          daysAgo: i,
                          deficit: deficit,
                          activeCalories: realActive,
                          realActiveCalories: active,
                          restingCalories: realResting,
                          realRestingCalories: resting,
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
            if dayInformation.count == days + 1 {
                return dayInformation
            }
        }
        return [:]
    }
    
    /// Reload the end of the days list. This takes into account the running total deficit.
    func reload(days: inout [Int:Day], fromDay daysAgo: Int) async -> [Int:Day] {
        var reloadedDays = await getDays(forPastDays: daysAgo)
        let earliestDeficit = (days[daysAgo + 1]?.runningTotalDeficit ?? 0) + (reloadedDays[daysAgo]?.deficit ?? 0)
        reloadedDays[daysAgo]?.runningTotalDeficit = earliestDeficit
        for i in stride(from: daysAgo - 1, through: 0, by: -1) {
            let deficit = (reloadedDays[i+1]?.runningTotalDeficit ?? 0) + (reloadedDays[i]?.deficit ?? 0)
            reloadedDays[i]?.runningTotalDeficit = deficit
        }
        for i in 0...daysAgo {
            days[i] = reloadedDays[i]
        }
        return days
    }
    
    // MARK: CATCH ERRORS
    //TODO: Prevent this error from occurring
    /// Catch error where sometimes days will be loaded with empty information.
    func catchError(in days: [Int:Day]) -> Bool {
        for i in 0..<days.count {
            if days[i]?.consumedCalories == 0 && i < days.count - 2 {
                if days[i+1]?.consumedCalories == 0 &&
                    days[i+2]?.consumedCalories == 0 {
                    return true
                }
            }
        }
        return false
    }
    
    //MARK: ACTIVE CALORIE MODFIER
    
    func getActiveCalorieModifier(days: [Int:Day], weightLost: Double, daysBetweenStartAndNow: Int, forceLoad: Bool = false) async -> Double {
        let lastWeight = fitness?.weights.first
        let caloriesLost = weightLost * 3500
        
        let filtered = days.filter {
            let days = $0.key - 1
            let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date())
            let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
            return startDate <= lastWeight?.date ?? Date()
        }
        let active = Array(filtered.values)
            .map { $0.activeCalories }
            .reduce(0, { x, y in x + y })
        let resting = Array(filtered.values)
            .map { $0.restingCalories }
            .reduce(0, { x, y in x + y })
        let eaten = Array(filtered.values)
            .map { $0.consumedCalories }
            .reduce(0, { x, y in x + y })
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
                
                if let error = error {
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
