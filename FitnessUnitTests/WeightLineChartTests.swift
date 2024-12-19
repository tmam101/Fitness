//
//  WeightLineChartTests.swift
//  Fitness
//
//  Created by Thomas on 5/31/24.
//

import Testing
@testable import Fitness
import SwiftUI

extension Tag {
  @Tag static var timeFrame: Self
}

@Suite struct WeightLineChartTests {
    
    var allTimeDay = Day(daysAgo: 34, activeCalories: 3500, expectedWeight: 68, realisticWeight: 69, weight: 70)
    var day: Day!
    
    init() {
        self.day = Day(date: Date(), daysAgo: 0, activeCalories: 3500, expectedWeight: 68, realisticWeight: 69, weight: 70)
    }
    
    @Test func plotStyleTypeProperties() {
        let weightStyle = PlotStyleType.weight
        #expect(weightStyle.foregroundStyle == "Weight")
        #expect(weightStyle.xValueLabel == "Days ago")
        #expect(weightStyle.yValueLabel == "Real Weight")
        #expect(weightStyle.series == "C")
        #expect(weightStyle.color == Color.weightGreen)
        
        let expectedWeightStyle = PlotStyleType.expectedWeight
        #expect(expectedWeightStyle.foregroundStyle == "Expected Weight")
        #expect(expectedWeightStyle.xValueLabel == "Days ago")
        #expect(expectedWeightStyle.yValueLabel == "Expected Weight")
        #expect(expectedWeightStyle.series == "A")
        #expect(expectedWeightStyle.color == Color.expectedWeightYellow)
        
        let realisticWeightStyle = PlotStyleType.realisticWeight
        #expect(realisticWeightStyle.foregroundStyle == "Realistic Weight")
        #expect(realisticWeightStyle.xValueLabel == "Days ago")
        #expect(realisticWeightStyle.yValueLabel == "Realistic Weight")
        #expect(realisticWeightStyle.series == "D")
        #expect(realisticWeightStyle.color == Color.realisticWeightGreen)
        
        let expectedWeightTomorrowStyle = PlotStyleType.expectedWeightTomorrow
        #expect(expectedWeightTomorrowStyle.foregroundStyle == "Expected Weight Tomorrow")
        #expect(expectedWeightTomorrowStyle.xValueLabel == "Days ago")
        #expect(expectedWeightTomorrowStyle.yValueLabel == "Expected Weight Tomorrow")
        #expect(expectedWeightTomorrowStyle.series == "B")
        #expect(expectedWeightTomorrowStyle.color == Color.expectedWeightTomorrowYellow)
    }
    
