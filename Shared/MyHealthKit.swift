//
//  MyHealthKit.swift
//  Fitness
//
//  Created by Thomas Goss on 1/26/21.
//

import Foundation
import HealthKit
import WidgetKit

class MyHealthKit: ObservableObject {
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    @Published public var weights: [HKQuantitySample]?
    @Published public var burned: Float?
    @Published public var eaten: Float?
    @Published public var progress: Float?
    @Published public var remaining: Int = 0
    
    init() {
//        getCaloriesBurned { calories in
//            DispatchQueue.main.async {
//                self.burned = calories
//                self.progress = 1500 / (1500 + (self.burned ?? 0))
//                WidgetCenter.shared.reloadAllTimelines()
//            }
//        }
//        getCaloriesEaten { calories in
//            DispatchQueue.main.async {
//                self.eaten = calories
//                self.remaining = Int((self.burned ?? 0) + 1500 - (self.eaten ?? 0))
//                WidgetCenter.shared.reloadAllTimelines()
//            }
//        }
        getCaloriesBurned { burned in
            self.burned = burned
            self.progress = 1500 / (1500 + (self.burned ?? 0))
            self.getCaloriesEaten { eaten in
                self.eaten = eaten
                self.remaining = Int((self.burned ?? 0) + 1500 - (self.eaten ?? 0))
            }
        }
    }
    
    init(_ completion: @escaping ((_ health: MyHealthKit) -> Void)) {
        getCaloriesBurned { burned in
            self.burned = burned
            self.progress = 1500 / (1500 + (self.burned ?? 0))
            self.getCaloriesEaten { eaten in
                self.eaten = eaten
                self.remaining = Int((self.burned ?? 0) + 1500 - (self.eaten ?? 0))
                completion(self)
            }
        }
    }
    
    func getCaloriesBurned(completion: @escaping ((_ burned: Float?) -> Void)) {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: 0, to: now)!
        
        var interval = DateComponents()
        interval.day = 1
        
        var anchorComponents = Calendar.current.dateComponents([.day, .month, .year], from: now)
        anchorComponents.hour = 0
        let anchorDate = Calendar.current.date(from: anchorComponents)!
        
        let query = HKStatisticsCollectionQuery(
            quantityType: HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
            quantitySamplePredicate: nil,
            options: [.cumulativeSum],
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, results, error in
            guard let results = results else {
                completion(nil)
                return
            }
            
            results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let calories = sum.doubleValue(for: HKUnit.largeCalorie())
                    completion(Float(calories))
                }
            }
        }
        healthStore.execute(query)
    }
    
    func getCaloriesEaten(completion: @escaping ((_ eaten: Float?) -> Void)) {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: 0, to: now)!
        
        var interval = DateComponents()
        interval.day = 1
        
        var anchorComponents = Calendar.current.dateComponents([.day, .month, .year], from: now)
        anchorComponents.hour = 0
        let anchorDate = Calendar.current.date(from: anchorComponents)!
        
        let query = HKStatisticsCollectionQuery(
            quantityType: HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            quantitySamplePredicate: nil,
            options: [.cumulativeSum],
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, results, error in
            guard let results = results else {
                completion(nil)
                return
            }
            
            results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let calories = sum.doubleValue(for: HKUnit.largeCalorie())
                    completion(Float(calories))
                }
            }
        }
        healthStore.execute(query)
    }
    
    func getWeights(amount: Int, completion: @escaping ((_ weights: [HKQuantitySample]?) -> Void)) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: amount * 3, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            guard let results = results else {
                completion(nil)
                return
            }
            var n: [HKQuantitySample]? = []
            for x in results {
                if !((x as? HKQuantitySample)?.description.contains("MyFitnessPal") ?? true) {
                    n?.append(x as! HKQuantitySample)
                    if n?.count == amount {
                        completion(n)
                        return
                    }
                }
            }
            completion(n)
        }
        healthStore.execute(query)
    }
    
}
