//
//  HealthDataTests.swift
//  Fitness
//
//  Created by Thomas on 8/31/24.
//

import Testing
@testable import Fitness
import Combine
import Foundation

@Suite

final class HealthDataTests {
    
    private var cancellables: [AnyCancellable] = []
    
    @Test("Health data set values")
    func health() async throws {
        let startDate = Date().subtracting(days: 10)
        let environment = AppEnvironmentConfig(startDate: startDate, healthStorage: MockHealthStorage())
        let healthData = await HealthData.setValues(environment: environment)
        #expect(healthData.weightManager.weights.count == 7)
        #expect(healthData.startDate == startDate)
        #expect(healthData.weightManager.startDate == startDate)
        #expect(healthData.weightManager.startingWeight == 206)
        #expect(healthData.weightManager.currentWeight == 200)
        let daysWithWeights = healthData.days.array().filter { $0.weight != 0}.toDays()
        let oldestDayWithWeight = try #require(daysWithWeights.oldestDay)
        let newestDayWithWeight = try #require(daysWithWeights.newestDay)
        #expect(oldestDayWithWeight.weight == 206)  // TODO flaky
        #expect(newestDayWithWeight.weight == 200)
        #expect(newestDayWithWeight.protein == 1000)
        #expect(healthData.hasLoaded == true)
        #expect(healthData.days == healthData.calorieManager.days)
        #expect(healthData.days.count == 11)
    }
    
    // TODO test different environment things, like adding weights on every day
    
}
