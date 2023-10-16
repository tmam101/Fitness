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
