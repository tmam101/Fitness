//
//  FitnessCalculations.swift
//  Fitness
//
//  Created by Thomas Goss on 1/20/21.
//

import Foundation
#if !os(macOS)
import HealthKit
#endif
#if !os(watchOS)
import WidgetKit
#endif

class FitnessCalculations: ObservableObject {
    var environment: AppEnvironmentConfig?
    let startDateString = "01.23.2021"
    let endDateString = "05.01.2021"
    @Published var startingWeight: Double = 231.8
    @Published var currentWeight: Double = 231.8
    @Published var endingWeight: Double = 190
    @Published var progressToWeight: Double = 0
    @Published var weightLost: Double = 0
    @Published public var percentWeightLost: Int = 0
    @Published public var weightToLose: Double = 0
    @Published public var averageWeightLostPerWeek: Double = 0
    @Published public var weights: [Weight] = []
    @Published public var averageWeightLostPerWeekThisMonth: Double = 0
    
    @Published var shouldShowBars = true
    

    
    init(environment: AppEnvironmentConfig) {
        self.environment = environment
        switch environment {
            //        case .release:
            //            authorizeHealthKit { _, _ in
            //
            //            }
            //            getAllStats()
        case .debug:
            getAllStatsDebug(completion: nil)
        default:
            return
        }
    }
    
    init() {
//        authorizeHealthKit { _, _ in
//            //
//        }
    }
    
    init(environment: AppEnvironmentConfig, completion: @escaping((_ fitness: FitnessCalculations) -> Void)) {
        self.environment = environment
        switch environment {
        case .release:
            getAllStats(completion: completion)
        case .debug:
            getAllStatsDebug(completion: completion)
        }
    }
    
