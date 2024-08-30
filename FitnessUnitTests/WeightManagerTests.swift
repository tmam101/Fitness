//
//  WeightManagerTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 8/30/24.
//

import XCTest
@testable import Fitness

final class WeightManagerTests: XCTestCase {
    var weightManager: WeightManager!
    
    override func setUp() {
        weightManager = WeightManager()
    }
    
    func testMockWorks() async {
        let weightRetrievier = MockWeightRetriever()
        let startDate = Date().subtracting(days: 3)
        await weightManager.setup(startDate: startDate, weightRetriever: MockWeightRetriever())
        let expectedWeights = await weightRetrievier.getWeights()
        XCTAssertEqual(weightManager.weights, expectedWeights)
        XCTAssertEqual(weightManager.startDateString, startDate.toString())
    }
    
    func testStartingWeightWithGapInDaysBeforeAndAfterStartDate() async {
        let weightRetrievier = MockWeightRetrieverWithGapInDays()
        let startDate = Date().subtracting(days: 4)
        await weightManager.setup(startDate: startDate, weightRetriever: weightRetrievier)
        let expectedWeights = await weightRetrievier.getWeights()
        XCTAssertEqual(weightManager.weights, expectedWeights)
        XCTAssertEqual(weightManager.startingWeight, 204)
    }
    
    func testStartingWeightWithNoWeightsUntilAfterStartDate() async {
        let weightRetrievier = MockWeightRetriever()
        let startDate = Date().subtracting(days: 12)
        await weightManager.setup(startDate: startDate, weightRetriever: weightRetrievier)
        let expectedWeights = await weightRetrievier.getWeights()
        XCTAssertEqual(weightManager.weights, expectedWeights)
        XCTAssertEqual(weightManager.startingWeight, 206)
    }
}

class MockWeightRetriever: WeightRetrieverProtocol {
    func getWeights() async -> [Fitness.Weight] {
        return [
            .init(weight: 200, date: Date().subtracting(days: 0)),
            .init(weight: 201, date: Date().subtracting(days: 1)),
            .init(weight: 202, date: Date().subtracting(days: 2)),
            .init(weight: 203, date: Date().subtracting(days: 3)),
            .init(weight: 204, date: Date().subtracting(days: 4)),
            .init(weight: 205, date: Date().subtracting(days: 5)),
            .init(weight: 206, date: Date().subtracting(days: 6))
        ].sorted { $0.date < $1.date }
    }
}

class MockWeightRetrieverWithGapInDays: WeightRetrieverProtocol {
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

//class MockWeightRetrieverWithNoWeightsUntilAfterStartDate: WeightRetrieverProtocol {
//    func getWeights() async -> [Fitness.Weight] {
//        return [
//            .init(weight: 200, date: Date().subtracting(days: 0)),
//            .init(weight: 201, date: Date().subtracting(days: 1)),
//            .init(weight: 202, date: Date().subtracting(days: 2)),
//            .init(weight: 203, date: Date().subtracting(days: 3))
//        ]
//    }
//}