    @Test("Weight plot view model", .tags(.timeFrame), arguments: TimeFrame.allCases)
    func weightPlotViewModel(timeFrame: TimeFrame) {
        let weightViewModel = PlotViewModel(type: .weight, day: day, timeFrame: timeFrame)
        
        switch timeFrame {
        case .allTime:
            #expect(!weightViewModel.shouldHavePoint)
        case .month:
            #expect(weightViewModel.shouldHavePoint)
        case .week:
            #expect(weightViewModel.shouldHavePoint)
        }
        #expect(weightViewModel.xValue == day.date)
        #expect(weightViewModel.xValueLabel == "Days ago")
        #expect(weightViewModel.yValue == 70)
        #expect(weightViewModel.yValueLabel == "Real Weight")
        #expect(weightViewModel.foregroundStyle == "Weight")
        #expect(weightViewModel.series == "C")
        #expect(weightViewModel.dateOverlay == day.firstLetterOfDay)
        #expect(weightViewModel.pointStyle as! Color == weightViewModel.type.color)
        #expect(weightViewModel.shouldDisplay)
        #expect(!weightViewModel.shouldHaveDayOverlay)
        #expect(!weightViewModel.shouldIndicateMissedDays)
    }
    
    
    @Test("Exepected weight plot view model", .tags(.timeFrame), arguments: TimeFrame.allCases)
    func expectedWeightPlotViewModel(timeFrame: TimeFrame) {
        let expectedWeightViewModel = PlotViewModel(type: .expectedWeight, day: day, timeFrame: timeFrame)
        switch timeFrame {
        case .allTime:
            #expect(!expectedWeightViewModel.shouldHavePoint)
            #expect(!expectedWeightViewModel.shouldHaveDayOverlay)
            #expect(!expectedWeightViewModel.shouldIndicateMissedDays)
        case .month:
            #expect(expectedWeightViewModel.shouldHavePoint)
            #expect(!expectedWeightViewModel.shouldHaveDayOverlay)
            #expect(expectedWeightViewModel.shouldIndicateMissedDays)
        case .week:
            #expect(expectedWeightViewModel.shouldHavePoint)
            #expect(expectedWeightViewModel.shouldHaveDayOverlay)
            #expect(expectedWeightViewModel.shouldIndicateMissedDays)
        }
        
        #expect(expectedWeightViewModel.xValue == day.date)
        #expect(expectedWeightViewModel.xValueLabel == "Days ago")
        #expect(expectedWeightViewModel.yValue == 68)
        #expect(expectedWeightViewModel.yValueLabel == "Expected Weight")
        #expect(expectedWeightViewModel.foregroundStyle == "Expected Weight")
        #expect(expectedWeightViewModel.series == "A")
        #expect(expectedWeightViewModel.dateOverlay == day.firstLetterOfDay)
        #expect(expectedWeightViewModel.pointStyle as! Color == expectedWeightViewModel.type.color)
        #expect(expectedWeightViewModel.shouldDisplay)
    }
    
    @Test("Expected weight tomorrow plot view model", .tags(.timeFrame), arguments: TimeFrame.allCases)
    func expectedWeightTomorrowPlotViewModel(timeFrame: TimeFrame) {
        let expectedWeightTomorrowViewModel = PlotViewModel(type: .expectedWeightTomorrow, day: day, timeFrame: timeFrame)
        #expect(expectedWeightTomorrowViewModel.xValue == day.date)
        #expect(expectedWeightTomorrowViewModel.xValueLabel == "Days ago")
        #expect(expectedWeightTomorrowViewModel.yValue == 68)
        #expect(expectedWeightTomorrowViewModel.yValueLabel == "Expected Weight Tomorrow")
        #expect(expectedWeightTomorrowViewModel.foregroundStyle == "Expected Weight Tomorrow")
        #expect(expectedWeightTomorrowViewModel.series == "B")
        #expect(expectedWeightTomorrowViewModel.dateOverlay == day.firstLetterOfDay)
        #expect(expectedWeightTomorrowViewModel.pointStyle as! Color == expectedWeightTomorrowViewModel.type.color)
        #expect(expectedWeightTomorrowViewModel.shouldDisplay)
        #expect(!expectedWeightTomorrowViewModel.shouldHavePoint)
        #expect(!expectedWeightTomorrowViewModel.shouldHaveDayOverlay)
        #expect(!expectedWeightTomorrowViewModel.shouldIndicateMissedDays)
    }
    
    @Test("Realistic weight plot view model", .tags(.timeFrame), arguments: TimeFrame.allCases)
    func realisticWeightPlotViewModel(timeFrame: TimeFrame) {
        let realisticWeightViewModel = PlotViewModel(type: .realisticWeight, day: day, timeFrame: timeFrame)
        switch timeFrame {
        case .allTime:
            #expect(!realisticWeightViewModel.shouldHavePoint)
        case .month:
            #expect(realisticWeightViewModel.shouldHavePoint)
        case .week:
            #expect(realisticWeightViewModel.shouldHavePoint)
        }
        #expect(realisticWeightViewModel.xValue == day.date)
        #expect(realisticWeightViewModel.xValueLabel == "Days ago")
        #expect(realisticWeightViewModel.yValue == 69)
        #expect(realisticWeightViewModel.yValueLabel == "Realistic Weight")
        #expect(realisticWeightViewModel.foregroundStyle == "Realistic Weight")
        #expect(realisticWeightViewModel.series == "D")
        #expect(realisticWeightViewModel.dateOverlay == day.firstLetterOfDay)
        #expect(realisticWeightViewModel.pointStyle as! Color == realisticWeightViewModel.type.color)
        #expect(realisticWeightViewModel.shouldDisplay)
        #expect(!realisticWeightViewModel.shouldHaveDayOverlay)
        #expect(!realisticWeightViewModel.shouldIndicateMissedDays)
    }
    
