//
//  FitnessUnitTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 10/10/23.
//

import Testing
@testable import Fitness
import Combine
import Foundation

// TODO: Put this into HealthData. So it goes through the real process, and can detect errors in HealthData and CalorieManager.

@Suite

final class DayUnitTests {
    
    var day: Day!
    var days: Days?
    
    init() {
        day = Day()
    }
    
    deinit {
        day = nil
        days = nil
    }
    
    @Test func decoding() {
        guard
            let _: [Decimal] = .decode(path: .activeCalories),
            let _: [Decimal] = .decode(path: .restingCalories),
            let _: [Decimal] = .decode(path: .consumedCalories),
            let _: [Decimal] = .decode(path: .upAndDownWeights),
            let _: [Decimal] = .decode(path: .missingConsumedCalories),
            let _: [Decimal] = .decode(path: .weightGoingSteadilyDown)
        else {
            Issue.record()
            return
        }
    }
    
    @Test func average() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        let sum = days.sum(property: .activeCalories)
        let average = days.average(property: .activeCalories)
        #expect(sum / Decimal(days.count) == average, "Calculated average does not match expected value")
    }
    
    @Test func dayDates() {
        days = Days.testDays()
        guard let days else { Issue.record()
            return
        }
        
        #expect(Date.daysBetween(date1: days[0]!.date, date2: days[30]!.date) == 30)
    }
    
    @Test func extractedDays() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        var newDays = days.subset(from: 0, through: 10)
        #expect(newDays.count == 11, "Extracted days count should match")
        newDays = days.subset(from: 10, through: 0)
        #expect(newDays.count == 11, "Extracted days count should match")
    }
    
    @Test func allTimeAverage() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        let allTimeAverageExceptToday = days.averageDeficitOfPrevious(days: TimeFrame.allTime.days, endingOnDay: 1) ?? 0.0
        let allDaysExceptToday = days.subset(from: 1, through: days.count - 1)
        guard let averageExceptToday = allDaysExceptToday.average(property: .deficit) else {
            Issue.record()
            return
        }
        #expect(allTimeAverageExceptToday.isApproximately(averageExceptToday, accuracy: 0.1))
        
        let allTimeAverage = days.averageDeficitOfPrevious(days: TimeFrame.allTime.days, endingOnDay: 0) ?? 0.0
        let allDays = days.subset(from: 0, through: days.count - 1)
        if let average = allDays.average(property: .deficit) {
            #expect(allTimeAverage.isApproximately(average, accuracy: 0.1), "Calculated average does not match expected value")
        } else {
            Issue.record()
        }
    }
    
    @Test func weeklyAverage() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        let weeklyAverage = days.averageDeficitOfPrevious(days: TimeFrame.week.days, endingOnDay: 1) ?? 0.0
        if let calculatedAverage = days.subset(from: TimeFrame.week.days, through: 1).average(property: .deficit) {
            #expect(weeklyAverage.isApproximately(calculatedAverage, accuracy: 0.1))
        } else {
            Issue.record()
        }
    }
    
    @Test func deficitAndSurplusAndRunningTotalDeficitAlign() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        let totalSurplus = days.sum(property: .netEnergy)
        let totalDeficit = days.sum(property: .deficit)
        if let runningTotalDeficit = days[0]?.runningTotalDeficit {
            #expect(totalSurplus.isApproximately(-totalDeficit, accuracy: 0.1))
            #expect(totalDeficit.isApproximately(runningTotalDeficit, accuracy: 0.1))
        } else {
            Issue.record()
        }
    }
    
