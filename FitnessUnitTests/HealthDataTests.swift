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
        let environment = AppEnvironmentConfig(startDate: startDate, healthStorage: MockHealthStorage.standard)
        let healthData = await HealthData.setValues(environment: environment)
        #expect(healthData.days.count == 11)
        #expect(healthData.weightManager.weights.count == 18)
        #expect(healthData.weightManager.weightsAfterStartDate.count == 3)
        #expect(healthData.startDate == startDate)
        #expect(healthData.weightManager.startDate == startDate)
        #expect(healthData.calorieManager.daysBetweenStartAndNow == 10)
//        #expect(healthData.weightManager.startingWeight == 206)
//        #expect(healthData.weightManager.currentWeight == 200)
        let daysWithWeights = healthData.days.array().filter { $0.weight != 0}.toDays()
        let oldestDayWithWeight = try #require(daysWithWeights.oldestDay)
        let newestDayWithWeight = try #require(daysWithWeights.newestDay)
        #expect(oldestDayWithWeight.weight.isApproximately(224.83, accuracy: 0.01))
        #expect(newestDayWithWeight.weight == 227.6)
        #expect(newestDayWithWeight.protein == 0)
        #expect(daysWithWeights.count == healthData.days.count)
        #expect(healthData.hasLoaded == true)
        #expect(healthData.days == healthData.calorieManager.days)
        #expect(healthData.days.count == 11)
    }
    
    @Test("Health data handles gaps in weight data correctly")
    func health_gaps_in_weights() async throws {
        let startDate = Date().subtracting(days: 10)
        let gappedWeights = [
            Weight(weight: 200, date: Date().subtracting(days: 0)),
            Weight(weight: 201, date: Date().subtracting(days: 1)),
            // Gap on day 2
            Weight(weight: 203, date: Date().subtracting(days: 3)),
            // Gap on day 4 and 5
            Weight(weight: 206, date: Date().subtracting(days: 6)),
            Weight(weight: 207, date: Date().subtracting(days: 7))
        ]
        
        let environment = AppEnvironmentConfig(
            startDate: startDate,
            healthStorage: MockHealthStorage(weights: gappedWeights)
        )
        
        let healthData = await HealthData.setValues(environment: environment)
        
        // Verify that gaps are filled
        #expect(healthData.days[2]!.weight.isApproximately(202, accuracy: 0.1))
        #expect(healthData.days[4]!.weight.isApproximately(204, accuracy: 0.1))
        #expect(healthData.days[5]!.weight.isApproximately(205, accuracy: 0.1))
    }
}