    @Test("Points become red when they should", .tags(.timeFrame), arguments: TimeFrame.allCases)
    func pointsBecomeRedWhenTheyShould(timeFrame: TimeFrame) {
        let expectedWeightViewModel = PlotViewModel(type: .expectedWeight, day: day, timeFrame: timeFrame)
        let expectedWeightTomorrowViewModel = PlotViewModel(type: .expectedWeightTomorrow, day: day, timeFrame: timeFrame)
        let weightViewModel = PlotViewModel(type: .weight, day: day, timeFrame: timeFrame)
        let realisticWeightViewModel = PlotViewModel(type: .realisticWeight, day: day, timeFrame: timeFrame)
        
        day.wasModifiedBecauseTheUserDidntEnterData = true
        
        switch timeFrame {
        case .allTime:
            #expect(expectedWeightViewModel.pointStyle as! Color == expectedWeightViewModel.type.color)
            #expect(!expectedWeightViewModel.shouldIndicateMissedDays)
        case .month, .week:
            #expect(expectedWeightViewModel.pointStyle as! Color == Color.red)
            #expect(expectedWeightViewModel.shouldIndicateMissedDays)
        }
        
        #expect(!expectedWeightTomorrowViewModel.shouldIndicateMissedDays)
        #expect(!weightViewModel.shouldIndicateMissedDays)
        #expect(!realisticWeightViewModel.shouldIndicateMissedDays)
        
        #expect(expectedWeightTomorrowViewModel.pointStyle as! Color == expectedWeightTomorrowViewModel.type.color)
        #expect(realisticWeightViewModel.pointStyle as! Color == realisticWeightViewModel.type.color)
        #expect(weightViewModel.pointStyle as! Color == weightViewModel.type.color)
    }
    
    @Test("Points dont show after month", .tags(.timeFrame), arguments: TimeFrame.allCases)
    func pointsDontShowAfterMonth(timeFrame: TimeFrame) {
        let longAgoWeightViewModel = PlotViewModel(type: .weight, day: day, timeFrame: timeFrame)
        switch timeFrame {
        case .allTime:
            #expect(!longAgoWeightViewModel.shouldHavePoint)
        case .month:
            #expect(longAgoWeightViewModel.shouldHavePoint)
        case .week:
            #expect(longAgoWeightViewModel.shouldHavePoint)
        }
    }
    
    @Test("Dont indicate missed days for all time", .tags(.timeFrame), arguments: TimeFrame.allCases)
    func dontIndicateMissedDaysForAllTime(timeFrame: TimeFrame) {
        let longAgoExpectedWeightViewModel = PlotViewModel(type: .expectedWeight, day: allTimeDay, timeFrame: timeFrame)
        switch timeFrame {
        case .allTime:
            #expect(!longAgoExpectedWeightViewModel.shouldIndicateMissedDays)
        case .month:
            #expect(longAgoExpectedWeightViewModel.shouldIndicateMissedDays)
        case .week:
            #expect(longAgoExpectedWeightViewModel.shouldIndicateMissedDays)
        }
    }
    
    @Test func dayOfWeekLabelsDontShowAfterWeek() {
        let day = Day(date: Date(), daysAgo: 0, activeCalories: 3500, expectedWeight: 68, realisticWeight: 69, weight: 70)
        // Ensure day of week labels don't show up after a week
        var timeFrame = TimeFrame.week
        let dayOfWeekViewModel = PlotViewModel(type: .expectedWeight, day: day, timeFrame: timeFrame)
        #expect(dayOfWeekViewModel.shouldHaveDayOverlay)
        
        timeFrame = .month
        let dayOfMonthViewModel = PlotViewModel(type: .expectedWeight, day: day, timeFrame: timeFrame)
        #expect(!dayOfMonthViewModel.shouldHaveDayOverlay)
    }
    
