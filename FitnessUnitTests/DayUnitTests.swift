//
//  FitnessUnitTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 10/10/23.
//

import XCTest
@testable import Fitness
import Combine

// TODO: Put this into HealthData. So it goes through the real process, and can detect errors in HealthData and CalorieManager.

final class DayUnitTests: XCTestCase {
    
    var day: Day!
    var days: Days?
    
    override func setUp() {
        super.setUp()
        day = Day()
    }
    
    override func tearDown() {
        day = nil
        days = nil
        super.tearDown()
    }
    
    func testDecoding() {
        guard
            let activeCalories: [Double] = .decode(path: .activeCalories),
            let restingCalories: [Double] = .decode(path: .restingCalories),
            let consumedCalories: [Double] = .decode(path: .consumedCalories),
            let upAndDownWeights: [Double] = .decode(path: .upAndDownWeights),
            let missingConsumedCalories: [Double] = .decode(path: .missingConsumedCalories),
            let weightsGoingSteadilyDown: [Double] = .decode(path: .weightGoingSteadilyDown)
        else {
            XCTFail()
            return
        }
    }
    
    func testAverage() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        let sum = days.sum(property: .activeCalories)
        let average = days.average(property: .activeCalories)
        XCTAssertEqual(sum / Double(days.count), average, "Calculated average does not match expected value")
    }
    
    func testDayDates() {
        days = Days.testDays()
        guard let days else { XCTFail()
            return
        }
        
        XCTAssertEqual(Date.daysBetween(date1: days[0]!.date, date2: days[30]!.date), 30)
    }
    
    func testExtractedDays() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        var newDays = days.subset(from: 0, through: 10)
        XCTAssertEqual(newDays.count, 11, "Extracted days count should match")
        newDays = days.subset(from: 10, through: 0)
        XCTAssertEqual(newDays.count, 11, "Extracted days count should match")
    }
    
    func testAllTimeAverage() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        let allTimeAverageExceptToday = days.averageDeficitOfPrevious(days: TimeFrame.allTime.days, endingOnDay: 1) ?? 0.0
        let allDaysExceptToday = days.subset(from: 1, through: days.count - 1)
        guard let averageExceptToday = allDaysExceptToday.average(property: .deficit) else {
            XCTFail()
            return
        }
        XCTAssertEqual(allTimeAverageExceptToday, averageExceptToday, accuracy: 0.1)
        
        let allTimeAverage = days.averageDeficitOfPrevious(days: TimeFrame.allTime.days, endingOnDay: 0) ?? 0.0
        let allDays = days.subset(from: 0, through: days.count - 1)
        if let average = allDays.average(property: .deficit) {
            XCTAssertEqual(allTimeAverage, average, accuracy: 0.1, "Calculated average does not match expected value")
        } else {
            XCTFail()
        }
    }
    
    func testWeeklyAverage() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        let weeklyAverage = days.averageDeficitOfPrevious(days: TimeFrame.week.days, endingOnDay: 1) ?? 0.0
        if let calculatedAverage = days.subset(from: TimeFrame.week.days, through: 1).average(property: .deficit) {
            XCTAssertEqual(weeklyAverage, calculatedAverage, accuracy: 0.1)
        } else {
            XCTFail()
        }
    }
    
    func testDeficitAndSurplusAndRunningTotalDeficitAlign() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        let totalSurplus = days.sum(property: .netEnergy)
        let totalDeficit = days.sum(property: .deficit)
        if let runningTotalDeficit = days[0]?.runningTotalDeficit {
            XCTAssertEqual(totalSurplus, -totalDeficit, accuracy: 0.1)
            XCTAssertEqual(totalDeficit, runningTotalDeficit, accuracy: 0.1)
        } else {
            XCTFail()
        }
    }
    
