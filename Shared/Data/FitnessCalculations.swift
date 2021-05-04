//
//  FitnessCalculations.swift
//  Fitness
//
//  Created by Thomas Goss on 1/20/21.
//

import Foundation
import HealthKit
import WidgetKit

class FitnessCalculations: ObservableObject {
    var environment: AppEnvironmentConfig?
    let startDateString = "01.23.2021"
    let endDateString = "05.01.2021"
    @Published var startingWeight: Float = 231.8
    @Published var currentWeight: Float = 231.8
    @Published var endingWeight: Float = 190
    let formatter = DateFormatter()
    @Published var progressToWeight: Float = 0
    @Published var progressToDate: Float = 0
    @Published var successPercentage: Float = 0
    @Published var weightLost: Float = 0
    @Published public var percentWeightLost: Int = 0
    @Published public var weightToLose: Float = 0
    @Published public var averageWeightLostPerWeek: Float = 0
    @Published public var weights: [Weight] = []
    @Published public var averageWeightLostPerWeekThisMonth: Float = 0
    
    struct Weight {
        var weight: Double
        var date: Date
    }
    

    
    init(environment: AppEnvironmentConfig) {
//        authorizeHealthKit { _, _ in
//
//        }
        self.environment = environment
        switch environment {
        case .release:
            getAllStats()
        case .debug:
            getAllStatsDebug(completion: nil)
        }
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
    
    
    func daysBetween(date1: Date, date2: Date) -> Int? {
        return Calendar
            .current
            .dateComponents([.day], from: date1, to: date2)
            .day
    }
    
    func getProgressToWeight() {
        let lost = startingWeight - currentWeight
        let totalToLose = startingWeight - endingWeight
        let progress = lost / totalToLose
        DispatchQueue.main.async {
            self.progressToWeight = progress
            WidgetCenter.shared.reloadAllTimelines()
            self.getSuccess()
        }
    }
    
    private func getProgressToDate() {
        formatter.dateFormat = "MM.dd.yyyy"
        
        guard
            let endDate = formatter.date(from: endDateString),
            let startDate = formatter.date(from: startDateString)
        else { return }
        
        guard
            let daysBetweenStartAndEnd = daysBetween(date1: startDate, date2: endDate),
            let daysBetweenNowAndEnd = daysBetween(date1: Date(), date2: endDate)
        else { return }
        
        let progress = Float(daysBetweenStartAndEnd - daysBetweenNowAndEnd) / Float(daysBetweenStartAndEnd)
        DispatchQueue.main.async {
            self.progressToDate = progress
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func progressString(from float: Float) -> String {
        return String(format: "%.2f", float * 100)
    }
    
    private func getSuccess() {
        DispatchQueue.main.async {
            self.successPercentage = self.progressToWeight - self.progressToDate
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func getAllStatsDebug(completion: ((_ fitness: FitnessCalculations) -> Void)?) {
        self.progressToWeight = 0.65
        self.successPercentage = 0.75
        self.weightLost = 12
        self.weightToLose = 20
        self.percentWeightLost = 60
        let weeks = 10
        self.averageWeightLostPerWeek = self.weightLost / Float(weeks)
        self.averageWeightLostPerWeekThisMonth = 1.9
        completion?(self)
    }
    
    func getAllStats() {
        getCurrentWeightFromHealthKit { success in
            self.getProgressToWeight()
            self.getProgressToDate()
            self.getSuccess()
            self.weightLost = self.startingWeight - self.currentWeight
            self.weightToLose = self.startingWeight - self.endingWeight
            self.percentWeightLost = Int((self.weightLost / self.weightToLose) * 100)
            guard
                let startDate = self.formatter.date(from: self.startDateString)
            else { return }
            
            guard
                let daysBetweenStartAndNow = self.daysBetween(date1: startDate, date2: Date())
            else { return }
            
            let weeks: Float = Float(daysBetweenStartAndNow) / Float(7)
            self.averageWeightLostPerWeek = self.weightLost / weeks
            self.getWeightFromAMonthAgo()
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
            let dayCount = daysBetween(date1: date, date2: Date())
            else { return }
            print(dayCount)
            if dayCount >= 30 {
                index = i
                days = dayCount
                break
            }
        }
        let newIndex = index - 1
        let newDays = daysBetween(date1: self.weights[newIndex].date, date2: Date())!
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
        self.averageWeightLostPerWeekThisMonth = Float(weeklyAverageThisMonth)
        
    }
    
    func getAllStats(completion: @escaping((_ fitness: FitnessCalculations) -> Void)) {
        getCurrentWeightFromHealthKit { success in
            self.getProgressToWeight()
            self.getProgressToDate()
            self.getSuccess()
            self.weightLost = self.startingWeight - self.currentWeight
            self.weightToLose = self.startingWeight - self.endingWeight
            self.percentWeightLost = Int((self.weightLost / self.weightToLose) * 100)
            completion(self)
        }
    }
    
    // MARK - weight
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    private func authorizeHealthKit(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        if !HKHealthStore.isHealthDataAvailable() {
            return
        }

        let readDataTypes: Set<HKSampleType> = [bodyMassType,
                                                HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                                HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!,
                                                HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!]

        healthStore.requestAuthorization(toShare: nil, read: readDataTypes) { (success, error) in
            completion(success, error)
        }

    }
    
    
    //returns the weight entry in pounds or nil if no data
    private func bodyMass(completion: @escaping ((_ bodyMass: Double?, _ date: Date?) -> Void)) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 31, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            if let results = results as? [HKQuantitySample],
            let result = results.first {
                self.weights = results.map{
                    Weight(weight: $0.quantity.doubleValue(for: HKUnit.pound()), date: $0.endDate)
                }
                let bodyMass = result.quantity.doubleValue(for: HKUnit.pound())
                completion(bodyMass, result.endDate)
                return
            }
            
            //no data
            completion(nil, nil)
        }
        healthStore.execute(query)
    }
    
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
                self.bodyMass(completion: { (weight, weightDate) in
                    if weight != nil {
                        completion(weight, weightDate)
                        return
                    }
                    completion(nil, nil)
                })
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
                self.currentWeight = Float(weight)
                completion(true)
            }
        }
    }
}

