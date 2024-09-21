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
    
    @Test("Start date filters weights")
    func startDate() async {
        let startDate = Date().subtracting(days: 3)
        await weightManager.setup(startDate: startDate)
        #expect(weightManager.weights.first?.weight == 206)
        #expect(weightManager.weights.last?.weight == 200)
        #expect(weightManager.weights.first?.date.daysAgo() == 6)
        #expect(weightManager.weightsAfterStartDate.first?.date.daysAgo() == 3)
        #expect(weightManager.weightsAfterStartDate.first?.weight == 203)
        #expect(weightManager.startDate == startDate)
    }
    
    @Test func startingWeightWithGapInDaysBeforeAndAfterStartDate() async {
        let weightProcessor = MockHealthStorageWithGapInDays()
        environment = .init(healthStorage: weightProcessor)
        weightManager = WeightManager(environment: environment)
        let startDate = Date().subtracting(days: 4)
        await weightManager.setup(startDate: startDate)
        #expect(weightManager.startingWeight == 204)
    }
    
    @Test func startingWeightWithNoWeightsUntilAfterStartDate() async {
        let startDate = Date().subtracting(days: 12)
        await weightManager.setup(startDate: startDate)
        #expect(weightManager.startingWeight == 206)
    }
    
    @Test func currentWeight() async {
        let startDate = Date().subtracting(days: 12)
        await weightManager.setup(startDate: startDate)
        #expect(weightManager.currentWeight == 200)
    }
    
    @Test("Get weights")
    func getWeights() async {
        let weights = await WeightManager(environment: .debug).getWeights()
        #expect(weights.first?.weight == 206)
        #expect(weights.last?.weight == 200)
    }
}
