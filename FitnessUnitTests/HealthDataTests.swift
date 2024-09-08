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
    func health() async {
        let startDate = Date().subtracting(days: 10)
        let config = Config.init(startDate: startDate, healthStorage: MockHealthStorage())
        let environment = AppEnvironmentConfig.release(options: config)
        let healthData = await HealthData.setValues(environment: environment)
        #expect(healthData.weightManager.weights.count == 7)
        #expect(healthData.startDate == startDate)
        #expect(healthData.weightManager.startDate == startDate)
        #expect(healthData.weightManager.startingWeight == 206)
        #expect(healthData.weightManager.currentWeight == 200)
//        #expect(healthData.hasLoaded == true)
        #expect(healthData.days == healthData.calorieManager.days)
        #expect(healthData.days.count == 7)
    }
    
}
