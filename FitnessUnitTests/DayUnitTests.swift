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
    
    override func setUp() {
        super.setUp()
        day = Day()
    }
    
    override func tearDown() {
        day = nil
        super.tearDown()
    }
    
    func testAverage() {
        let days = Days.testDays
        let sum = days.sum(property: .activeCalories)
        let average = days.average(property: .activeCalories)
        XCTAssertEqual(sum / Double(days.count), average)
    }
    
    func testExtractedDays() {
        let days = Days.testDays
        var newDays = days.extractDays(from: 0, to: 10)
        XCTAssertEqual(newDays.count, 11)
        newDays = days.extractDays(from: 10, to: 0)
        XCTAssertEqual(newDays.count, 11)
    }
    
    func testAllTimeAverage() {
        let days = Days.testDays
        let allTimeAverage = days.averageDeficitOfPrevious(days: TimeFrame.allTime.days, endingOnDay: 1) ?? 0.0
        XCTAssertEqual(allTimeAverage, 156.9142857142857)
        let extractedDays = days.extractDays(from: 1, to: days.count - 1)
        let sum = Array(extractedDays.values)
            .map(\.deficit)
            .reduce(0, +)
        let average = sum / Double(extractedDays.count)
        XCTAssertEqual(allTimeAverage, average)
    }
    
    func testWeeklyAverage() {
        let days = Days.testDays
        let weeklyAverage = days.averageDeficitOfPrevious(days: TimeFrame.week.days, endingOnDay: 1) ?? 0.0
        XCTAssertEqual(weeklyAverage, 138.71, accuracy: 0.1)
    }
    
    func testDeficitAndSurplusAndRunningTotalDeficitAlign() {
        let days = Days.testDays
        let totalSurplus = days.sum(property: .surplus)
        let totalDeficit = days.sum(property: .deficit)
        let runningTotalDeficit = days[0]?.runningTotalDeficit
        XCTAssertEqual(totalSurplus, -totalDeficit)
        XCTAssertEqual(totalDeficit, runningTotalDeficit)
    }
    
    func testPreviousWeekAverageDeficit() {
        if let deficit = Days.testDays.averageDeficitOfPrevious(days: 7, endingOnDay: 1) {
            XCTAssertEqual(deficit, 138.71, accuracy: 0.1)
        } else {
            XCTFail()
        }
    }
    
    func testExpectedWeightTomorrow() {
        let days = Days.testDays
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
        let days = Days.testDays
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
    
}
