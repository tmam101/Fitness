//
//  HomeScreenTests.swift
//  Fitness
//
//  Created by Thomas on 8/31/24.
//

import Testing
@testable import Fitness
import Combine
import Foundation

@Suite

final class HomeScreenTests {
    
    @Test("Home screen net energy models")
    func netEnergy() throws {
        // TODO Test more thoroughly - create days that I know the difference of, then test against that
        let days = Days.testDays(options: [.isMissingConsumedCalories(.v3), .testCase(.realisticWeightsIssue)])
        
        // Test week
        var models = HomeScreen.netEnergyRingModels(days: days, timeFrame: .week)
        var netEnergyThisTimeFrameModel = try #require(models?.first)
        #expect(netEnergyThisTimeFrameModel.bodyText == "+307")
        #expect(netEnergyThisTimeFrameModel.percentage.isApproximately(-0.307, accuracy: 0.001))
        #expect(netEnergyThisTimeFrameModel.color == .red)

        var netEnergyTomorrowModel = try #require(models?[1])
        #expect(netEnergyTomorrowModel.bodyText == "-113")
        #expect(netEnergyTomorrowModel.percentage.isApproximately(0.113, accuracy: 0.001))
        #expect(netEnergyTomorrowModel.color == .yellow)
        
        // Test calculations
        let daysWithinTimeframe = days.filteredBy(.week)
        let oldestDay = try #require(daysWithinTimeframe.oldestDay)
        let newestDay = try #require(daysWithinTimeframe.newestDay)

        let expectedWeightDifference = newestDay.expectedWeight - oldestDay.expectedWeight
        #expect(expectedWeightDifference.isApproximately(0.61, accuracy: 0.01))
        let weightDifference = newestDay.weight - oldestDay.weight
        #expect(weightDifference.isApproximately(0.83, accuracy: 0.01))
        
        // Test month
        models = HomeScreen.netEnergyRingModels(days: days, timeFrame: .month)
        netEnergyThisTimeFrameModel = try #require(models?.first)
        #expect(netEnergyThisTimeFrameModel.bodyText == "+59")
        #expect(netEnergyThisTimeFrameModel.percentage.isApproximately(-0.059, accuracy: 0.01))
        #expect(netEnergyThisTimeFrameModel.color == .red)

        netEnergyTomorrowModel = try #require(models?[1])
        #expect(netEnergyTomorrowModel.bodyText == "+21")
        #expect(netEnergyTomorrowModel.percentage.isApproximately(-0.021, accuracy: 0.01))
        #expect(netEnergyTomorrowModel.color == .red)

        // Test year
        models = HomeScreen.netEnergyRingModels(days: days, timeFrame: .allTime)
        netEnergyThisTimeFrameModel = try #require(models?.first)
        #expect(netEnergyThisTimeFrameModel.bodyText == "-74")
        #expect(netEnergyThisTimeFrameModel.percentage.isApproximately(0.074, accuracy: 0.001))
        #expect(netEnergyThisTimeFrameModel.color == .yellow)

        netEnergyTomorrowModel = try #require(models?[1])
        #expect(netEnergyTomorrowModel.bodyText == "-90")
        #expect(netEnergyTomorrowModel.percentage.isApproximately(0.090001, accuracy: 0.001))
        #expect(netEnergyTomorrowModel.color == .yellow)
        
    }
    
    @Test("Home screen weight models")
    func weight() throws {
        // TODO Test more thoroughly - create days that I know the difference of, then test against that
        let days = Days.testDays(options: [.isMissingConsumedCalories(.v3), .testCase(.realisticWeightsIssue)])
        
        // Test week
        var models = HomeScreen.weightRingModels(days: days, timeFrame: .week)
        var expectedWeightModel = try #require(models?.first)
        #expect(expectedWeightModel.bodyText == "+0.61")
        #expect(expectedWeightModel.percentage == 0)
        #expect(expectedWeightModel.color == .white)

        var weightModel = try #require(models?[1])
        #expect(weightModel.bodyText == "+0.83")
        #expect(weightModel.percentage == 0)
        #expect(weightModel.color == .white)
        
        // Test calculations
        let daysWithinTimeframe = days.filteredBy(.week)
        let oldestDay = try #require(daysWithinTimeframe.oldestDay)
        let newestDay = try #require(daysWithinTimeframe.newestDay)

        let expectedWeightDifference = newestDay.expectedWeight - oldestDay.expectedWeight
        #expect(expectedWeightDifference.isApproximately(0.61, accuracy: 0.01))
        let weightDifference = newestDay.weight - oldestDay.weight
        #expect(weightDifference.isApproximately(0.83, accuracy: 0.01))
        
        // Test month
        models = HomeScreen.weightRingModels(days: days, timeFrame: .month)
        expectedWeightModel = try #require(models?.first)
        #expect(expectedWeightModel.bodyText == "+0.51")
        #expect(expectedWeightModel.percentage == 0)
        #expect(expectedWeightModel.color == .white)

        weightModel = try #require(models?[1])
        #expect(weightModel.bodyText == "+0.40")
        #expect(weightModel.percentage == 0)
        #expect(weightModel.color == .white)

        // Test year
        models = HomeScreen.weightRingModels(days: days, timeFrame: .allTime)
        expectedWeightModel = try #require(models?.first)
        #expect(expectedWeightModel.bodyText == "-2.86")
        #expect(expectedWeightModel.percentage.isApproximately(1.427, accuracy: 0.001))
        #expect(expectedWeightModel.color == .yellow)

        weightModel = try #require(models?[1])
        #expect(weightModel.bodyText == "-1.60")
        #expect(weightModel.percentage.isApproximately(0.8, accuracy: 0.01))
        #expect(weightModel.color == .green)
    }
}
