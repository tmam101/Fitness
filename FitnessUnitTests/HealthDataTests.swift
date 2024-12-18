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
    
    @Test("Health data sets weights on every day when necessary")
    func health_gaps() async {
        let startDate = Date().subtracting(days: 10)
        var environment = AppEnvironmentConfig(startDate: startDate, healthStorage: MockHealthStorage.standard) // TODO need gap in days
        var healthData = await HealthData.setValues(environment: environment)
        #expect(healthData.days[3]?.weight == 203)
        #expect(healthData.days[4]?.weight == 204)
        
        // TODO these options are getting overridden by the MockHealthStorage's own options
        environment = AppEnvironmentConfig(dontAddWeightsOnEveryDay: true, startDate: startDate, healthStorage: MockHealthStorage(
            days:
                [5: Day(daysAgo: 5, weight: 205),
                 4: Day(daysAgo: 4, weight: 0),
                 3: Day(daysAgo: 3, weight: 203)
                ]))
        healthData = await HealthData.setValues(environment: environment)
        #expect(healthData.days[3]?.weight == 203)
        #expect(healthData.days[4]?.weight == 0)
    }
}
