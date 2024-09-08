//
//  WeightManagerTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 8/30/24.
//

import Testing
@testable import Fitness
import HealthKit

final class WeightManagerTests {
    var weightManager: WeightManager!
    var environment: AppEnvironmentConfig!
    
    init() {
        environment = .debug(.init(healthStorage: MockHealthStorage()))
        weightManager = WeightManager(environment: environment)
    }
    
    @Test func mockWorks() async {
        let startDate = Date().subtracting(days: 3)
        await weightManager.setup(startDate: startDate)
        #expect(weightManager.weights.first?.weight == 206)
        #expect(weightManager.weights.last?.weight == 200)
        #expect(weightManager.startDate == startDate)
    }
    
    @Test func startingWeightWithGapInDaysBeforeAndAfterStartDate() async {
        let weightProcessor = MockHealthStorageWithGapInDays()
        environment = .debug(.init(healthStorage: MockHealthStorage()))
        weightManager = WeightManager(environment: environment)
        let startDate = Date().subtracting(days: 4)
        await weightManager.setup(startDate: startDate)
//        let expectedWeights = await weightProcessor.getWeights()
//        #expect(weightManager.weights == expectedWeights)
        #expect(weightManager.startingWeight == 204)
    }
    
    @Test func startingWeightWithNoWeightsUntilAfterStartDate() async {
        let startDate = Date().subtracting(days: 12)
        await weightManager.setup(startDate: startDate)
//        #expect(weightManager.weights == weightProcessor.weights)
        #expect(weightManager.startingWeight == 206)
    }
    
    @Test func currentWeight() async {
        let startDate = Date().subtracting(days: 12)
        await weightManager.setup(startDate: startDate)
//        #expect(weightManager.weights == weightProcessor.weights)
        #expect(weightManager.currentWeight == 200)
    }
    
    @Test func HKQuery() async {
        let startDate = Date().subtracting(days: 12)
        await weightManager.setup(startDate: startDate)
        #expect(weightManager.sortDescriptor == NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false))
        #expect(weightManager.weightLimit == 3000)
        #expect(weightManager.querySampleType == HKSampleType.quantityType(forIdentifier: .bodyMass)!)
    }
}



class MockHealthStorage: HealthStorageProtocol {
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
                .init(weight: 206, date: Date().subtracting(days: 6))
        ]
        let samples = weights.map { HKQuantitySample(type: .init(.bodyMass), quantity: .init(unit: .pound(), doubleValue: Double($0.weight)), start: $0.date, end: $0.date)}
            
        resultsHandler(query, samples, nil)
    }
}

class MockHealthStorageWithGapInDays: HealthStorageProtocol {
    func sampleQuery(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
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
