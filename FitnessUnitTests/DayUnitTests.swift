//
//  FitnessUnitTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 10/10/23.
//

import XCTest
@testable import Fitness

final class DayUnitTests: XCTestCase {
    
    var day: Day!
    var days: Days!
    
    override func setUp() {
        super.setUp()
        day = Day()
        days = Days.testDays
    }
    
    override func tearDown() {
        day = nil
        days = nil
        super.tearDown()
    }
    
    func testAverage() {
        let sum = days.sum(property: .activeCalories)
        let average = days.average(property: .activeCalories)
        XCTAssertEqual(sum / Double(days.count), average, "Calculated average does not match expected value")
    }
    
    func testDayDates() {
        XCTAssertEqual(Date.daysBetween(date1: days[0]!.date, date2: days[30]!.date), 30)
    }
    
    func testExtractedDays() {
        var newDays = days.extractDays(from: 0, to: 10)
        XCTAssertEqual(newDays.count, 11, "Extracted days count should match")
        newDays = days.extractDays(from: 10, to: 0)
        XCTAssertEqual(newDays.count, 11, "Extracted days count should match")
    }
    
    func testAllTimeAverage() {
        let allTimeAverageExceptToday = days.averageDeficitOfPrevious(days: TimeFrame.allTime.days, endingOnDay: 1) ?? 0.0
        let allDaysExceptToday = days.extractDays(from: 1, to: days.count - 1)
        let averageExceptToday = allDaysExceptToday.average(property: .deficit)
        XCTAssertEqual(allTimeAverageExceptToday, averageExceptToday, "Calculated average does not match expected value")
        
        let allTimeAverage = days.averageDeficitOfPrevious(days: TimeFrame.allTime.days, endingOnDay: 0) ?? 0.0
        let allDays = days.extractDays(from: 1, to: days.count - 1)
        let average = allDays.average(property: .deficit)
        XCTAssertEqual(allTimeAverageExceptToday, average, "Calculated average does not match expected value")
    }
    
    func testWeeklyAverage() {
        let weeklyAverage = days.averageDeficitOfPrevious(days: TimeFrame.week.days, endingOnDay: 1) ?? 0.0
        XCTAssertEqual(weeklyAverage, 138.71, accuracy: 0.1)
    }
    
    func testDeficitAndSurplusAndRunningTotalDeficitAlign() {
        let totalSurplus = days.sum(property: .surplus)
        let totalDeficit = days.sum(property: .deficit)
        let runningTotalDeficit = days[0]?.runningTotalDeficit
        XCTAssertEqual(totalSurplus, -totalDeficit)
        XCTAssertEqual(totalDeficit, runningTotalDeficit)
    }
    
    func testPreviousWeekAverageDeficit() {
        if let deficit = days.averageDeficitOfPrevious(days: 7, endingOnDay: 1) {
            XCTAssertEqual(deficit, 138.71, accuracy: 0.1)
        } else {
            XCTFail()
        }
    }
    
    //TODO: Test that tomorrow's all time equals today's predicted for all time tomorrow
    func testSomething() {
        let a = days.averageDeficitOfPrevious(days: 30, endingOnDay: 1)
        let b = days.averageDeficitOfPrevious(days: 30, endingOnDay: 0)
//        XCTAssertEqual(days.averageDeficitOfPrevious(days: 30, endingOnDay: 1), <#T##expression2: Equatable##Equatable#>)
    }
    
    func testExpectedWeightTomorrow() {
        XCTAssertEqual(days[1]?.expectedWeight, days[2]?.expectedWeightTomorrow)
    }
    
    func testDeficitProperty() {
        day.deficit = 500
        XCTAssertEqual(day.deficit, 500)
    }
    
    func testActiveCalorieToDeficitRatio() {
        day.activeCalories = 250
        day.deficit = 500
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
        day.deficit = 500
        XCTAssertEqual(day.expectedWeightChangeBasedOnDeficit, -0.14, accuracy: 0.01)
    }
    
    func testDays() {
        XCTAssert(days.count != 0)
    }
    
    func testAddingRunningTotalDeficits() throws {
        let days = Days.testDays
        let todaysRunningTotalDeficit = days[0]?.runningTotalDeficit
        let shouldBe = days.sum(property: .deficit)
        XCTAssertEqual(todaysRunningTotalDeficit, shouldBe)
        XCTAssertEqual(days[days.count-1]?.deficit, days[days.count-1]?.runningTotalDeficit)
    }
    
    func testSumPropertyActiveCalories() {
        let days = Days.testDays
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
        let newDays = days.extractDays(from: 5, to: 5)
        XCTAssertEqual(newDays.count, 1, "Extracted days count should be 1")
    }
    
    // Test with an edge case of large number of days
    func testLargeNumberOfDays() {
        let average = days.averageDeficitOfPrevious(days: 100000, endingOnDay: 1)
        XCTAssertNotNil(average, "Average should not be nil")
    }
    
    // Test for negative deficit values
    func testNegativeDeficit() {
        day.deficit = -500
        XCTAssertEqual(day.deficit, -500, "Deficit should be set to negative value")
    }
    
}
