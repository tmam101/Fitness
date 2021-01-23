//
//  FitnessCalculations.swift
//  Fitness
//
//  Created by Thomas Goss on 1/20/21.
//

import Foundation
import HealthKit

class FitnessCalculations: ObservableObject {
    let startDateString = "01.20.2021"
    let endDateString = "07.01.2021"
    let startingWeight: Float = 231
    var currentWeight: Float = 200
    let endingWeight: Float = 185
    let formatter = DateFormatter()
    @Published var progressToWeight: Float = 0
    @Published var progressToDate: Float = 0
    @Published var successPercentage: Float = 0
    
    init() {
        getAllStats { _, _, _ in
            
        }
    }
    
    init(completion: @escaping((_ success: Float, _ progressToWeight: Float, _ progressToDate: Float) -> Void)) {
        getAllStats(completion: completion)
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
    
    private func getProgressToWeight() {
        let lost = startingWeight - currentWeight
        let totalToLose = startingWeight - endingWeight
        let progress = lost / totalToLose
        progressToWeight = progress
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
        progressToDate = progress
    }
    
    func progressString(from float: Float) -> String {
        return String(format: "%.2f", float * 100)
    }
    
    private func getSuccess() {
        successPercentage = progressToWeight - progressToDate
    }
    
    func getAllStats(completion: @escaping((_ success: Float, _ progressToWeight: Float, _ progressToDate: Float) -> Void)) {
        getCurrentWeightFromHealthKit { success in
            self.getProgressToWeight()
            self.getProgressToDate()
            self.getSuccess()
            completion(self.successPercentage, self.progressToWeight, self.progressToDate)
        }
    }
    
    func getAllStats(completion: @escaping((_ fitness: FitnessCalculations) -> Void)) {
        getCurrentWeightFromHealthKit { success in
            self.getProgressToWeight()
            self.getProgressToDate()
            self.getSuccess()
            completion(self)
        }
    }
    
    // MARK - weight
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
//    private func authorizeHealthKit(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
//        if health
//        if !HKHealthStore.isHealthDataAvailable() {
//            return
//        }
//
//        let readDataTypes: Set<HKSampleType> = [bodyMassType]
//
//        healthStore.requestAuthorization(toShare: nil, read: readDataTypes) { (success, error) in
//            completion(success, error)
//        }
//
//    }
    
    
    //returns the weight entry in pounds or nil if no data
    private func bodyMass(completion: @escaping ((_ bodyMass: Double?, _ date: Date?) -> Void)) {
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, results, error) in
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
            self.currentWeight = Float(weight)
            completion(true)
        }
    }
}

