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
    
    @Published public var averageWeightLossSinceStart: Double = 0
    @Published public var expectedAverageWeightLossSinceStart: Double = 0
    
    @Published public var expectedWeightLossSinceStart: Double = 0
    
    // Days
    @Published public var daysBetweenStartAndEnd: Int = 0
    @Published public var daysBetweenStartAndNow: Int = 0
    @Published public var daysBetweenNowAndEnd: Int = 0
    @Published public var deficitsThisWeek: [Int:Double] = [:]
    @Published public var deficitsThisMonth: [Int:Double] = [:]
    @Published public var dailyActiveCalories: [Int:Double] = [:]
    
    @Published public var workouts: WorkoutInformation = WorkoutInformation(afterDate: "01.23.2021", environment: .debug)
    
    @Published public var activeCalorieModifier: Double = 1
    @Published public var adjustActiveCalorieModifier = true
    @Published public var runs: [Run] = []


    //todo
    @Published public var runClicked: Run = Run(date: Date(), totalDistance: 0, totalTime: 0, averageMileTime: 0, caloriesBurned: 0)
    @Published public var numberOfRuns: Int = UserDefaults.standard.value(forKey: "numberOfRuns") as? Int ?? 0
    
    @Published public var individualStatistics: Days = Days()
    
    // Constants
    let minimumActiveCalories: Double = 200
    let minimumRestingCalories: Double = 2300
    let goalDeficit: Double = 1000
    let goalEaten: Double = 1500
    let caloriesInPound: Double = 3500
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
    
    func setValues(_ completion: ((_ health: MyHealthKit) -> Void)?) async {
//        UserDefaults.standard.set(10, forKey: "numberOfRuns")
//        let x = UserDefaults.standard.value(forKey: "Test")
        loadRunningWorkouts(completion: { [self] workouts, error in
            print(workouts)
            if let workouts = workouts {
                var runs = workouts.map { item -> Run in
                    let duration = Double(item.duration) / 60
                    let distance = item.totalDistance?.doubleValue(for: .mile()) ?? 1
                    let average = duration / distance
                    let indoor = item.metadata?["HKIndoorWorkout"] as! Bool
                    let burned = item.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                    let run = Run(date: item.startDate, totalDistance: distance, totalTime: duration, averageMileTime: average, indoor: indoor, caloriesBurned: burned ?? 0)
                    return run
                }
                print(runs)
                
                // Handle exceptions
                //TODO: Make this something possible from within app settings
                runs = runs.filter { item in
                    let timeIssue = item.totalTime == 49.384849566221234
                    let totalDistance = item.totalDistance == 3.0232693776029285
                    return !(timeIssue && totalDistance)
                }
                
                //TODO Do this somewhere else
                runs = runs.filter { item in
                    !item.indoor
                }
                
                // Handle date
                runs = runs.filter { item in
                    return item.date > self.startDate ?? Date()
                }
                runs = runs.reversed()
                self.runs = runs
            }
//            workouts?.first?.metadata["HK"]
        })
        setupDates()
        workouts = WorkoutInformation(afterDate: self.startDate ?? Date(), environment: environment ?? .release)
        fitness.getAllStats() // make this async?
        
        print("setting values")
        if adjustActiveCalorieModifier {
            self.activeCalorieModifier = 1
            let tempAverageDeficitSinceStart = await getAverageDeficit(forPast: self.daysBetweenStartAndNow)
            let activeCalorieModifier = await getActiveCalorieModifier(weightLost: fitness.weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, averageDeficitSinceStart: tempAverageDeficitSinceStart ?? 0.0)
            self.activeCalorieModifier = activeCalorieModifier
        }
        let averageDeficitSinceStart = await getAverageDeficit(forPast: self.daysBetweenStartAndNow)
        
        let deficitToReachToday = await getDeficitToReachIdeal()
        let averageWeeklyDeficitTomorrow = await getProjectedAverageDeficitForTomorrow(forPast: 6)
        let averageTotalDeficitTomorrow = await getProjectedAverageDeficitForTomorrow(forPast: self.daysBetweenStartAndNow)
        let averageDeficitThisWeek = await getAverageDeficit(forPast: 7)
        
        let averageDeficitThisMonth = await getAverageDeficit(forPast: 30)
        let averageMonthlyDeficitTomorrow = await getProjectedAverageDeficitForTomorrow(forPast: 30)

        let averageDeficitToday = await getAverageDeficit(forPast: 0)
        
        let deficitsThisWeek = await getIndividualDeficits(forPastDays: 7)
        let deficitsThisMonth = await getIndividualDeficits(forPastDays: 30)
        
        let individualActiveCalories = await getIndividualActiveCalories(forPastDays: 7)
        let individualStatistics = await getIndividualStatistics(forPastDays: 7)
        
        DispatchQueue.main.async { [self] in
            self.deficitsThisWeek = deficitsThisWeek
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
            self.averageWeightLossSinceStart = averageWeightLossSinceStart
            self.expectedAverageWeightLossSinceStart = expectedAverageWeightLossSinceStart
            self.averageDeficitSinceStart = averageDeficitSinceStart ?? 0
            self.expectedWeightLossSinceStart = ((averageDeficitSinceStart ?? 1) * Double(self.daysBetweenStartAndNow)) / Double(3500)
            // todo line graph comparing weight loss to calorie deficit
            self.projectedAverageMonthlyDeficitTomorrow = averageMonthlyDeficitTomorrow ?? 0
            self.individualStatistics = individualStatistics
            
            completion?(self)
            
            
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
        self.deficitsThisWeek = [0: Double(300), 1: Double(1000), 2:Double(500), 3: Double(1200), 4: Double(-300), 5:Double(500),6: Double(300), 7: Double(-1000)]
        
        let averageWeightLossSinceStart = (231.8 - Double(221)) / (Double(daysBetweenStartAndNow) / Double(7)) // TODO calculate with real values
        let expectedAverageWeightLossSinceStart = ((averageDeficitSinceStart) / 3500) * 7
        self.averageWeightLossSinceStart = averageWeightLossSinceStart
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
    
    func getIndividualStatistics(forPastDays days: Int) async -> Days {
        var dayInformation = Days()
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
        return Days()

    }
    
    func loadRunningWorkouts(completion:
      @escaping ([HKWorkout]?, Error?) -> Void) {
      //1. Get all workouts with the "Other" activity type.
      let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
      
      //2. Get all workouts that only came from this app.
//        let sourcePredicate = HKQuery.predicateForObjects(from: .)
      
      //3. Combine the predicates into a single predicate.
//      let compound = NSCompoundPredicate(andPredicateWithSubpredicates:
//        [workoutPredicate])
      
      let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                            ascending: false)
        
        let query = HKSampleQuery(
          sampleType: .workoutType(),
          predicate: workoutPredicate,
          limit: 100,
          sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            DispatchQueue.main.async {
              guard
                let samples = samples as? [HKWorkout],
                error == nil
                else {
                  completion(nil, error)
                  return
              }
              
              completion(samples, nil)
            }
          }

        HKHealthStore().execute(query)
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
    
    func getActiveCalorieModifier(weightLost: Double, daysBetweenStartAndNow: Int, averageDeficitSinceStart: Double) async -> Double {
        let weightLost = fitness.weightLost
        let caloriesLost = weightLost * 3500
        let active = await getActiveCaloriesBurned(forPast: daysBetweenStartAndNow)
        let currentCalorieCalculation = Double(daysBetweenStartAndNow) * averageDeficitSinceStart
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
        let realResting = max(resting, 2300)
        let realActive = max(active, 200)
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
}
