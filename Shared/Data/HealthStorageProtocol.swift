//
//  HealthStorageProtocol.swift
//  Fitness
//
//  Created by Thomas on 9/9/24.
//

import Foundation
import HealthKit

protocol HealthStorageProtocol {
    func sampleQuery(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void)
    func statisticsQuery(
        type: HealthKitType, quantitySamplePredicate: NSPredicate?, options: HKStatisticsOptions, completionHandler handler: @escaping (HKStatisticsQuery?, HKStatisticsProtocol?, (any Error)?) -> Void
    )
    func save(
        _ object: HKObject,
        withCompletion completion: @escaping (Bool, (any Error)?) -> Void
    )
    func getAllWeights(resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void)
}

//TODO: For now, all in one, then separate later
class HealthStorage: HealthStorageProtocol {
    var weightLimit = 3000
    var sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    var querySampleType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    func getAllWeights(resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: querySampleType, predicate: nil, limit: weightLimit, sortDescriptors: [sortDescriptor], resultsHandler: resultsHandler)
        healthStore.execute(query)
    }
    
    private let healthStore = HKHealthStore()
    
    func save(_ object: HKObject, withCompletion completion: @escaping (Bool, (any Error)?) -> Void) {
        healthStore.save(object, withCompletion: completion)
    }
    
    func sampleQuery(
        sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors, resultsHandler: resultsHandler)
            healthStore.execute(query)
        }
    
    func statisticsQuery(
        type: HealthKitType, quantitySamplePredicate: NSPredicate?, options: HKStatisticsOptions = [], completionHandler handler: @escaping (HKStatisticsQuery?, HKStatisticsProtocol?, (any Error)?) -> Void
    ) {
        guard let quantityType = type.value else {
            handler(nil, nil, nil) // TODO return error
            return 
        }
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantitySamplePredicate, options: options, completionHandler: handler)
        
        healthStore.execute(query)
    }
}

class MockHealthStorage: HealthStorageProtocol {
    var weightLimit = 3000
    var sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    var querySampleType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    func save(_ object: HKObject, withCompletion completion: @escaping (Bool, (any Error)?) -> Void) {
        //  TODO
    }
    
    func statisticsQuery(type: HealthKitType, quantitySamplePredicate: NSPredicate?, options: HKStatisticsOptions, completionHandler handler: @escaping (HKStatisticsQuery?, HKStatisticsProtocol?, (any Error)?) -> Void) {
        guard let quantityType = type.value else {
            handler(nil, nil, nil) // TODO return error
            return
        }
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantitySamplePredicate, options: options, completionHandler: handler)
        let mock = MockHKStatistics(sumQuantity: .init(unit: type.unit, doubleValue: 1000))
        handler(query, mock, nil)
    }
    
    func sampleQuery(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors, resultsHandler: resultsHandler)
        // TODO set up some Days, using testDays probably, then create samples from their weights
        
        let weights: [Weight] = [
            .init(weight: 200, date: Date().subtracting(days: 0)),
            .init(weight: 201, date: Date().subtracting(days: 1)),
            .init(weight: 202, date: Date().subtracting(days: 2)),
            .init(weight: 203, date: Date().subtracting(days: 3)),
            .init(weight: 204, date: Date().subtracting(days: 4)),
            .init(weight: 205, date: Date().subtracting(days: 5)),
            .init(weight: 206, date: Date().subtracting(days: 6)),
        ]
        let samples = weights.map { HKQuantitySample(type: .init(.bodyMass), quantity: .init(unit: .pound(), doubleValue: Double($0.weight)), start: $0.date, end: $0.date)}
        
        resultsHandler(query, samples, nil)
    }
    
    func getAllWeights(resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: querySampleType, predicate: nil, limit: weightLimit, sortDescriptors: [sortDescriptor], resultsHandler: resultsHandler)
        // TODO set up some Days, using testDays probably, then create samples from their weights
        
        let weights: [Weight] = [
            .init(weight: 200, date: Date().subtracting(days: 0)),
            .init(weight: 201, date: Date().subtracting(days: 1)),
            .init(weight: 202, date: Date().subtracting(days: 2)),
            .init(weight: 203, date: Date().subtracting(days: 3)),
            .init(weight: 204, date: Date().subtracting(days: 4)),
            .init(weight: 205, date: Date().subtracting(days: 5)),
            .init(weight: 206, date: Date().subtracting(days: 6)),
        ]
        let samples = weights.map { HKQuantitySample(type: .init(.bodyMass), quantity: .init(unit: .pound(), doubleValue: Double($0.weight)), start: $0.date, end: $0.date)}
        
        resultsHandler(query, samples, nil)
    }
}

class MockHealthStorageWithGapInDays: MockHealthStorage {
    
    override func getAllWeights(resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: querySampleType, predicate: nil, limit: weightLimit, sortDescriptors: [sortDescriptor], resultsHandler: resultsHandler)
        // TODO set up some Days, using testDays probably, then create samples from their weights
        
        let weights: [Weight] = [
            .init(weight: 200, date: Date().subtracting(days: 0)),
            .init(weight: 201, date: Date().subtracting(days: 1)),
            .init(weight: 202, date: Date().subtracting(days: 2)),
            .init(weight: 203, date: Date().subtracting(days: 3)),
            .init(weight: 206, date: Date().subtracting(days: 6)),
            .init(weight: 207, date: Date().subtracting(days: 7)),
            .init(weight: 208, date: Date().subtracting(days: 8)),
            .init(weight: 209, date: Date().subtracting(days: 9))
        ]
        
        let samples = weights.map { HKQuantitySample(type: .init(.bodyMass), quantity: .init(unit: .pound(), doubleValue: Double($0.weight)), start: $0.date, end: $0.date)}
        
        resultsHandler(query, samples, nil)
    }
    
    override func sampleQuery(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors, resultsHandler: resultsHandler)
        
        let weights: [Weight] = [
            .init(weight: 200, date: Date().subtracting(days: 0)),
            .init(weight: 201, date: Date().subtracting(days: 1)),
            .init(weight: 202, date: Date().subtracting(days: 2)),
            .init(weight: 203, date: Date().subtracting(days: 3)),
            .init(weight: 206, date: Date().subtracting(days: 6)),
            .init(weight: 207, date: Date().subtracting(days: 7)),
            .init(weight: 208, date: Date().subtracting(days: 8)),
            .init(weight: 209, date: Date().subtracting(days: 9))
        ]
        let samples = weights.map { HKQuantitySample(type: .init(.bodyMass), quantity: .init(unit: .pound(), doubleValue: Double($0.weight)), start: $0.date, end: $0.date)}
        
        resultsHandler(query, samples, nil)
    }
}

protocol HKStatisticsProtocol {
    func sumQuantity() -> HKQuantity?
}

extension HKStatistics: HKStatisticsProtocol {}

class MockHKStatistics: HKStatisticsProtocol {
    var mockSumQuantity: HKQuantity?
    
    init(sumQuantity: HKQuantity?) {
        self.mockSumQuantity = sumQuantity
    }
    
    func sumQuantity() -> HKQuantity? {
        return mockSumQuantity
    }
}

