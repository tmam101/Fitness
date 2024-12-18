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
        func days() -> Days {
            var days: Days = [:]
            for i in 0...100 {
                days[i] = Day(activeCalories: 100, restingCalories: 2000, consumedCalories: 1900) // Every day has deficit of -200
            }
            return days
        }
        
        // Test week
        let days = days()
        days[0]?.consumedCalories = 3000 // except for today, which has a surplus of 900
        var models = HomeScreen.netEnergyRingModels(days: days, timeFrame: .week)
        var netEnergyThisTimeFrameModel = try #require(models?.first)
        #expect(netEnergyThisTimeFrameModel.bodyText == "-200")
        #expect(netEnergyThisTimeFrameModel.percentage.isApproximately(0.2, accuracy: 0.001))
        #expect(netEnergyThisTimeFrameModel.color == .yellow)

        var netEnergyTomorrowModel = try #require(models?[1])
        #expect(netEnergyTomorrowModel.bodyText == "-42")
        #expect(netEnergyTomorrowModel.percentage.isApproximately(0.042, accuracy: 0.001))
        #expect(netEnergyTomorrowModel.color == .yellow)
        
        // Test month
        models = HomeScreen.netEnergyRingModels(days: days, timeFrame: .month)
        netEnergyThisTimeFrameModel = try #require(models?.first)
        #expect(netEnergyThisTimeFrameModel.bodyText == "-200")
        #expect(netEnergyThisTimeFrameModel.percentage.isApproximately(0.2, accuracy: 0.01))
        #expect(netEnergyThisTimeFrameModel.color == .yellow)

        netEnergyTomorrowModel = try #require(models?[1])
        #expect(netEnergyTomorrowModel.bodyText == "-163")
        #expect(netEnergyTomorrowModel.percentage.isApproximately(0.163, accuracy: 0.01))
        #expect(netEnergyTomorrowModel.color == .yellow)

        // Test year
        models = HomeScreen.netEnergyRingModels(days: days, timeFrame: .allTime)
        netEnergyThisTimeFrameModel = try #require(models?.first)
        #expect(netEnergyThisTimeFrameModel.bodyText == "-200")
        #expect(netEnergyThisTimeFrameModel.percentage.isApproximately(0.2, accuracy: 0.001))
        #expect(netEnergyThisTimeFrameModel.color == .yellow)

        netEnergyTomorrowModel = try #require(models?[1])
        #expect(netEnergyTomorrowModel.bodyText == "-189")
        #expect(netEnergyTomorrowModel.percentage.isApproximately(0.189, accuracy: 0.001))
        #expect(netEnergyTomorrowModel.color == .yellow)
        
    }
    
    @Test("Home screen weight models")
    func weight() throws {
        var days = Days()
        // Set first day's expected weight to match its actual weight
        days[7] = Day(daysAgo: 7, activeCalories: 0, restingCalories: 3500 / 7, consumedCalories: 0, expectedWeight: 210, weight: 210)
        days[6] = Day(daysAgo: 6, activeCalories: 0, restingCalories: 3500 / 7, consumedCalories: 0, expectedWeight: 209.9, weight: 209.9)
        days[5] = Day(daysAgo: 5, activeCalories: 0, restingCalories: 3500 / 7, consumedCalories: 0, expectedWeight: 209.8, weight: 209.8)
        days[4] = Day(daysAgo: 4, activeCalories: 0, restingCalories: 3500 / 7, consumedCalories: 0, expectedWeight: 209.7, weight: 209.7)
        days[3] = Day(daysAgo: 3, activeCalories: 0, restingCalories: 3500 / 7, consumedCalories: 0, expectedWeight: 209.6, weight: 209.6)
        days[2] = Day(daysAgo: 2, activeCalories: 0, restingCalories: 3500 / 7, consumedCalories: 0, expectedWeight: 209.5, weight: 209.5)
        days[1] = Day(daysAgo: 1, activeCalories: 0, restingCalories: 3500 / 7, consumedCalories: 0, expectedWeight: 209.4, weight: 209.4)
        days[0] = Day(daysAgo: 0, activeCalories: 0, restingCalories: 3500, consumedCalories: 0, expectedWeight: 209.3, weight: 209.3)

        // Test week
        var models = HomeScreen.weightRingModels(days: days, timeFrame: .week)
        var expectedWeightModel = try #require(models?.first)
        #expect(expectedWeightModel.bodyText == "-1.00")
        #expect(expectedWeightModel.percentage.isApproximately(0.5, accuracy: 0.01))
        #expect(expectedWeightModel.color == .yellow)

        var weightModel = try #require(models?[1])
        #expect(weightModel.bodyText == "-0.70") // TODO should this be days[0] - days[6] rather than days[7]?
        #expect(weightModel.percentage.isApproximately(0.35, accuracy: 0.01))
        #expect(weightModel.color == .green)
        
        // Test calculations
        let daysWithinTimeframe = days.filteredBy(.week)
        var oldestDay = try #require(daysWithinTimeframe.oldestDay)
        var newestDay = try #require(daysWithinTimeframe.newestDay) // shouldnt be today

        let expectedWeightDifference = newestDay.expectedWeight - oldestDay.expectedWeight
        #expect(expectedWeightDifference.isApproximately(-0.7, accuracy: 0.01))
        let weightDifference = newestDay.weight - oldestDay.weight
        #expect(weightDifference.isApproximately(-0.7, accuracy: 0.01))

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
        oldestDay = try #require(days.oldestDay)
        newestDay = try #require(days.newestDay)
        let dayDifference = Decimal(oldestDay.daysAgo - newestDay.daysAgo)
        let goalDifference = -Decimal(2.0/7.0) * dayDifference
        #expect(dayDifference == 135)
        #expect(goalDifference.isApproximately(-38.571, accuracy: 0.001))
        
        models = HomeScreen.weightRingModels(days: days, timeFrame: .allTime)
        expectedWeightModel = try #require(models?.first)
        #expect(expectedWeightModel.bodyText == "-2.86")
        #expect(expectedWeightModel.percentage.isApproximately(-2.86 / goalDifference, accuracy: 0.001))
        #expect(expectedWeightModel.color == .yellow)

        weightModel = try #require(models?[1])
        #expect(weightModel.bodyText == "-1.60")
        #expect(weightModel.percentage.isApproximately(-1.60 / goalDifference, accuracy: 0.01))
        #expect(weightModel.color == .green)
    }
}
