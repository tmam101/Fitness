//
//  HealthStorageProtocol.swift
//  Fitness
//
//  Created by Thomas on 9/9/24.
//

import Foundation
import HealthKit

protocol HealthStorageProtocol {
    func save(
        _ object: HKObject,
        withCompletion completion: @escaping (Bool, (any Error)?) -> Void
    )
    func getAllWeights(resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void)
    func sumValueForDay(daysAgo: Int, forType type: HealthKitType) async -> HKQuantity?

}

//TODO: For now, all in one, then separate later
class HealthStorage: HealthStorageProtocol {
    var weightLimit = 3000
    var weightSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    var weightQuerySampleType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    func getAllWeights(resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: weightQuerySampleType, predicate: nil, limit: weightLimit, sortDescriptors: [weightSortDescriptor], resultsHandler: resultsHandler)
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
    
    // MARK: CONVENIENCE
    
    func sumValueForDay(daysAgo: Int, forType type: HealthKitType) async -> HKQuantity? {
        return await withUnsafeContinuation { continuation in
            let predicate = specificDayPredicate(daysAgo: daysAgo)
           
            self.statisticsQuery(type: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                continuation.resume(returning: result?.sumQuantity())
            }
        }
    }
    
    // MARK: PREDICATES
    
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
}

class MockHealthStorage: HealthStorageProtocol {
    static var standard = MockHealthStorage(days: Days.daysFromFileWithNoAdjustment(file: .realisticWeightsIssue))

    var days: Days
    var weightLimit = 3000
    var sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    var querySampleType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    init(days: Days) {
        self.days = days
    }
    
    init(file: Filepath.Days) {
        self.days = Days.daysFromFileWithNoAdjustment(file: file)
    }
    
    func sumValueForDay(daysAgo: Int, forType type: HealthKitType) async -> HKQuantity? {
        return switch type {
        case .dietaryProtein:
            HKQuantity(unit: .gram(), doubleValue: Double(days[daysAgo]?.protein ?? 1000)) // TODO 1000 not ideal
        case .activeEnergyBurned:
            HKQuantity(unit: .kilocalorie(), doubleValue: Double(days[daysAgo]?.activeCalories ?? 1000))
        case .basalEnergyBurned:
            HKQuantity(unit: .kilocalorie(), doubleValue: Double(days[daysAgo]?.restingCalories ?? 1000))
        case .dietaryEnergyConsumed:
            HKQuantity(unit: .kilocalorie(), doubleValue: Double(days[daysAgo]?.consumedCalories ?? 1000))
        }
    }
    
    func save(_ object: HKObject, withCompletion completion: @escaping (Bool, (any Error)?) -> Void) {
        //  TODO
    }
    
    func getAllWeights(resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: querySampleType, predicate: nil, limit: weightLimit, sortDescriptors: [sortDescriptor], resultsHandler: resultsHandler)
        
        let weights: [Weight] = days.array().sorted(.longestAgoToMostRecent).compactMap { day in
            day.weight == 0 ? nil : Weight(weight: day.weight, date: Date().subtracting(days: day.daysAgo))
        }
        let samples = weights.map { HKQuantitySample(type: .init(.bodyMass), quantity: .init(unit: .pound(), doubleValue: Double($0.weight)), start: $0.date, end: $0.date)}
        
        resultsHandler(query, samples, nil)
    }
}

class MockHealthStorageWithGapInDays: MockHealthStorage {
    let gappedWeights: [Weight]
    
    init(weights: [Weight]) {
        self.gappedWeights = weights
        super.init(days: [:])  // Empty days since we're providing weights directly
    }
    
    override func getAllWeights(resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: querySampleType, predicate: nil, limit: weightLimit, sortDescriptors: [sortDescriptor], resultsHandler: resultsHandler)
        
        let samples = gappedWeights.map {
            HKQuantitySample(
                type: .init(.bodyMass),
                quantity: .init(unit: .pound(), doubleValue: Double($0.weight)),
                start: $0.date,
                end: $0.date
            )
        }
        
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
