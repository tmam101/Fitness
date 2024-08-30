//
//  WeightManagerTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 8/30/24.
//

import Testing
@testable import Fitness
import HealthKit

struct WeightManagerTests {
    var weightManager: WeightManager!
    
    init() {
        weightManager = WeightManager()
    }
    
    @Test func mockWorks() async {
        let weightProcessor = MockWeightProcessor()
        let startDate = Date().subtracting(days: 3)
        await weightManager.setup(startDate: startDate, weightProcessor: MockWeightProcessor())
        #expect(weightManager.weights == weightProcessor.weights)
        #expect(weightManager.startDateString == startDate.toString())
    }
    
    @Test func startingWeightWithGapInDaysBeforeAndAfterStartDate() async {
        let weightProcessor = MockWeightProcessorWithGapInDays()
        let startDate = Date().subtracting(days: 4)
        await weightManager.setup(startDate: startDate, weightProcessor: weightProcessor)
        let expectedWeights = await weightProcessor.getWeights()
        #expect(weightManager.weights == expectedWeights)
        #expect(weightManager.startingWeight == 204)
    }
    
    @Test func startingWeightWithNoWeightsUntilAfterStartDate() async {
        let weightProcessor = MockWeightProcessor()
        let startDate = Date().subtracting(days: 12)
        await weightManager.setup(startDate: startDate, weightProcessor: weightProcessor)
        #expect(weightManager.weights == weightProcessor.weights)
        #expect(weightManager.startingWeight == 206)
    }
    
    @Test func HKQuery() async {
        let weightProcessor = MockWeightProcessor()
        let startDate = Date().subtracting(days: 12)
        await weightManager.setup(startDate: startDate, weightProcessor: weightProcessor)
        #expect(weightProcessor.query?.sortDescriptors == [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)])
        #expect(weightProcessor.query?.limit == 3000)
        #expect(weightProcessor.query?.objectType == HKSampleType.quantityType(forIdentifier: .bodyMass)!)
    }
}

class MockWeightProcessor: WeightProcessorProtocol {
    var query: HKSampleQuery?

    let weights: [Weight] = [
        .init(weight: 200, date: Date().subtracting(days: 0)),
        .init(weight: 201, date: Date().subtracting(days: 1)),
        .init(weight: 202, date: Date().subtracting(days: 2)),
        .init(weight: 203, date: Date().subtracting(days: 3)),
        .init(weight: 204, date: Date().subtracting(days: 4)),
        .init(weight: 205, date: Date().subtracting(days: 5)),
        .init(weight: 206, date: Date().subtracting(days: 6))
    ].sorted { $0.date < $1.date }
    func processWeights(continuation: CheckedContinuation<[Fitness.Weight], Never>, _ query: HKSampleQuery, _ results: [HKSample]?, _ error: (any Error)?) {
        self.query = query
        continuation.resume(returning: weights)
    }
}

class MockWeightProcessorWithGapInDays: WeightProcessorProtocol {
    let weights: [Weight] = [
        .init(weight: 200, date: Date().subtracting(days: 0)),
        .init(weight: 201, date: Date().subtracting(days: 1)),
        .init(weight: 202, date: Date().subtracting(days: 2)),
        .init(weight: 203, date: Date().subtracting(days: 3)),
        .init(weight: 206, date: Date().subtracting(days: 6)),
        .init(weight: 207, date: Date().subtracting(days: 7)),
        .init(weight: 208, date: Date().subtracting(days: 8)),
        .init(weight: 209, date: Date().subtracting(days: 9))
    ].sorted { $0.date < $1.date }
    var query: HKSampleQuery?
    
    func processWeights(continuation: CheckedContinuation<[Fitness.Weight], Never>, _ query: HKSampleQuery, _ results: [HKSample]?, _ error: (any Error)?) {
        self.query = query
        continuation.resume(returning: weights)
    }
    
    func getWeights() async -> [Fitness.Weight] {
        return [
            .init(weight: 200, date: Date().subtracting(days: 0)),
            .init(weight: 201, date: Date().subtracting(days: 1)),
            .init(weight: 202, date: Date().subtracting(days: 2)),
            .init(weight: 203, date: Date().subtracting(days: 3)),
            .init(weight: 206, date: Date().subtracting(days: 6)),
            .init(weight: 207, date: Date().subtracting(days: 7)),
            .init(weight: 208, date: Date().subtracting(days: 8)),
            .init(weight: 209, date: Date().subtracting(days: 9))
        ].sorted { $0.date < $1.date }
    }
}