//        //TODO: Test that tomorrow's all time equals today's predicted for all time tomorrow
//        func testSomething() {
//            let a = days.averageDeficitOfPrevious(days: 30, endingOnDay: 1)
//            let b = days.averageDeficitOfPrevious(days: 30, endingOnDay: 0)
//    //        XCTAssertEqual(days.averageDeficitOfPrevious(days: 30, endingOnDay: 1), <#T##expression2: Equatable##Equatable#>)
//        }
    
    @Test func expectedWeightTomorrow() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        #expect(days[1]!.expectedWeight.isApproximately(days[2]!.expectedWeightTomorrow, accuracy: 0.001))
    }
    
    @Test func deficitProperty() {
        day.activeCalories = 500
        day.restingCalories = 2000
        day.consumedCalories = 2000
        #expect(day.deficit == 500)
    }
    
    @Test func activeCalorieToDeficitRatio() {
        day.activeCalories = 250
        day.restingCalories = 2750
        day.consumedCalories = 2500
        #expect(day.activeCalorieToDeficitRatio == 0.5)
    }
    
    @Test func proteinPercentage() {
        day.protein = 100
        day.consumedCalories = 2000
        #expect(day.proteinPercentage == 0.2)
    }
    
    @Test func proteinGoalPercentage() {
        day.protein = 100
        day.consumedCalories = 2000
        #expect(day.proteinGoalPercentage.isApproximately(0.6666666667, accuracy: 0.01))
    }
    
    @Test func expectedWeightChangeBasedOnDeficit() {
        day.activeCalories = 500
        day.restingCalories = 2000
        day.consumedCalories = 2000
        #expect(day.expectedWeightChangeBasedOnDeficit.isApproximately(-0.14, accuracy: 0.01))
    }
    
    @Test func testDays() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        #expect(days.count != 0)
    }
    
    @Test func addingRunningTotalDeficits() throws {
        days = Days.testDays()
        guard let days, let today = days[0] else {
            Issue.record()
            return
        }
        
        // Test that today's runningTotalDeficit is the sum of all deficits
        let todaysRunningTotalDeficit = today.runningTotalDeficit
        let shouldBe = days.sum(property: .deficit)
        #expect(todaysRunningTotalDeficit.isApproximately(shouldBe, accuracy: 0.1))
        
        // Test that the first day's deficit is the same as the runningTotalDeficit
        if let firstDay = days[days.count-1] {
            #expect(firstDay.deficit.isApproximately(firstDay.runningTotalDeficit, accuracy: 0.1))
        }
    }
    
    // TODO Finish
//    @Test func averageProperties() {
//        days = Days.testDays()
//        guard let days else {
//            Issue.record()
//            return
//        }
//        
//        let averageActiveCalories = days.averageDeficitOfPrevious(days: 7, endingOnDay: 0)
//    }
    
    @Test func sumPropertyActiveCalories() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        let total = days.sum(property: .activeCalories)
        #expect(total == days.values.reduce(0) {$0 + $1.activeCalories})
    }
    
    // Test with edge case of zero days
    @Test func zeroDaysAverage() {
        let days = Days()
        let average = days.average(property: .activeCalories)
        #expect(average == nil, "Average should be nil for zero days")
    }
    
    // Test for edge case where start and end index are same
    @Test func singleDayExtracted() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        let newDays = days.subset(from: 5, through: 5)
        #expect(newDays.count == 1, "Extracted days count should be 1")
    }
    
    // Test with an edge case of large number of days
    @Test func largeNumberOfDaysAverageDeficit() {
        days = Days.testDays()
        guard let days else {
            Issue.record()
            return
        }
        
        let average = days.averageDeficitOfPrevious(days: 100000, endingOnDay: 1)
        #expect(average != nil, "Average should not be nil")
    }
    
    // Test for negative deficit values
    @Test func negativeDeficit() {
        day.activeCalories = 500
        day.restingCalories = 2000
        day.consumedCalories = 3000
        #expect(day.deficit == -500, "Deficit should be set to negative value")
    }
    
    @Test func setWeightsOnEveryDay() {
        for _ in 0...10 {
            days = Days.testDays(options: .init([.dontAddWeightsOnEveryDay]))
            guard let days else {
                Issue.record()
                return
            }
            // Ensure there are empty weights at first
            var daysWithoutWeights = days.array().filter { $0.weight == 0 }
            #expect(daysWithoutWeights.count != 0)
            
            // Set weights on every day
            // Ensure the existing weights are the same after the calculation
            let originalDaysAndWeights = days.array().filter { $0.weight != 0 }.map { ($0.daysAgo, $0.weight) }
            days.setWeightOnEveryDay()
            for x in originalDaysAndWeights {
                #expect(days[x.0]?.weight == x.1)
            }
            
            // Ensure the only empty days are the ones closest to now, if you havent weighed yourself
            daysWithoutWeights = days.array().filter { $0.weight == 0 }
            if daysWithoutWeights.count != 0 {
                for x in 0..<daysWithoutWeights.count {
                    #expect(days[x]?.weight == 0)
                }
            }
            
            // TODO: Now the logic adds weights closes to now if you havent weighed yourself
        }
        // Ensure the calculations are correct
        var d: Days = [:]
        d[0] = Day(date: daysAgo(0), daysAgo: 0, weight: 1)
        d[1] = Day(date: daysAgo(1), daysAgo: 1, weight: 0)
        d[2] = Day(date: daysAgo(2), daysAgo: 2, weight: 3)
        d[3] = Day(date: daysAgo(3), daysAgo: 3, weight: 0)
        d[4] = Day(date: daysAgo(4), daysAgo: 4, weight: 0)
        d[5] = Day(date: daysAgo(5), daysAgo: 5, weight: 3.3)
        d[6] = Day(date: daysAgo(6), daysAgo: 6, weight: 0)
        d[7] = Day(date: daysAgo(7), daysAgo: 7, weight: 1)
        d.setWeightOnEveryDay()
        #expect(d[1]?.weight == 2)
        #expect(d[3]!.weight.isApproximately(3.1, accuracy: 0.01))
        #expect(d[4]!.weight.isApproximately(3.2, accuracy: 0.01))
        #expect(d[6]!.weight.isApproximately(2.15, accuracy: 0.01))
    }
    
    @Test func weightsOnEveryDaySimple() {
        var d: Days = [:]
        d[0] = Day(date: daysAgo(0), daysAgo: 0, weight: 1)
        d[1] = Day(date: daysAgo(1), daysAgo: 1, weight: 0)
        d[2] = Day(date: daysAgo(2), daysAgo: 2, weight: 3)
        d[3] = Day(date: daysAgo(3), daysAgo: 3, weight: 0)
        d[4] = Day(date: daysAgo(4), daysAgo: 4, weight: 0)
        d[5] = Day(date: daysAgo(5), daysAgo: 5, weight: 3.3)
        d[6] = Day(date: daysAgo(6), daysAgo: 6, weight: 0)
        d[7] = Day(date: daysAgo(7), daysAgo: 7, weight: 1)
        d.setWeightOnEveryDay()
        #expect(d[1]?.weight == 2)
        #expect(d[3]!.weight.isApproximately(3.1, accuracy: 0.01))
        #expect(d[4]!.weight.isApproximately(3.2, accuracy: 0.01))
        #expect(d[6]!.weight.isApproximately(2.15, accuracy: 0.01))
    }
    
    @Test func recentDaysKeepRecentWeight() {
        var d: Days = [:]
        d[0] = Day(date: daysAgo(0), daysAgo: 0, weight: 0)
        d[1] = Day(date: daysAgo(1), daysAgo: 1, weight: 1)
        d[2] = Day(date: daysAgo(2), daysAgo: 2, weight: 0)
        d[3] = Day(date: daysAgo(3), daysAgo: 3, weight: 3)
        d[4] = Day(date: daysAgo(4), daysAgo: 4, weight: 0)
        d[5] = Day(date: daysAgo(5), daysAgo: 5, weight: 0)
        d[6] = Day(date: daysAgo(6), daysAgo: 6, weight: 3.3)
        d[7] = Day(date: daysAgo(7), daysAgo: 7, weight: 0)
        d[8] = Day(date: daysAgo(8), daysAgo: 8, weight: 1)
        d.setWeightOnEveryDay()
        #expect(d[0]?.weight == 1)
        #expect(d[2]?.weight == 2)
        #expect(d[4]!.weight.isApproximately(3.1, accuracy: 0.01))
        #expect(d[5]!.weight.isApproximately(3.2, accuracy: 0.01))
        #expect(d[7]!.weight.isApproximately(2.15, accuracy: 0.01))
    }
    
    func daysAgo(_ num: Int) -> Date {
        Date.subtract(days: num, from: Date())
    }
    
    // TODO Figure out how to make a test like this work on CI