    func getProgressToWeight() {
        let lost = startingWeight - currentWeight
        let totalToLose = startingWeight - endingWeight
        let progress = lost / totalToLose
        DispatchQueue.main.async {
            self.progressToWeight = progress
#if !os(watchOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }
    
    func progressString(from float: Double) -> String {
        return String(format: "%.2f", float * 100)
    }
    
    func getAllStatsDebug(completion: ((_ fitness: FitnessCalculations) -> Void)?) {
        self.progressToWeight = 0.65
        self.weightLost = 12
        self.weightToLose = 20
        self.percentWeightLost = 60
        let weeks = 10
        self.averageWeightLostPerWeek = self.weightLost / Double(weeks)
        self.averageWeightLostPerWeekThisMonth = 1.9
        completion?(self)
    }
    
    func getAllStats() async {
        return await withUnsafeContinuation { continuation in
            getCurrentWeightFromHealthKit { success in
                self.startingWeight = self.weights.last?.weight ?? self.startingWeight
                
                self.getProgressToWeight()
                self.weightLost = self.startingWeight - self.currentWeight
                self.weightToLose = self.startingWeight - self.endingWeight
                self.percentWeightLost = Int((self.weightLost / self.weightToLose) * 100)
                guard
                    let startDate = Date.dateFromString(self.startDateString)
                else { return }
                
                guard
                    let daysBetweenStartAndNow = Date.daysBetween(date1: startDate, date2: Date())
                else { return }
//                self.weight(at: Date.dateFromString("11.25.2021") ?? Date())
                
                let weeks: Double = Double(daysBetweenStartAndNow) / Double(7)
                self.averageWeightLostPerWeek = self.weightLost / weeks
                //            self.getWeightFromAMonthAgo()
                continuation.resume()
            }
        }
    }
    
    func getWeightFromAMonthAgo() {
        var index: Int = 0
        var days: Int = 0
        var finalWeight: Weight
        
        for i in stride(from: 0, to: self.weights.count, by: 1) {
            let weight = self.weights[i]
            let date = weight.date
            guard
                let dayCount = Date.daysBetween(date1: date, date2: Date())
            else {
                print("Date that's fucked: \(date)")
                return
            }
            print("dayCount: \(dayCount)")
            if dayCount >= 30 {
                index = i
                days = dayCount
                break
            }
        }
        let newIndex = index - 1
        print(newIndex)
        print(weights)
        print(weights.count)
        let newDays = Date.daysBetween(date1: self.weights[newIndex].date, date2: Date())!
        let between1 = abs(days - 30)
        let between2 = abs(newDays - 30)
        
        if between1 <= between2 {
            finalWeight = self.weights[index]
        } else {
            finalWeight = self.weights[newIndex]
            days = newDays
        }
        let difference = finalWeight.weight - self.weights.first!.weight
        let weeklyAverageThisMonth = (difference / Double(days)) * Double(7)
        self.averageWeightLostPerWeekThisMonth = Double(weeklyAverageThisMonth)
        
    }
    
    func weight(at date: Date) -> Double {
        let d = Date.startOfDay(date)
        var weight1: Weight?
        var weight2: Weight?
        
        for i in stride(from: 0, to: self.weights.count, by: 1) {
            let w = Date.startOfDay(weights[i].date)
            if w == d {
                return weights[i].weight
            }
            if Date.startOfDay(weights[0].date) < d {
                return weights[0].weight
            }
            if w < d {
                weight1 = weights[i]
                weight2 = weights[i-1]
                break
            }
        }
        guard let weight1 = weight1, let weight2 = weight2 else { return 0 }
//        let maxWeight = max(weight1.weight, weight2.weight)
//        let minWeight = min(weight1.weight, weight2.weight)
        let weightDifference = weight1.weight - weight2.weight
        let dayDifferenceBetweenWeights = Date.daysBetween(date1: weight1.date, date2: weight2.date) ?? 0
        let dayDifferenceBetweenWeightAndDate = Date.daysBetween(date1: weight1.date, date2: date) ?? 0
        let proportion = weightDifference * (Double(dayDifferenceBetweenWeightAndDate) / Double(dayDifferenceBetweenWeights))
        let weightAtDate = weight1.weight - proportion
        return weightAtDate
    }
    
    func getAllStats(completion: @escaping((_ fitness: FitnessCalculations) -> Void)) {
        getCurrentWeightFromHealthKit { success in
//            self.startingWeight = self.weights.last?.weight ?? self.startingWeight
            
            self.getProgressToWeight()
            self.weightLost = self.startingWeight - self.currentWeight
            self.weightToLose = self.startingWeight - self.endingWeight
            self.percentWeightLost = Int((self.weightLost / self.weightToLose) * 100)
            completion(self)
        }
    }
    
    // MARK - weight
    #if !os(macOS)
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    func authorizeHealthKit(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        if !HKHealthStore.isHealthDataAvailable() {
            return
        }

        let readDataTypes: Swift.Set<HKSampleType>? = [bodyMassType,
                                                HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                                HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!,
                                                HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
                                                       HKSampleType.workoutType(),
                                                       HKSampleType.quantityType(forIdentifier: .heartRate)!,
                                                       HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!]
        let writeDataTypes: Swift.Set<HKSampleType>? = [
                                                        HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
                                                               ]

        healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes) { (success, error) in
            completion(success, error)
        }

    }
    //returns the weight entry in pounds or nil if no data
    private func bodyMass(completion: @escaping ((_ bodyMass: Double?, _ date: Date?) -> Void)) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 3000, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            if let results = results as? [HKQuantitySample],
            let result = results.first {
                self.weights = results
                    .map{ Weight(weight: $0.quantity.doubleValue(for: HKUnit.pound()), date: $0.endDate) }
                    .filter { $0.date > Date.dateFromString(self.startDateString)!}
                print(self.weights)
//                    .sorted(by: { $0.date < $1.date })
//                Weight.weightBetweenTwoWeights(date: self.weights.first?.date.advanced(by: (24 * 60 * 60 * 4)) ?? Date(), weight1: self.weights.first, weight2: self.weights[1])
//                Weight.closestTwoWeightsToDate(weights: self.weights, date: Date.dateFromString(month: "04", day: "04", year: "2021") ?? Date())
                let bodyMass = result.quantity.doubleValue(for: HKUnit.pound())
                completion(bodyMass, result.endDate)
                return
            }
            
            //no data
            completion(nil, nil)
        }
        healthStore.execute(query)
    }
    #endif
    
//    func getWeights(_ weights: [HKSample]?, _ offset: Int, amount: Int, completion: @escaping ((_ weights: [HKSample]?) -> Void)) {
//    func getWeights(amount: Int, completion: @escaping ((_ weights: [HKSample]?) -> Void)) {
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
//        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: amount * 3, sortDescriptors: [sortDescriptor]) { (query, results, error) in
//            guard let results = results else {
//                completion(nil)
//                return
//            }
//            var n: [HKSample]? = []
//            for x in results {
//                if !((x as? HKQuantitySample)?.description.contains("MyFitnessPal") ?? true) {
//                    n?.append(x)
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
    
    private func getWeight(completion: @escaping ((_ weight: Double?, _ date: Date?) -> Void)) {
//        authorizeHealthKit { (success, error) in
//            if success {
        #if !os(macOS)
                self.bodyMass(completion: { (weight, weightDate) in
                    if weight != nil {
                        completion(weight, weightDate)
                        return
                    }
                    completion(nil, nil)
                })
        #else
        completion(210, Date())
        #endif
//            }
//            completion(nil, nil)
//        }
    }
    
    private func getCurrentWeightFromHealthKit(completion: @escaping ((_ success: Bool) -> Void)) {
        getWeight { weight, date in
            guard let weight = weight else {
                completion(false)
                return
            }
            DispatchQueue.main.async {
                self.currentWeight = weight
                completion(true)
            }
        }
    }
}