//        //TODO: Test that tomorrow's all time equals today's predicted for all time tomorrow
//        func testSomething() {
//            let a = days.averageDeficitOfPrevious(days: 30, endingOnDay: 1)
//            let b = days.averageDeficitOfPrevious(days: 30, endingOnDay: 0)
//    //        XCTAssertEqual(days.averageDeficitOfPrevious(days: 30, endingOnDay: 1), <#T##expression2: Equatable##Equatable#>)
//        }
    
    func testExpectedWeightTomorrow() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(days[1]?.expectedWeight, days[2]?.expectedWeightTomorrow)
    }
    
    func testDeficitProperty() {
        day.activeCalories = 500
        day.restingCalories = 2000
        day.consumedCalories = 2000
        XCTAssertEqual(day.deficit, 500)
    }
    
    func testActiveCalorieToDeficitRatio() {
        day.activeCalories = 250
        day.restingCalories = 2750
        day.consumedCalories = 2500
        XCTAssertEqual(day.activeCalorieToDeficitRatio, 0.5)
    }
    
    func testProteinPercentage() {
        day.protein = 100
        day.consumedCalories = 2000
        XCTAssertEqual(day.proteinPercentage, 0.2)
    }
    
    func testProteinGoalPercentage() {
        day.protein = 100
        day.consumedCalories = 2000
        XCTAssertEqual(day.proteinGoalPercentage, 0.6666666667, accuracy: 0.01)
    }
    
    func testExpectedWeightChangeBasedOnDeficit() {
        day.activeCalories = 500
        day.restingCalories = 2000
        day.consumedCalories = 2000
        XCTAssertEqual(day.expectedWeightChangeBasedOnDeficit, -0.14, accuracy: 0.01)
    }
    
    func testDays() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        XCTAssert(days.count != 0)
    }
    
    func testAddingRunningTotalDeficits() throws {
        days = Days.testDays()
        guard let days, let today = days[0] else {
            XCTFail()
            return
        }
        
        // Test that today's runningTotalDeficit is the sum of all deficits
        let todaysRunningTotalDeficit = today.runningTotalDeficit
        let shouldBe = days.sum(property: .deficit)
        XCTAssertEqual(todaysRunningTotalDeficit, shouldBe, accuracy: 0.1)
        
        // Test that the first day's deficit is the same as the runningTotalDeficit
        if let firstDay = days[days.count-1] {
            XCTAssertEqual(firstDay.deficit, firstDay.runningTotalDeficit, accuracy: 0.1)
        }
    }
    
    // TODO Finish
    func testAverageProperties() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        let averageActiveCalories = days.averageDeficitOfPrevious(days: 7, endingOnDay: 0)
    }
    
    func testSumPropertyActiveCalories() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        let total = days.sum(property: .activeCalories)
        XCTAssertEqual(total, days.values.reduce(0) {$0 + $1.activeCalories})
    }
    
    // Test with edge case of zero days
    func testZeroDaysAverage() {
        let days = Days()
        let average = days.average(property: .activeCalories)
        XCTAssertNil(average, "Average should be nil for zero days")
    }
    
    // Test for edge case where start and end index are same
    func testSingleDayExtracted() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        let newDays = days.subset(from: 5, through: 5)
        XCTAssertEqual(newDays.count, 1, "Extracted days count should be 1")
    }
    
    // Test with an edge case of large number of days
    func testLargeNumberOfDaysAverageDeficit() {
        days = Days.testDays()
        guard let days else {
            XCTFail()
            return
        }
        
        let average = days.averageDeficitOfPrevious(days: 100000, endingOnDay: 1)
        XCTAssertNotNil(average, "Average should not be nil")
    }
    
    // Test for negative deficit values
    func testNegativeDeficit() {
        day.activeCalories = 500
        day.restingCalories = 2000
        day.consumedCalories = 3000
        XCTAssertEqual(day.deficit, -500, "Deficit should be set to negative value")
    }
    
    func testSetWeightsOnEveryDay() {
        for _ in 0...100 {
            days = Days.testDays(options: [.dontAddWeightsOnEveryDay])
            guard var days else {
                XCTFail()
                return
            }
            // Ensure there are empty weights at first
            var daysWithoutWeights = days.array().filter { $0.weight == 0 }
            XCTAssertNotEqual(daysWithoutWeights.count, 0)
            
            // Set weights on every day
            // Ensure the existing weights are the same after the calculation
            let originalDaysAndWeights = days.array().filter { $0.weight != 0 }.map { ($0.daysAgo, $0.weight) }
            days.setWeightOnEveryDay()
            for x in originalDaysAndWeights {
                XCTAssertEqual(days[x.0]?.weight, x.1)
            }
            
            // Ensure the only empty days are the ones closest to now, if you havent weighed yourself
            daysWithoutWeights = days.array().filter { $0.weight == 0 }
            if daysWithoutWeights.count != 0 {
                for x in 0..<daysWithoutWeights.count {
                    XCTAssertEqual(days[x]?.weight, 0)
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
        XCTAssertEqual(d[1]?.weight, 2)
        XCTAssertEqual(d[3]?.weight ?? 0.0, 3.1, accuracy: 0.01)
        XCTAssertEqual(d[4]?.weight ?? 0.0, 3.2, accuracy: 0.01)
        XCTAssertEqual(d[6]?.weight ?? 0.0, 2.15, accuracy: 0.01)
    }
    
    func testWeightsOnEveryDaySimple() {
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
        XCTAssertEqual(d[1]?.weight, 2)
        XCTAssertEqual(d[3]?.weight ?? 0.0, 3.1, accuracy: 0.01)
        XCTAssertEqual(d[4]?.weight ?? 0.0, 3.2, accuracy: 0.01)
        XCTAssertEqual(d[6]?.weight ?? 0.0, 2.15, accuracy: 0.01)
    }
    
    func testRecentDaysKeepRecentWeight() {
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
        XCTAssertEqual(d[0]?.weight, 1)
        XCTAssertEqual(d[2]?.weight, 2)
        XCTAssertEqual(d[4]?.weight ?? 0.0, 3.1, accuracy: 0.01)
        XCTAssertEqual(d[5]?.weight ?? 0.0, 3.2, accuracy: 0.01)
        XCTAssertEqual(d[7]?.weight ?? 0.0, 2.15, accuracy: 0.01)
    }
    
    func daysAgo(_ num: Int) -> Date {
        Date.subtract(days: num, from: Date())
    }
    
    func testDayOfWeek() {
        days = Days.testDays(options: [.testCase(.missingDataIssue)])
        XCTAssertEqual(days?[0]?.dayOfWeek, "Thursday")
    }
    
    func testDecodingTestCases() {
        for path in Filepath.Days.allCases {
            days = Days.decode(path: path)
            XCTAssertNotNil(days)
        }
    }
    
    func testEncodingJSON() {
        days = Days.decode(path: .missingDataIssue)
        XCTAssertNotNil(days.encodeAsString())
    }
    
    func testMissingDayAdjustment() {
        for path in Filepath.Days.allCases {
            days = Days.testDays(options: [.isMissingConsumedCalories(.v3), .testCase(path)])
            guard let days else {
                XCTFail()
                return
            }
            for i in stride(from: days.count - 1, through: 0, by: -1) {
                if let day = days[i], day.wasModifiedBecauseTheUserDidntEnterData {
                    if let tomorrow = days[i-1] {
                        let realisticWeightChangeTomorrowBasedOnToday = tomorrow.realisticWeight - day.expectedWeight
                        if realisticWeightChangeTomorrowBasedOnToday > Constants.maximumWeightChangePerDay {
                            XCTAssertEqual(day.expectedWeightChangeBasedOnDeficit, Constants.maximumWeightChangePerDay, accuracy: 0.1)
                        } else if realisticWeightChangeTomorrowBasedOnToday < -Constants.maximumWeightChangePerDay {
                            XCTAssertEqual(day.expectedWeightChangeBasedOnDeficit, -Constants.maximumWeightChangePerDay, accuracy: 0.1)
                        } else {
                            XCTAssertEqual(day.expectedWeightChangeBasedOnDeficit, realisticWeightChangeTomorrowBasedOnToday, accuracy: 0.1)
                        }
                    }
                    if let yesterday = days[i+1] {
                        XCTAssertEqual(day.expectedWeight, yesterday.expectedWeightTomorrow)
                    }
                }
            }
            if let today = days[0], let yesterday = days[1] {
                XCTAssertEqual(today.expectedWeight, yesterday.expectedWeightTomorrow)
            }
        }
    }
    
    func testMissingDayAdjustmentWorksOnFirstDay() {
        days = Days.testDays(options: [.isMissingConsumedCalories(.v3), .testCase(.firstDayNotAdjustingWhenMissing)])
        guard let days else {
            XCTFail()
            return
        }
        let firstDayIndex = days.count - 1
        guard let firstDay = days[firstDayIndex], let tomorrow = days[firstDayIndex - 1] else {
            XCTFail()
            return
        }
        XCTAssertNotEqual(firstDay.consumedCalories, 0)
        XCTAssertTrue(firstDay.wasModifiedBecauseTheUserDidntEnterData)
        let realisticWeightChangeTomorrowBasedOnToday = tomorrow.realisticWeight - day.expectedWeight
        if realisticWeightChangeTomorrowBasedOnToday > Constants.maximumWeightChangePerDay {
            XCTAssertEqual(firstDay.expectedWeightChangeBasedOnDeficit, Constants.maximumWeightChangePerDay, accuracy: 0.1)
        } else if realisticWeightChangeTomorrowBasedOnToday < -Constants.maximumWeightChangePerDay {
            XCTAssertEqual(firstDay.expectedWeightChangeBasedOnDeficit, -Constants.maximumWeightChangePerDay, accuracy: 0.1)
        } else {
            XCTAssertEqual(firstDay.expectedWeightChangeBasedOnDeficit, realisticWeightChangeTomorrowBasedOnToday, accuracy: 0.1)
        }
    }
    
    func testSettingRealisticWeights() {
        // Initialize days with missing consumed calories and a specific test case
        days = Days.testDays(options: [.isMissingConsumedCalories(.v3), .testCase(.realisticWeightsIssue)])
        guard let days else {
            XCTFail("Days initialization failed")
            return
        }
        
        // Ensure realistic weights have been set
        XCTAssertTrue(days.everyDayHas(.realisticWeight))
        
        // Ensure weights have been set
        XCTAssertTrue(days.everyDayHas(.weight))
        
        // Ensure the realistic weight change per day does not exceed the maximum allowed change
        for i in stride(from: days.count - 1, through: 1, by: -1) {
            if let day = days[i], let previousDay = days[i-1] {
                XCTAssertLessThanOrEqual(abs(day.realisticWeight - previousDay.realisticWeight), Constants.maximumWeightChangePerDay, "Realistic weight change per day should not exceed the maximum allowed change")
            }
        }
        
        // Additional edge case: Check if oldest day uses its own weight as realistic weight
        if let oldestDay = days.oldestDay {
            XCTAssertEqual(oldestDay.realisticWeight, oldestDay.weight, "Oldest day should use its own weight as realistic weight")
        }
        
        // Additional edge case: Check if newest day has realistic weight properly set
        if let newestDay = days.newestDay, let previousDay = days.dayBefore(newestDay) {
            let realWeightDifference = newestDay.weight - previousDay.realisticWeight
            let adjustedWeightDifference = Swift.max(Swift.min(realWeightDifference, Constants.maximumWeightChangePerDay), -Constants.maximumWeightChangePerDay)
            XCTAssertEqual(newestDay.realisticWeight, previousDay.realisticWeight + adjustedWeightDifference, "Newest day should have a properly adjusted realistic weight")
        }
        
        // Additional edge case: Ensure no negative realistic weights
        let numberOfDaysWithNegativeRealisticWeight = days.mappedToProperty(property: .realisticWeight).filter { $0 < 0 }.count
        XCTAssertEqual(numberOfDaysWithNegativeRealisticWeight, 0, "There should be no days with a negative realistic weight")
        
        // Ensure realistic weights follow the pattern of real weights within the threshold
        for i in stride(from: days.count - 1, through: 1, by: -1) {
            if let currentDay = days[i], let previousDay = days[i+1] {
                let realWeightDifference = currentDay.weight - previousDay.realisticWeight
                let realisticWeightDifference = currentDay.realisticWeight - previousDay.realisticWeight
                let adjustedWeightDifference = Swift.max(Swift.min(realWeightDifference, Constants.maximumWeightChangePerDay), -Constants.maximumWeightChangePerDay)
                XCTAssertEqual(realisticWeightDifference, adjustedWeightDifference, accuracy: 0.1, "Realistic weight change should match the adjusted real weight change within the allowed threshold")
            }
        }
    }
    
    //todo not day test
    // TODO test days have proper high and low values on chart
    func testLineChartViewModel() async {
        let days = Days.testDays(options: [.isMissingConsumedCalories(.v3), .testCase(.twoDaysIssue)])
        let vm = LineChartViewModel(days: days, timeFrame: TimeFrame.week)
    }
    
    func testSortDays() {
        let oneDayAgo = Date.subtract(days: 1, from: Date())
        let twoDaysAgo = Date.subtract(days: 2, from: Date())
        
        let days = [
            1:Day(date: oneDayAgo),
            2:Day(date: twoDaysAgo)
        ]
        var sorted = days.array().sortedLongestAgoToMostRecent()
        XCTAssertEqual(sorted.first?.date, twoDaysAgo)
        XCTAssertEqual(sorted.last?.date, oneDayAgo)
        sorted = days.array().sortedMostRecentToLongestAgo()
        XCTAssertEqual(sorted.first?.date, oneDayAgo)
        XCTAssertEqual(sorted.last?.date, twoDaysAgo)
    }
    
    func testEveryDayHasProperty() {
        let days = [
            1:Day(realisticWeight: 1, weight: 0),
            2:Day(realisticWeight: 0, weight:1)
        ]
        XCTAssertFalse(days.everyDayHas(.weight))
        XCTAssertFalse(days.everyDayHas(.realisticWeight))
        days[1]?.weight = 1
        days[2]?.realisticWeight = 1
        XCTAssertTrue(days.everyDayHas(.weight))
        XCTAssertTrue(days.everyDayHas(.realisticWeight))
    }
    
    func testDaysWithProperty() {
        let dayWithWeight = Day(weight: 1)
        var days = [
            0:dayWithWeight,
            2: dayWithWeight,
            1:Day(weight:0)
        ]
        var daysWithProperty = [0:dayWithWeight, 2:dayWithWeight]
        XCTAssertEqual(days.daysWith(.weight), daysWithProperty)
        
        let dayWithRealisticWeight = Day(daysAgo: 3, realisticWeight: 1)
        let _ = days.append(dayWithRealisticWeight)
        daysWithProperty = [3: dayWithRealisticWeight]
        XCTAssertEqual(days.daysWith(.realisticWeight), daysWithProperty)
    }
    
    func testEditingDayByReferenceWorks() {
        let days = [
            0:Day(weight:10),
            1:Day(weight:20)
        ]
        let firstDay = days[0]
        firstDay?.weight = 20
        XCTAssertEqual(days[0]?.weight, 20)
    }
    
    func testOldestDay() {
        let day1 = Day(daysAgo: 2)
        let day2 = Day(daysAgo: 1)
        let day3 = Day(daysAgo: 3)
        let days: Days = [day1.daysAgo: day1, day2.daysAgo: day2, day3.daysAgo: day3]
        
        XCTAssertEqual(days.oldestDay, day3, "The oldest day should be the day with the highest daysAgo value.")
    }
    
    func testNewestDay() {
        let day1 = Day(daysAgo: 2)
        let day2 = Day(daysAgo: 1)
        let day3 = Day(daysAgo: 3)
        let days: Days = [day1.daysAgo: day1, day2.daysAgo: day2, day3.daysAgo: day3]
        
        XCTAssertEqual(days.newestDay, day2, "The newest day should be the day with the lowest daysAgo value.")
    }
    
    func testDayInit() {
        // You can use daysAgo and date interchangeably, they both calculate the other
        // TODO remove the option of creating one day with conflicting information
        day = Day(daysAgo: 2)
        XCTAssertEqual(Date.daysBetween(date1: Date(), date2: day.date), 2)
        
        day = Day(date: Date.subtract(days: 5, from: Date()))
        XCTAssertEqual(day.daysAgo, 5)
    }
    
    func testDayAfter() {
        let day1 = Day(daysAgo: 1)
        let day2 = Day(daysAgo: 2)
        let day3 = Day(daysAgo: 3)
        var days: Days = [day1.daysAgo: day1, day2.daysAgo: day2, day3.daysAgo: day3]
        XCTAssertEqual(days.dayAfter(day2), day1)
        
        days = [day3.daysAgo: day3, day1.daysAgo:day1]
        XCTAssertEqual(days.dayAfter(day3), day1)
    }
    
    func testDayBefore() {
        let day1 = Day(daysAgo: 1)
        let day2 = Day(daysAgo: 2)
        let day3 = Day(daysAgo: 3)
        var days: Days = [day1.daysAgo: day1, day2.daysAgo: day2, day3.daysAgo: day3]
        XCTAssertEqual(days.dayBefore(day2), day3)
        
        days = [day3.daysAgo: day3, day1.daysAgo:day1]
        XCTAssertEqual(days.dayBefore(day1), day3)
    }
    
    func testAppend() {
        var days: Days = [:]
        let day = Day(daysAgo: 4)
        let day2 = Day(daysAgo: 5)
        let day3 = Day(daysAgo: 6)
        XCTAssertTrue(days.append([day, day2, day3]))
        XCTAssertEqual(days[4], day)
    }
    
    func testEstimatedConsumedCaloriesToCause_Loss() {
        let day = Day(activeCalories: 10, restingCalories: 10, consumedCalories: 0, weight: 70)
        let realisticWeightChange = -0.1 // Assume a weight loss of 0.1 pounds
        let estimatedConsumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: realisticWeightChange)
        
        XCTAssertEqual(estimatedConsumedCalories, 0, accuracy: 0.1, "Estimated consumed calories should be zero when the burned calories cause more than that weight loss")
    }
    
    func testEstimatedConsumedCaloriesToCause_NoChange() {
        let day = Day(activeCalories: 500, restingCalories: 1500, consumedCalories: 0, weight: 70)
        let realisticWeightChange = 0.0 // No weight change
        let estimatedConsumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: realisticWeightChange)
        
        XCTAssertEqual(estimatedConsumedCalories, day.allCaloriesBurned, accuracy: 0.1, "Estimated consumed calories should match the total burned calories when there is no weight change.")
    }
    
    func testEstimatedConsumedCaloriesToCause_MaxLoss() {
        let day = Day(activeCalories: 600, restingCalories: 1400, consumedCalories: 0, weight: 70)
        let realisticWeightChange = -1.0 // Assume a weight loss of 1.0 pounds which is more than the max allowed per day
        let estimatedConsumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: realisticWeightChange)
        
        let expectedCalories = day.allCaloriesBurned - (Constants.maximumWeightChangePerDay * Constants.numberOfCaloriesInPound)
        
        XCTAssertEqual(estimatedConsumedCalories, expectedCalories, accuracy: 0.1, "Estimated consumed calories should be adjusted to the maximum weight change allowed per day.")
    }
    
    func testEstimatedConsumedCaloriesToCause_MaxGain() {
        let day = Day(activeCalories: 600, restingCalories: 1400, consumedCalories: 0, weight: 70)
        let realisticWeightChange = 1.0 // Assume a weight gain of 1.0 pounds which is more than the max allowed per day
        let estimatedConsumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: realisticWeightChange)
        
        let expectedCalories = day.allCaloriesBurned + (Constants.maximumWeightChangePerDay * Constants.numberOfCaloriesInPound)
        
        XCTAssertEqual(estimatedConsumedCalories, expectedCalories, accuracy: 0.1, "Estimated consumed calories should be adjusted to the maximum weight gain allowed per day.")
    }
    
    func testSubsetOfDaysOption() {
        var testCases = [(75, 45),
                         (75, 50)]
        testCases.append((50, 75))
        for subset in testCases {
            let days = Days.testDays(options: [.isMissingConsumedCalories(.v3), .testCase(.realisticWeightsIssue), .subsetOfDays(subset.0, subset.1)])
            let max = Swift.max(subset.0, subset.1)
            let min = Swift.min(subset.0, subset.1)
            XCTAssertEqual(days.count, max - min + 1)
            //        days.array().sortedLongestAgoToMostRecent()
            XCTAssertEqual(days.oldestDay?.daysAgo, max)
            XCTAssertEqual(days.newestDay?.daysAgo, min)
        }
    }
    
    func testSubset() {
        var days: Days = [:]
        let day = Day(daysAgo: 4)
        let day2 = Day(daysAgo: 5)
        let day3 = Day(daysAgo: 6)
        XCTAssertTrue(days.append([day, day2, day3]))
        
        var subset = days.subset(from: 4, through: 5)
        XCTAssertEqual(subset.oldestDay?.daysAgo, 5)
        XCTAssertEqual(subset.newestDay?.daysAgo, 4)
        subset = days.subset(from: 5, through: 4)
        XCTAssertEqual(subset.oldestDay?.daysAgo, 5)
        XCTAssertEqual(subset.newestDay?.daysAgo, 4)
    }
    
    
    
    func testForEveryDay() {
        var days: Days = [:]
        var dayNumbers = [4,5,6]
        for num in dayNumbers {
            XCTAssertTrue(days.append(Day(daysAgo: num)))
        }
        XCTAssertEqual(days.count, dayNumbers.count)
        var daysCaptured: [Int] = []
        days.forEveryDay { day in
            daysCaptured.append(day.daysAgo)
        }
        XCTAssert(daysCaptured.elementsEqual(dayNumbers.sorted(by: >)))
        daysCaptured = []
        days.forEveryDay(oldestToNewest: false) { day in
            daysCaptured.append(day.daysAgo)
        }
        XCTAssert(daysCaptured.elementsEqual(dayNumbers.sorted(by: <)))
    }
    
}