//    @Test func dayOfWeek() {
//        days = Days.testDays(options: .init([.testCase(.missingDataIssue)]))
//        #expect(days?[0]?.dayOfWeek == "Thursday")
//    }
    
    @Test func decodingTestCases() {
        for path in Filepath.Days.allCases {
            days = Days.decode(path: path)
            #expect(days != nil)
        }
    }
    
    @Test func encodingJSON() {
        days = Days.decode(path: .missingDataIssue)
        #expect(days.encodeAsString() != nil)
    }
    
    @Test("Missing day adjustment", arguments: Filepath.Days.allCases)
    func missingDayAdjustment(path: Filepath.Days) {
        days = Days.testDays(options: .init(testCase: path))
        guard let days else {
            Issue.record()
            return
        }
        days.forEveryDay { day in
            if day.wasModifiedBecauseTheUserDidntEnterData {
                if let tomorrow = days.dayAfter(day) {
                    let realisticWeightChangeTomorrowBasedOnToday = tomorrow.realisticWeight - day.expectedWeight
                    if realisticWeightChangeTomorrowBasedOnToday > Constants.maximumWeightChangePerDay {
                        #expect(day.expectedWeightChangeBasedOnDeficit.isApproximately(Constants.maximumWeightChangePerDay, accuracy: 0.1))
                    } else if realisticWeightChangeTomorrowBasedOnToday < -Constants.maximumWeightChangePerDay {
                        #expect(day.expectedWeightChangeBasedOnDeficit.isApproximately( -Constants.maximumWeightChangePerDay, accuracy: 0.1))
                    } else {
                        #expect(day.expectedWeightChangeBasedOnDeficit.isApproximately(realisticWeightChangeTomorrowBasedOnToday, accuracy: 0.1))
                    }
                }
                if let yesterday = days.dayBefore(day) {
                    #expect(day.expectedWeight == yesterday.expectedWeightTomorrow)
                }
            }
        }
        if let today = days[0], let yesterday = days[1] {
            #expect(today.expectedWeight.isApproximately(yesterday.expectedWeightTomorrow, accuracy: 0.001) )
        }
    }
    
    @Test func missingDayAdjustmentWorksOnFirstDay() {
        days = Days.testDays(options: .init(testCase: .firstDayNotAdjustingWhenMissing))
        guard let days, let firstDay = days.oldestDay, let tomorrow = days.dayAfter(firstDay) else {
            Issue.record()
            return
        }
        #expect(firstDay.consumedCalories != 0)
        #expect(firstDay.wasModifiedBecauseTheUserDidntEnterData)
        let realisticWeightChangeTomorrowBasedOnToday = tomorrow.realisticWeight - day.expectedWeight
        if realisticWeightChangeTomorrowBasedOnToday > Constants.maximumWeightChangePerDay {
            #expect(firstDay.expectedWeightChangeBasedOnDeficit.isApproximately(Constants.maximumWeightChangePerDay, accuracy: 0.1))
        } else if realisticWeightChangeTomorrowBasedOnToday < -Constants.maximumWeightChangePerDay {
            #expect(firstDay.expectedWeightChangeBasedOnDeficit.isApproximately(-Constants.maximumWeightChangePerDay, accuracy: 0.1))
        } else {
            #expect(firstDay.expectedWeightChangeBasedOnDeficit.isApproximately(realisticWeightChangeTomorrowBasedOnToday, accuracy: 0.1))
        }
    }
