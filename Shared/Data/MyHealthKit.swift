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

//struct DayAndDeficit {
//    var dailyDeficits: [Int:CGFloat] = [:]
//    var orderedDeficits: [CGFloat] {
//        var x: [CGFloat] = []
//        let size = dailyDeficits.count
//        for i in 0..<size {
//            x.append(dailyDeficits[i] ?? 0)
//        }
//        return x
//    }
////    func sort() {
////        let size = dailyDeficits.count
////        for i in 0..<size {
////            print(i)
////        }
////    }
//}

class MyHealthKit: ObservableObject {
    //MARK: PROPERTIES
    var environment: AppEnvironmentConfig?
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
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
    
    // Days
    @Published public var daysBetweenStartAndEnd: Int = 0
    @Published public var daysBetweenStartAndNow: Int = 0
    @Published public var daysBetweenNowAndEnd: Int = 0
    @Published public var dailyDeficits0: [Int:Float] = [:]
    @Published public var dailyDeficits: [Int:Float] = [:]
    
    @Published public var workouts: Workouts = []
    @Published public var benchORM: Float = 0.0
    @Published public var squatORM: Float = 0.0

    
    // Constants 
    let minimumActiveCalories: Float = 200
    let minimumRestingCalories: Float = 2300
    let goalDeficit: Float = 1000
    let goalEaten: Float = 1500
    let caloriesInPound: Float = 3500
    let startDateString = "01.23.2021"
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
        
        guard
            let daysBetweenStartAndEnd = daysBetween(date1: startDate, date2: endDate),
            let daysBetweenStartAndNow = daysBetween(date1: startDate, date2: Date()),
            let daysBetweenNowAndEnd = daysBetween(date1: Date(), date2: endDate)
        else { return }
        
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
    
    private func setValues(_ completion: ((_ health: MyHealthKit) -> Void)?) {
        setupDates()
        
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
            
//            let expectedWeightLossThisMonth: Float = ((averageDeficitThisMonth ?? 1) * 30) / caloriesInPound
            
            let averageWeightLossSinceStart = (231.8 - Double(221)) / (Double(daysBetweenStartAndNow) / Double(7)) // TODO calculate with real values
            let expectedAverageWeightLossSinceStart = ((averageDeficitSinceStart ?? 1) / 3500) * 7
            self.averageWeightLossSinceStart = Float(averageWeightLossSinceStart)
            self.expectedAverageWeightLossSinceStart = expectedAverageWeightLossSinceStart
            self.averageDeficitSinceStart = averageDeficitSinceStart ?? 0
            //            let d = yesterdaysDeficit
            //            LineGraph.xtoy(weights: width: 200, height: 200)
            if let filepath = Bundle.main.path(forResource: "strong", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: filepath), options: .mappedIfSafe)
                    let workoutjson = try JSONDecoder().decode(Workouts.self, from: data)
                    self.workouts = workoutjson
                    self.benchORM = Float(workouts.filter { $0.exerciseName.rawValue.contains("Bench")}.last?.oneRepMax() ?? 0.0)
                    self.squatORM = Float(workouts.filter { $0.exerciseName.rawValue.contains("Squat")}.last?.oneRepMax() ?? 0.0)
    
                } catch {
                    // handle error
                }
            }
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
        var startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -daysAgo), to: Date())!)
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
    
    func daysBetween(date1: Date, date2: Date) -> Int? {
        return Calendar
            .current
            .dateComponents([.day], from: date1, to: date2)
            .day
    }
    
    func getDeficit(resting: Double, active: Double, eaten: Double) -> Double {
        return (resting + active) - eaten
    }
    
    func getAverageDeficit(forPast days: Int, completion: @escaping ((_ eaten: Float?) -> Void)) {
        self.getRestingCaloriesBurned(forPast: days) { resting in
        self.getActiveCaloriesBurned(forPast: days) { active in
        self.getTotalCaloriesEaten(forPast: days) { eaten in
            let realDays: Double = Double(days == 0 ? 1 : days)
            let realResting = max(Double(self.minimumRestingCalories) * realDays, resting)
            let realActive = max(Double(self.minimumActiveCalories) * realDays, active)
//            let deficit = (resting + active) - eaten
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
    
//    func getAverageDeficitThisMonth(completion: @escaping ((_ eaten: Float?) -> Void)) {
//        self.getRestingCaloriesBurned(forPast: 30) { resting in
//        self.getActiveCaloriesBurned(forPast: 30) { active in
//        self.getTotalCaloriesEaten(forPast: 30) { eaten in
//            let deficit = (resting + active) - eaten
//            let average = deficit / 30
//            completion(Float(average))
//        }}}
//    }
    
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
    
//    func netAmountToEat(completion: @escaping ((_ eaten: Float?) -> Void)) {
//        self.getTotalCaloriesEaten(forPast: 6) { eaten in
//            self.getActiveCaloriesBurned(forPast: 6) { burned in
//                let net = eaten - burned
//                let val = (1500*7) - net
//                self.getActiveCaloriesBurnedToday { burnedToday in
//                    let r = Float(val) + Float(burnedToday ?? 0)
//                    completion(r > 0 ? r : 0)
//                }
//            }
//        }
//    }
    
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
    
    //MARK: WEIGHT
    
//    func getWeights(amount: Int, completion: @escaping ((_ weights: [HKQuantitySample]?) -> Void)) {
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
//        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: amount * 3, sortDescriptors: [sortDescriptor]) { (query, results, error) in
//            guard let results = results else {
//                completion(nil)
//                return
//            }
//            var n: [HKQuantitySample]? = []
//            for x in results {
//                if !((x as? HKQuantitySample)?.description.contains("MyFitnessPal") ?? true) {
//                    n?.append(x as! HKQuantitySample)
//                    if n?.count == amount {
//                        completion(n)
//                        return
//                    }
//                }
//            }
//            completion(n)
//        }
//        healthStore.execute(query)
//    }
    
}
