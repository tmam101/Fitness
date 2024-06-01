//
//  WeightLineChartTests.swift
//  Fitness
//
//  Created by Thomas on 5/31/24.
//

import XCTest
@testable import Fitness
import SwiftUI

final class WeightLineChartTests: XCTestCase {
    
    func testPlotStyleTypeProperties() {
        let weightStyle = PlotStyleType.weight
        XCTAssertEqual(weightStyle.foregroundStyle, "Weight")
        XCTAssertEqual(weightStyle.xValueLabel, "Days ago")
        XCTAssertEqual(weightStyle.yValueLabel, "Real Weight")
        XCTAssertEqual(weightStyle.series, "C")
        XCTAssertEqual(weightStyle.color, Color.weightGreen)
        
        let expectedWeightStyle = PlotStyleType.expectedWeight
        XCTAssertEqual(expectedWeightStyle.foregroundStyle, "Expected Weight")
        XCTAssertEqual(expectedWeightStyle.xValueLabel, "Days ago")
        XCTAssertEqual(expectedWeightStyle.yValueLabel, "Expected Weight")
        XCTAssertEqual(expectedWeightStyle.series, "A")
        XCTAssertEqual(expectedWeightStyle.color, Color.expectedWeightYellow)
        
        let realisticWeightStyle = PlotStyleType.realisticWeight
        XCTAssertEqual(realisticWeightStyle.foregroundStyle, "Realistic Weight")
        XCTAssertEqual(realisticWeightStyle.xValueLabel, "Days ago")
        XCTAssertEqual(realisticWeightStyle.yValueLabel, "Realistic Weight")
        XCTAssertEqual(realisticWeightStyle.series, "D")
        XCTAssertEqual(realisticWeightStyle.color, Color.realisticWeightGreen)
        
        let expectedWeightTomorrowStyle = PlotStyleType.expectedWeightTomorrow
        XCTAssertEqual(expectedWeightTomorrowStyle.foregroundStyle, "Expected Weight Tomorrow")
        XCTAssertEqual(expectedWeightTomorrowStyle.xValueLabel, "Days ago")
        XCTAssertEqual(expectedWeightTomorrowStyle.yValueLabel, "Expected Weight Tomorrow")
        XCTAssertEqual(expectedWeightTomorrowStyle.series, "B")
        XCTAssertEqual(expectedWeightTomorrowStyle.color, Color.expectedWeightTomorrowYellow)
    }
    
