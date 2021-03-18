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
    let startDateString = "01.23.2021"
    let endDateString = "05.01.2021"
    @Published var startingWeight: Float = 231.8
    @Published var currentWeight: Float = 231.8
    @Published var endingWeight: Float = 210
    let formatter = DateFormatter()
    @Published var progressToWeight: Float = 0
    @Published var progressToDate: Float = 0
    @Published var successPercentage: Float = 0
    @Published var weightLost: Float = 0
    @Published public var percentWeightLost: Int = 0
    @Published public var weightToLose: Float = 0
    

    
    init() {
//        authorizeHealthKit { _, _ in
//
//        }
        getAllStats()
    }
    
    init(completion: @escaping((_ fitness: FitnessCalculations) -> Void)) {
        getAllStats(completion: completion)
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
    
    func getAllStats() {
        getCurrentWeightFromHealthKit { success in
            self.getProgressToWeight()
            self.getProgressToDate()
            self.getSuccess()
            self.weightLost = self.startingWeight - self.currentWeight
            self.weightToLose = self.startingWeight - self.endingWeight
            self.percentWeightLost = Int((self.weightLost / self.weightToLose) * 100)
        }
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
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 20, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            if let result = results?.first as? HKQuantitySample {
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

