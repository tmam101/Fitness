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
        environment = .debug
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
        environment = .init(healthStorage: weightProcessor)
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