//    TODO: should this run on all testcases?
//    func testMissingDayAdjustmentWorksOnFirstDay() {
//        for testcase in Filepath.Days.allCases {
//            days = Days.testDays(options: [.isMissingConsumedCalories(.v3), .testCase(testcase)])
//            guard let days, let firstDay = days.oldestDay, let tomorrow = days.dayAfter(firstDay) else {
//                XCTFail()
//                return
//            }
//            XCTAssertNotEqual(firstDay.consumedCalories, 0)
//            XCTAssertTrue(firstDay.wasModifiedBecauseTheUserDidntEnterData)
//            let realisticWeightChangeTomorrowBasedOnToday = tomorrow.realisticWeight - day.expectedWeight
//            if realisticWeightChangeTomorrowBasedOnToday > Constants.maximumWeightChangePerDay {
//                XCTAssertEqual(firstDay.expectedWeightChangeBasedOnDeficit, Constants.maximumWeightChangePerDay, accuracy: 0.1)
//            } else if realisticWeightChangeTomorrowBasedOnToday < -Constants.maximumWeightChangePerDay {
//                XCTAssertEqual(firstDay.expectedWeightChangeBasedOnDeficit, -Constants.maximumWeightChangePerDay, accuracy: 0.1)
//            } else {
//                XCTAssertEqual(firstDay.expectedWeightChangeBasedOnDeficit, realisticWeightChangeTomorrowBasedOnToday, accuracy: 0.1)
//            }
//        }
//    }
    
    @Test func settingRealisticWeights() {
        // Initialize days with missing consumed calories and a specific test case
        days = Days.testDays(options: .init(testCase: .realisticWeightsIssue))
        guard let days else {
            Issue.record("Days initialization failed")
            return
        }
        
        // Ensure realistic weights have been set
        #expect(days.everyDayHas(.realisticWeight))
        
        // Ensure weights have been set
        #expect(days.everyDayHas(.weight))
        
        // Ensure the realistic weight change per day does not exceed the maximum allowed change
        days.forEveryDay { day in
            if let previousDay = days.dayBefore(day) {
                #expect(abs(day.realisticWeight - previousDay.realisticWeight) <= Constants.maximumWeightChangePerDay, "Realistic weight change per day should not exceed the maximum allowed change")
            }
        }
        
        // Additional edge case: Check if oldest day uses its own weight as realistic weight
        if let oldestDay = days.oldestDay {
            #expect(oldestDay.realisticWeight == oldestDay.weight, "Oldest day should use its own weight as realistic weight")
        }
        
        // Additional edge case: Check if newest day has realistic weight properly set
        if let newestDay = days.newestDay, let previousDay = days.dayBefore(newestDay) {
            let realWeightDifference = newestDay.weight - previousDay.realisticWeight
            let adjustedWeightDifference = Swift.max(Swift.min(realWeightDifference, Constants.maximumWeightChangePerDay), -Constants.maximumWeightChangePerDay)
            #expect(newestDay.realisticWeight == previousDay.realisticWeight + adjustedWeightDifference, "Newest day should have a properly adjusted realistic weight")
        }
        
        // Additional edge case: Ensure no negative realistic weights
        let numberOfDaysWithNegativeRealisticWeight = days.mappedToProperty(property: .realisticWeight).filter { $0 < 0 }.count
        #expect(numberOfDaysWithNegativeRealisticWeight == 0, "There should be no days with a negative realistic weight")
        
        // Ensure realistic weights follow the pattern of real weights within the threshold
        days.forEveryDay { day in
            if let previousDay = days.dayBefore(day) {
                let realWeightDifference = day.weight - previousDay.realisticWeight
                let realisticWeightDifference = day.realisticWeight - previousDay.realisticWeight
                let adjustedWeightDifference = Swift.max(Swift.min(realWeightDifference, Constants.maximumWeightChangePerDay), -Constants.maximumWeightChangePerDay)
                #expect(realisticWeightDifference.isApproximately(adjustedWeightDifference, accuracy: 0.1), "Realistic weight change should match the adjusted real weight change within the allowed threshold")
            }
        }
    }
    
    //todo not day test
    // TODO test days have proper high and low values on chart
