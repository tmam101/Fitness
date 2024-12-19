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
        let startDate = Date().subtracting(days: 10)
        await weightManager.setup(startDate: startDate)
        #expect(weightManager.weights.first?.weight == 229.2)
        #expect(weightManager.weights.last?.weight == 227.6)
        #expect(weightManager.weights.first?.date.daysAgo() == 135)
        #expect(weightManager.weightsAfterStartDate.first?.date.daysAgo() == 9)
        #expect(weightManager.weightsAfterStartDate.first?.weight == 224.8)
        #expect(weightManager.startDate == startDate)
    }
    
    @Test func startingWeightWithGapInDaysBeforeAndAfterStartDate() async {
        let weights = [
            Weight(weight: 229.2, date: Date().subtracting(days: 10)),  // Before start date
            Weight(weight: 228.0, date: Date().subtracting(days: 2))    // After start date
        ]
        let mockStorage = MockHealthStorageWithGapInDays(weights: weights)
        environment = .init(healthStorage: mockStorage)
        weightManager = WeightManager(environment: environment)
        
        let startDate = Date().subtracting(days: 4)
        await weightManager.setup(startDate: startDate)
        
        #expect(weightManager.startingWeight == 228.3)
    }
    
    @Test func startingWeightWithNoWeightsUntilAfterStartDate() async {
        let startDate = Date.dateFromString("05.05.2020")
        await weightManager.setup(startDate: startDate)
        #expect(weightManager.startingWeight == 229.2)
    }
    
    @Test func currentWeight() async {
        let startDate = Date().subtracting(days: 12)
        await weightManager.setup(startDate: startDate)
        #expect(weightManager.currentWeight == 227.6)
    }
    
    @Test("Get weights")
    func getWeights() async {
        let weights = await WeightManager(environment: .debug).getWeights()
        #expect(weights.first?.weight == 229.2)
        #expect(weights.last?.weight == 227.6)
    }
}