    @Test func pointsDontShowOnEstimatedWeights() {
        let day1 = Day(daysAgo: 0, weight: 70)
        let day2 = Day(daysAgo: 1)
        let day3 = Day(daysAgo: 2, weight: 72)
        
        var days = Days()
        #expect(days.append([day1, day2, day3]) == true)
        days.setWeightOnEveryDay()
        #expect(day2.weight == 71)
        #expect(day2.weightWasEstimated)
        for timeFrame in TimeFrame.allCases {
            let vm = PlotViewModel(type: .weight, day: day2, timeFrame: timeFrame)
            #expect(!vm.shouldHavePoint)
        }
    }
    
    @Test func lineChartViewModel() {
        let day1 = Day(date: Date(), daysAgo: 0,
                      expectedWeight: 68,  // Middle
                      realisticWeight: 65, // Minimum
                      weight: 70)          // Middle
        let day2 = Day(date: Date().addingTimeInterval(-86400), daysAgo: 1,
                      expectedWeight: 72,  // Maximum
                      realisticWeight: 69, // Middle
                      weight: 67)          // Middle
        var days = Days()
        days[0] = day1
        days[1] = day2
        let timeFrame = TimeFrame.week
        
        let viewModel = LineChartViewModel(days: days, timeFrame: timeFrame)
        
        #expect(viewModel.days.count == 3)
        #expect(viewModel.maxValue == 72) // Should be day2's expectedWeight
        #expect(viewModel.minValue == 65) // Should be day1's realisticWeight
        
        viewModel.updateMinMaxValues(days: viewModel.days)
        #expect(viewModel.maxValue == 72) // Should still be day2's expectedWeight
        #expect(viewModel.minValue == 65) // Should still be day1's realisticWeight
        
        let day3 = Day(date: Date().addingTimeInterval(-172800), daysAgo: 2,
                      expectedWeight: 69,  // Middle
                      realisticWeight: 75, // New maximum
                      weight: 63)          // New minimum
        days[2] = day3
        
        viewModel.populateDays(for: days)
        #expect(viewModel.maxValue == 75) // Should be day3's realisticWeight
        #expect(viewModel.minValue == 63) // Should be day3's weight
    }

    @Test func lineChartViewModel_constructDays() {
        let day1 = Day(daysAgo: 0, expectedWeight: 68, realisticWeight: 69, weight: 70)
        let day2 = Day(daysAgo: 1, expectedWeight: 69, realisticWeight: 70, weight: 71)
        var days = Days()
        days[0] = day1
        days[1] = day2
        let timeFrame = TimeFrame.week
        let viewModel = LineChartViewModel(days: days, timeFrame: timeFrame)
        var constructedDays = viewModel.constructDays(using: days)
        // Ensure tomorrow is added
        #expect(constructedDays.count == 3)
        #expect(constructedDays.sorted(.mostRecentToLongestAgo).first?.daysAgo == -1)
        // Ensure tomorrow's weight
        #expect(constructedDays.first?.expectedWeight == constructedDays[1].expectedWeightTomorrow)
        // Ensure that filtering by timeframe takes place
        let dayOutsideOfTimeframe = Day(daysAgo: 8, expectedWeight: 68, realisticWeight: 69, weight: 70)
        let dayInsideOfTimeframe = Day(daysAgo: 7, expectedWeight: 68, realisticWeight: 69, weight: 70)
        #expect(days.append(dayOutsideOfTimeframe) == true)
        #expect(days.append(dayInsideOfTimeframe) == true)
        constructedDays = viewModel.constructDays(using: days)
        #expect(constructedDays.count == 4)
        // Ensure proper sorting
        #expect(constructedDays.first?.daysAgo == -1)
        #expect(constructedDays.last?.daysAgo == 7)
    }
}