//    @Test func lineChartViewModel() async {
//        let days = Days.testDays(options: .init(testCase: .twoDaysIssue))
//        let vm = LineChartViewModel(days: days, timeFrame: TimeFrame.week)
//    }
    
    @Test func sortDays() {
        let oneDayAgo = Date.subtract(days: 1, from: Date())
        let twoDaysAgo = Date.subtract(days: 2, from: Date())
        
        let days = [
            1:Day(date: oneDayAgo),
            2:Day(date: twoDaysAgo)
        ]
        var sorted = days.array().sorted(.longestAgoToMostRecent)
        #expect(sorted.first?.date == twoDaysAgo)
        #expect(sorted.last?.date == oneDayAgo)
        sorted = days.array().sorted(.mostRecentToLongestAgo)
        #expect(sorted.first?.date == oneDayAgo)
        #expect(sorted.last?.date == twoDaysAgo)
    }
    
    @Test func everyDayHasProperty() {
        let days = [
            1:Day(realisticWeight: 1, weight: 0),
            2:Day(realisticWeight: 0, weight:1)
        ]
        #expect(!days.everyDayHas(.weight))
        #expect(!days.everyDayHas(.realisticWeight))
        days[1]?.weight = 1
        days[2]?.realisticWeight = 1
        #expect(days.everyDayHas(.weight))
        #expect(days.everyDayHas(.realisticWeight))
    }
    
    @Test func daysWithProperty() {
        let dayWithWeight = Day(weight: 1)
        var days = [
            0:dayWithWeight,
            2: dayWithWeight,
            1:Day(weight:0)
        ]
        var daysWithProperty = [0:dayWithWeight, 2:dayWithWeight]
        #expect(days.daysWith(.weight) == daysWithProperty)
        
        let dayWithRealisticWeight = Day(daysAgo: 3, realisticWeight: 1)
        let _ = days.append(dayWithRealisticWeight)
        daysWithProperty = [3: dayWithRealisticWeight]
        #expect(days.daysWith(.realisticWeight) == daysWithProperty)
    }
    
    @Test func editingDayByReferenceWorks() {
        let days = [
            0:Day(weight:10),
            1:Day(weight:20)
        ]
        let firstDay = days[0]
        firstDay?.weight = 20
        #expect(days[0]?.weight == 20)
    }
    
    @Test func oldestDay() {
        let day1 = Day(daysAgo: 2)
        let day2 = Day(daysAgo: 1)
        let day3 = Day(daysAgo: 3)
        let days: Days = [day1.daysAgo: day1, day2.daysAgo: day2, day3.daysAgo: day3]
        
        #expect(days.oldestDay == day3, "The oldest day should be the day with the highest daysAgo value.")
    }
    
    @Test func newestDay() {
        let day1 = Day(daysAgo: 2)
        let day2 = Day(daysAgo: 1)
        let day3 = Day(daysAgo: 3)
        let days: Days = [day1.daysAgo: day1, day2.daysAgo: day2, day3.daysAgo: day3]
        
        #expect(days.newestDay == day2, "The newest day should be the day with the lowest daysAgo value.")
    }
    
    @Test func dayInit() {
        // You can use daysAgo and date interchangeably, they both calculate the other
        // TODO remove the option of creating one day with conflicting information
        day = Day(daysAgo: 2)
        #expect(Date.daysBetween(date1: Date(), date2: day.date) == 2)
        
        day = Day(date: Date.subtract(days: 5, from: Date()))
        #expect(day.daysAgo == 5)
    }
    
    @Test func dayAfter() {
        let day1 = Day(daysAgo: 1)
        let day2 = Day(daysAgo: 2)
        let day3 = Day(daysAgo: 3)
        var days: Days = [day1.daysAgo: day1, day2.daysAgo: day2, day3.daysAgo: day3]
        #expect(days.dayAfter(day2) == day1)
        
        days = [day3.daysAgo: day3, day1.daysAgo:day1]
        #expect(days.dayAfter(day3) == day1)
    }
    
    @Test func dayBefore() {
        let day1 = Day(daysAgo: 1)
        let day2 = Day(daysAgo: 2)
        let day3 = Day(daysAgo: 3)
        var days: Days = [day1.daysAgo: day1, day2.daysAgo: day2, day3.daysAgo: day3]
        #expect(days.dayBefore(day2) == day3)
        
        days = [day3.daysAgo: day3, day1.daysAgo:day1]
        #expect(days.dayBefore(day1) == day3)
    }
    
    @Test func append() {
        var days: Days = [:]
        let day = Day(daysAgo: 4)
        let day2 = Day(daysAgo: 5)
        let day3 = Day(daysAgo: 6)
        #expect(days.append([day, day2, day3]) == true)
        #expect(days[4] == day)
    }
    
    @Test func estimatedConsumedCaloriesToCause_Loss() {
        let day = Day(activeCalories: 10, restingCalories: 10, consumedCalories: 0, weight: 70)
        let realisticWeightChange = -0.1 // Assume a weight loss of 0.1 pounds
        let estimatedConsumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: Decimal(realisticWeightChange))
        
        #expect(estimatedConsumedCalories.isApproximately(0, accuracy: 0.1), "Estimated consumed calories should be zero when the burned calories cause more than that weight loss")
    }
    
    @Test func estimatedConsumedCaloriesToCause_NoChange() {
        let day = Day(activeCalories: 500, restingCalories: 1500, consumedCalories: 0, weight: 70)
        let realisticWeightChange = 0.0 // No weight change
        let estimatedConsumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: Decimal(realisticWeightChange))
        
        #expect(estimatedConsumedCalories.isApproximately(day.allCaloriesBurned, accuracy: 0.1), "Estimated consumed calories should match the total burned calories when there is no weight change.")
    }
    
    @Test func estimatedConsumedCaloriesToCause_MaxLoss() {
        let day = Day(activeCalories: 600, restingCalories: 1400, consumedCalories: 0, weight: 70)
        let realisticWeightChange = -1.0 // Assume a weight loss of 1.0 pounds which is more than the max allowed per day
        let estimatedConsumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: Decimal(realisticWeightChange))
        
        let expectedCalories = day.allCaloriesBurned - (Constants.maximumWeightChangePerDay * Constants.numberOfCaloriesInPound)
        
        #expect(estimatedConsumedCalories.isApproximately(expectedCalories, accuracy: 0.1), "Estimated consumed calories should be adjusted to the maximum weight change allowed per day.")
    }
    
    @Test func estimatedConsumedCaloriesToCause_MaxGain() {
        let day = Day(activeCalories: 600, restingCalories: 1400, consumedCalories: 0, weight: 70)
        let realisticWeightChange = 1.0 // Assume a weight gain of 1.0 pounds which is more than the max allowed per day
        let estimatedConsumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: Decimal(realisticWeightChange))
        
        let expectedCalories = day.allCaloriesBurned + (Constants.maximumWeightChangePerDay * Constants.numberOfCaloriesInPound)
        
        #expect(estimatedConsumedCalories.isApproximately(expectedCalories, accuracy: 0.1), "Estimated consumed calories should be adjusted to the maximum weight gain allowed per day.")
    }
    
    @Test("Subset of days", arguments: [
        (75, 45),
        (75, 50),
        (50, 75)
    ])
    func subsetOfDaysOption(subset: (Int, Int)) {
        let days = Days.testDays(options: .init(testCase: .realisticWeightsIssue, subsetOfDays: (subset.0, subset.1)))
        let max = Swift.max(subset.0, subset.1)
        let min = Swift.min(subset.0, subset.1)
        #expect(days.count == max - min + 1)
        //        days.array().sortedLongestAgoToMostRecent()
        #expect(days.oldestDay?.daysAgo == max)
        #expect(days.newestDay?.daysAgo == min)
    }
    
    @Test func subset() {
        var days: Days = [:]
        let fourDaysAgo = Day(daysAgo: 4)
        let fiveDaysAgo = Day(daysAgo: 5)
        let sixDaysAgo = Day(daysAgo: 6)
        #expect(days.append([fourDaysAgo, fiveDaysAgo, sixDaysAgo]) == true)
        
        // Test using day numbers
        var subset = days.subset(from: 4, through: 5)
        #expect(subset.oldestDay?.daysAgo == 5)
        #expect(subset.newestDay?.daysAgo == 4)
        subset = days.subset(from: 5, through: 4)
        #expect(subset.oldestDay?.daysAgo == 5)
        #expect(subset.newestDay?.daysAgo == 4)
        
        // Test using days
        subset = days.subset(from: fourDaysAgo, through: fiveDaysAgo)
        #expect(subset.oldestDay?.daysAgo == 5)
        #expect(subset.newestDay?.daysAgo == 4)
        subset = days.subset(from: fiveDaysAgo, through: fourDaysAgo)
        #expect(subset.oldestDay?.daysAgo == 5)
        #expect(subset.newestDay?.daysAgo == 4)
        
        // Test not inclusive
        subset = days.subset(from: fourDaysAgo, through: sixDaysAgo, inclusiveOfOldestDay: false, inclusiveOfNewestDay: true)
        #expect(subset.oldestDay?.daysAgo == 5)
        #expect(subset.newestDay?.daysAgo == 4)
        subset = days.subset(from: sixDaysAgo, through: fourDaysAgo, inclusiveOfOldestDay: false, inclusiveOfNewestDay: true)
        #expect(subset.oldestDay?.daysAgo == 5)
        #expect(subset.newestDay?.daysAgo == 4)    
        subset = days.subset(from: fourDaysAgo, through: sixDaysAgo, inclusiveOfOldestDay: false, inclusiveOfNewestDay: false)
        #expect(subset.oldestDay?.daysAgo == 5)
        #expect(subset.newestDay?.daysAgo == 5)
        subset = days.subset(from: fourDaysAgo, through: fiveDaysAgo, inclusiveOfOldestDay: false, inclusiveOfNewestDay: false)
        #expect(subset.newestDay?.daysAgo == nil)
        #expect(subset.oldestDay?.daysAgo == nil)
        
        //Test using dates
        subset = days.subset(from: fourDaysAgo, through: fiveDaysAgo)
        #expect(subset.oldestDay?.daysAgo == 5)
        #expect(subset.newestDay?.daysAgo == 4)
        subset = days.subset(from: fiveDaysAgo, through: fourDaysAgo)
        #expect(subset.oldestDay?.daysAgo == 5)
        #expect(subset.newestDay?.daysAgo == 4)
    }
    
    @Test func forEveryDay() {
        var dayNumbers = [4,5,6]
        var daysCaptured: [Int] = []
        
        var days: Days = [:]
        for num in dayNumbers {
            #expect(days.append(Day(daysAgo: num)) == true)
        }
        #expect(days.count == dayNumbers.count)
        days.forEveryDay { day in
            daysCaptured.append(day.daysAgo)
        }
        #expect(daysCaptured.elementsEqual(dayNumbers.sorted(by: >)))
        daysCaptured = []
        days.forEveryDay(.mostRecentToLongestAgo) { day in
            daysCaptured.append(day.daysAgo)
        }
        #expect(daysCaptured.elementsEqual(dayNumbers.sorted(by: <)))
        
        daysCaptured = []
        days = [:]
        dayNumbers = [0, 3, 4, 10]
        for num in dayNumbers {
            #expect(days.append(Day(daysAgo: num)) == true)
        }
        days.forEveryDay { day in
            daysCaptured.append(day.daysAgo)
        }
        #expect(daysCaptured.elementsEqual(dayNumbers.sorted(by: >)))
    }
    
    @Test func filterByTimeFrame() {
        let days = Days.testDays(options: .init(testCase: .realisticWeightsIssue))
        #expect(days.count == 136)
        #expect(days.oldestDay?.daysAgo == 135)
        // Filter by week
        var filtered = days.filteredBy(.week)
        #expect(filtered.count == 8)
        #expect(filtered.newestDay?.daysAgo == 0)
        #expect(filtered.oldestDay?.daysAgo == 7)
        // Filter by month
        filtered = days.filteredBy(.month)
        #expect(filtered.count == 31)
        #expect(filtered.newestDay?.daysAgo == 0)
        #expect(filtered.oldestDay?.daysAgo == 30)
        // Filter by all time
        filtered = days.filteredBy(.allTime)
        #expect(filtered.count == 136)
        #expect(filtered.newestDay?.daysAgo == 0)
        #expect(filtered.oldestDay?.daysAgo == 135)
    }
    
    @Test func oldestDaysHaveWeightsAdded() {
        days = Days.testDays(options: .init(testCase: .missingWeightsAtFirst))
        let oldestWeightDay = days?.sorted(.longestAgoToMostRecent).first(where: { day in
            day.weight != 0
        })
        #expect(days?.oldestDay?.weight == oldestWeightDay?.weight)
    }
    
    @Test func setTrailingProperty() {
        var days: Days = [:]
        let day = Day(daysAgo: 4)
        let day2 = Day(daysAgo: 5)
        let day3 = Day(daysAgo: 6)
        // Test with just weight
        #expect(days.append([day, day2, day3]) == true)
        if let day = days[5] {
            #expect(day.set(.weight, to: 200))
            #expect(day.weight == 200)
            #expect(days[6]?.weight == 0)
        } else {
            Issue.record()
        }
        days.setTrailingDaysPropertyToLastKnown(.weight, .mostRecentToLongestAgo)
        #expect(days[4]?.weight == 0)
        #expect(days[6]?.weight == 200)
        days.setTrailingDaysPropertyToLastKnown(.weight, .longestAgoToMostRecent)
        #expect(days[4]?.weight == 200)
        #expect(days[5]?.weight == 200)
        #expect(days[6]?.weight == 200)
        // Test with keypaths
        days = [:]
        #expect(days.append([day, day2, day3]) == true)
        let property = Day.Property.activeCalories
        if let day = days[5] {
            #expect(day.set(property, to: 200))
            #expect(day[keyPath: property.keyPath] == 200)
            #expect(day.activeCalories == 200)
            #expect(days[6]?.activeCalories == 0)
        } else {
            Issue.record()
        }
        days.setTrailingDaysPropertyToLastKnown(property, .mostRecentToLongestAgo)
        #expect(days[4]?[keyPath: property.keyPath] == 0)
        #expect(days[6]?[keyPath: property.keyPath] == 200)
        days.setTrailingDaysPropertyToLastKnown(property, .longestAgoToMostRecent)
        #expect(days[4]?[keyPath: property.keyPath] == 200)
        #expect(days[5]?[keyPath: property.keyPath] == 200)
        #expect(days[6]?[keyPath: property.keyPath] == 200)
    }
    
    @Test func expectedWeightMatchesRunningTotalDeficit() {
        var days = Days.testDays(options: .init(testCase: .realisticWeightsIssue, dontAddWeightsOnEveryDay: true))
        #expect(days.array().filter { $0.wasModifiedBecauseTheUserDidntEnterData }.count == 0)
        #expect(days.array().filter { $0.consumedCalories == 0 }.count == 111)
        #expect(days.count == 136)
        guard let oldestDay = days.oldestDay, let newestDay = days.newestDay else {
            Issue.record()
            return
        }
        // Test total weight change matches total energy change
        #expect(oldestDay.expectedWeight == 229.2)
        #expect(newestDay.expectedWeight.isApproximately(130.23, accuracy: 0.1))
        var allNetEnergyChageExceptToday = days.subset(from: 200, through: 1).sum(property: .netEnergy)
        #expect(allNetEnergyChageExceptToday.isApproximately(-346383.89441455155785, accuracy: 0.01))
        var expectedWeightChange = allNetEnergyChageExceptToday / Constants.numberOfCaloriesInPound
        #expect(expectedWeightChange == newestDay.expectedWeight - oldestDay.expectedWeight)
        
        // Test for subsets
        days = days.subset(from: 137, through: 70)
        #expect(days.count == 66)
        guard let oldestDay = days.oldestDay, let newestDay = days.newestDay else {
            Issue.record()
            return
        }
        #expect(oldestDay.expectedWeight == 229.2)
        #expect(newestDay.expectedWeight.isApproximately(179.17, accuracy: 0.1))
        allNetEnergyChageExceptToday = days.dropping(70).sum(property: .netEnergy)
        #expect(allNetEnergyChageExceptToday.isApproximately(-175094.86993652357856, accuracy: 0.01))
        #expect(allNetEnergyChageExceptToday == -days.dayBefore(newestDay)!.runningTotalDeficit)
        expectedWeightChange = allNetEnergyChageExceptToday / Constants.numberOfCaloriesInPound
        #expect(expectedWeightChange == newestDay.expectedWeight - oldestDay.expectedWeight)
    }
    
    @Test func copy() {
        var days: Days = [:]
        let day = Day(daysAgo: 4)
        let day2 = Day(daysAgo: 5)
        let day3 = Day(daysAgo: 6)
        #expect(days.append([day, day2, day3]) == true)
        
        let copy = days.copy()
        for i in 0..<days.count {
            #expect(copy[i] == days[i])
        }
        
        copy[4]?.weight = 1234
        #expect(days[4]?.weight != copy[4]?.weight)
    }
    
    @Test func dropping() {
        var days: Days = [:]
        let day = Day(daysAgo: 4)
        let day2 = Day(daysAgo: 5)
        let day3 = Day(daysAgo: 6)
        #expect(days.append([day, day2, day3]) == true)
        let dropped = days.dropping(day)
        #expect(dropped.count == 2)
        #expect(days.count == 3)
        dropped[5]?.weight = 1234
        #expect(dropped[5]?.weight != days[5]?.weight)
    }
}

public extension Decimal {
    func isApproximately( _ other: Self, accuracy: Decimal) -> Bool {
        Double(self).isApproximatelyEqual(to: Double(other), absoluteTolerance: Double.Magnitude(accuracy))
    }
}