    func testPlotViewModel() {
        let day = Day(date: Date(), daysAgo: 0, activeCalories: 3500, expectedWeight: 68, realisticWeight: 69, weight: 70)
        
        // Test for week time frame
        var timeFrame = TimeFrame(type: .week)
        
        let weightViewModel = PlotViewModel(type: .weight, day: day, timeFrame: timeFrame)
        XCTAssertEqual(weightViewModel.xValue, day.date)
        XCTAssertEqual(weightViewModel.xValueLabel, "Days ago")
        XCTAssertEqual(weightViewModel.yValue, 70)
        XCTAssertEqual(weightViewModel.yValueLabel, "Real Weight")
        XCTAssertEqual(weightViewModel.foregroundStyle, "Weight")
        XCTAssertEqual(weightViewModel.series, "C")
        XCTAssertEqual(weightViewModel.dateOverlay, day.firstLetterOfDay)
        XCTAssertEqual(weightViewModel.pointStyle as! Color, weightViewModel.type.color)
        XCTAssertTrue(weightViewModel.shouldDisplay)
        XCTAssertTrue(weightViewModel.shouldHavePoint)
        XCTAssertFalse(weightViewModel.shouldHaveDayOverlay)
        XCTAssertFalse(weightViewModel.shouldIndicateMissedDays)
        
        let expectedWeightViewModel = PlotViewModel(type: .expectedWeight, day: day, timeFrame: timeFrame)
        XCTAssertEqual(expectedWeightViewModel.xValue, day.date)
        XCTAssertEqual(expectedWeightViewModel.xValueLabel, "Days ago")
        XCTAssertEqual(expectedWeightViewModel.yValue, 68)
        XCTAssertEqual(expectedWeightViewModel.yValueLabel, "Expected Weight")
        XCTAssertEqual(expectedWeightViewModel.foregroundStyle, "Expected Weight")
        XCTAssertEqual(expectedWeightViewModel.series, "A")
        XCTAssertEqual(expectedWeightViewModel.dateOverlay, day.firstLetterOfDay)
        XCTAssertEqual(expectedWeightViewModel.pointStyle as! Color, expectedWeightViewModel.type.color)
        XCTAssertTrue(expectedWeightViewModel.shouldDisplay)
        XCTAssertTrue(expectedWeightViewModel.shouldHavePoint)
        XCTAssertTrue(expectedWeightViewModel.shouldHaveDayOverlay)
        XCTAssertTrue(expectedWeightViewModel.shouldIndicateMissedDays)
        
        let realisticWeightViewModel = PlotViewModel(type: .realisticWeight, day: day, timeFrame: timeFrame)
        XCTAssertEqual(realisticWeightViewModel.xValue, day.date)
        XCTAssertEqual(realisticWeightViewModel.xValueLabel, "Days ago")
        XCTAssertEqual(realisticWeightViewModel.yValue, 69)
        XCTAssertEqual(realisticWeightViewModel.yValueLabel, "Realistic Weight")
        XCTAssertEqual(realisticWeightViewModel.foregroundStyle, "Realistic Weight")
        XCTAssertEqual(realisticWeightViewModel.series, "D")
        XCTAssertEqual(realisticWeightViewModel.dateOverlay, day.firstLetterOfDay)
        XCTAssertEqual(realisticWeightViewModel.pointStyle as! Color, realisticWeightViewModel.type.color)
        XCTAssertTrue(realisticWeightViewModel.shouldDisplay)
        XCTAssertTrue(realisticWeightViewModel.shouldHavePoint)
        XCTAssertFalse(realisticWeightViewModel.shouldHaveDayOverlay)
        XCTAssertFalse(realisticWeightViewModel.shouldIndicateMissedDays)
        
        let expectedWeightTomorrowViewModel = PlotViewModel(type: .expectedWeightTomorrow, day: day, timeFrame: timeFrame)
        XCTAssertEqual(expectedWeightTomorrowViewModel.xValue, day.date)
        XCTAssertEqual(expectedWeightTomorrowViewModel.xValueLabel, "Days ago")
        XCTAssertEqual(expectedWeightTomorrowViewModel.yValue, 68)
        XCTAssertEqual(expectedWeightTomorrowViewModel.yValueLabel, "Expected Weight Tomorrow")
        XCTAssertEqual(expectedWeightTomorrowViewModel.foregroundStyle, "Expected Weight Tomorrow")
        XCTAssertEqual(expectedWeightTomorrowViewModel.series, "B")
        XCTAssertEqual(expectedWeightTomorrowViewModel.dateOverlay, day.firstLetterOfDay)
        XCTAssertEqual(expectedWeightTomorrowViewModel.pointStyle as! Color, expectedWeightTomorrowViewModel.type.color)
        XCTAssertTrue(expectedWeightTomorrowViewModel.shouldDisplay)
        XCTAssertFalse(expectedWeightTomorrowViewModel.shouldHavePoint)
        XCTAssertFalse(expectedWeightTomorrowViewModel.shouldHaveDayOverlay)
        XCTAssertFalse(expectedWeightTomorrowViewModel.shouldIndicateMissedDays)
        
        // Ensure the points become red when they should
        day.wasModifiedBecauseTheUserDidntEnterData = true
        XCTAssertEqual(expectedWeightViewModel.pointStyle as! Color, Color.red)
        XCTAssertEqual(expectedWeightTomorrowViewModel.pointStyle as! Color, expectedWeightTomorrowViewModel.type.color)
        XCTAssertEqual(realisticWeightViewModel.pointStyle as! Color, realisticWeightViewModel.type.color)
        XCTAssertEqual(weightViewModel.pointStyle as! Color, weightViewModel.type.color)
        
        // Ensure dots disappear after a month
        timeFrame = TimeFrame(type: .month)
        let longAgoDay = Day(daysAgo: 34, activeCalories: 3500, expectedWeight: 68, realisticWeight: 69, weight: 70)
        let longAgoWeightViewModel = PlotViewModel(type: .weight, day: longAgoDay, timeFrame: timeFrame)
        XCTAssertFalse(longAgoWeightViewModel.shouldHavePoint)
        
        // Ensure day of week labels don't show up after a week
        timeFrame = TimeFrame(type: .week)
        let dayOfWeekViewModel = PlotViewModel(type: .expectedWeight, day: day, timeFrame: timeFrame)
        XCTAssertTrue(dayOfWeekViewModel.shouldHaveDayOverlay)
        
        timeFrame = TimeFrame(type: .month)
        let dayOfMonthViewModel = PlotViewModel(type: .expectedWeight, day: day, timeFrame: timeFrame)
        XCTAssertFalse(dayOfMonthViewModel.shouldHaveDayOverlay)
    }
    
