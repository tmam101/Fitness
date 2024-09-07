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

    
//    @Test("Health data")
//    func netEnergy() async throws {
//        await confirmation("...") { healthLoaded in
//            let environment = AppEnvironmentConfig.release(options: nil, weightProcessor: MockWeightProcessor())
//            await withCheckedContinuation { continuation in
//                Task {
//                    let healthData = HealthData(environment: environment) { healthData in
//                        healthLoaded()
//                        continuation.resume()
//                    }
//                }
//            }
//        }
//    }
//    
//    @Test("Health data")
//    func netEnergy() async throws {
//        await confirmation("...") { healthLoaded in
//            let environment = AppEnvironmentConfig.release(options: nil, weightProcessor: MockWeightProcessor())
//            let healthData = HealthData(environment: environment)
////            healthData.$hasLoaded.sink { [weak self] hasLoaded in
////                guard let self = self, hasLoaded else { return }
////                healthLoaded()
////            }.store(in: &cancellables)
//            #expect(healthData.weightManager.weights.count == 7)
//        }
//    }
    
    @Test("Health data set values")
    func health() async {
        // TODO finish implementing start date
        let environment = AppEnvironmentConfig.release(options: [.startDate(Date().subtracting(days: 10))], weightProcessor: MockWeightProcessor())
        let healthData = await HealthData.setValues(environment: environment)
        #expect(healthData.weightManager.weights.count == 7)
        }
    
    
}