    func testLineChartViewModel() {
        let day1 = Day(date: Date(), daysAgo: 0, expectedWeight: 68, realisticWeight: 69, weight: 70)
        let day2 = Day(date: Date().addingTimeInterval(-86400), daysAgo: 1, expectedWeight: 69, realisticWeight: 70, weight: 71)
        var days = Days()
        days[0] = day1
        days[1] = day2
        let timeFrame = TimeFrame(type: .week)
        
        let viewModel = LineChartViewModel(days: days, timeFrame: timeFrame)
        XCTAssertEqual(viewModel.days.count, 3)
        XCTAssertEqual(viewModel.maxValue, 71)
        XCTAssertEqual(viewModel.minValue, 68)
        
        viewModel.populateDays(for: days)
        XCTAssertEqual(viewModel.days.count, 3)
        
        let constructedDays = viewModel.constructDays(using: days)
        XCTAssertEqual(constructedDays.count, 3)
        
        viewModel.updateMinMaxValues(days: constructedDays)
        XCTAssertEqual(viewModel.maxValue, 71)
        XCTAssertEqual(viewModel.minValue, 68)
    }
    
    func testLineChartViewModel_constructDays() {
        let day1 = Day(daysAgo: 0, expectedWeight: 68, realisticWeight: 69, weight: 70)
        let day2 = Day(daysAgo: 1, expectedWeight: 69, realisticWeight: 70, weight: 71)
        var days = Days()
        days[0] = day1
        days[1] = day2
        let timeFrame = TimeFrame(type: .week)
        let viewModel = LineChartViewModel(days: days, timeFrame: timeFrame)
        var constructedDays = viewModel.constructDays(using: days)
        // Ensure tomorrow is added
        XCTAssertEqual(constructedDays.count, 3)
        XCTAssertEqual(constructedDays.sortedMostRecentToLongestAgo().first?.daysAgo, -1)
        // Ensure tomorrow's weight
        XCTAssertEqual(constructedDays.first?.expectedWeight, constructedDays[1].expectedWeightTomorrow)
        // Ensure that filtering by timeframe takes place
        let dayOutsideOfTimeframe = Day(daysAgo: 10, expectedWeight: 68, realisticWeight: 69, weight: 70)
        let dayInsideOfTimeframe = Day(daysAgo: 7, expectedWeight: 68, realisticWeight: 69, weight: 70)
        XCTAssertTrue(days.append(dayOutsideOfTimeframe))
        XCTAssertTrue(days.append(dayInsideOfTimeframe))
        constructedDays = viewModel.constructDays(using: days)
        XCTAssertEqual(constructedDays.count, 4)
        // Ensure proper sorting
        XCTAssertEqual(constructedDays.first?.daysAgo, -1)
        XCTAssertEqual(constructedDays.last?.daysAgo, 7)
    }
    
}
