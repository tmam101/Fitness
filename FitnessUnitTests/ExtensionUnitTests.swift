//
//  ExtensionUnitTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 10/16/23.
//

import XCTest
@testable import Fitness
import SwiftUI

class ArrayExtensionTests: XCTestCase {

    func testSum() {
        // Test with integers
        XCTAssertEqual([1, 2, 3, 4, 5].sum, 15)
        
        // Test with floating-point numbers
        XCTAssertEqual([1.0, 2.0, 3.0, 4.0, 5.0].sum, 15.0)
        
        // Test with empty array (edge case)
        XCTAssertEqual([Int]().sum, 0)
    }

    func testAverage() {
        // Test with integers
        XCTAssertEqual([1, 2, 3, 4, 5].average, 3.0)
        
        // Test with floating-point numbers
        XCTAssertEqual([1.0, 2.0, 3.0, 4.0, 5.0].average, 3.0)
        
        // Test with empty array (edge case)
        XCTAssertNil([Double]().average)
    }
}


class ColorTests: XCTestCase {
    
    func testCustomColors() {
        // Verify that custom colors are correctly initialized
        XCTAssertNotNil(Color.myGray)
        XCTAssertNotNil(Color.green1)
        XCTAssertNotNil(Color.green2)
        XCTAssertNotNil(Color.green3)
        XCTAssertNotNil(Color.yellow1)
        XCTAssertNotNil(Color.yellow2)
        XCTAssertNotNil(Color.yellow3)
    }
    
    func testSolidColorGradient() {
        // Test the solidColorGradient() function
        let gradient = Color.myGray.solidColorGradient()
        XCTAssertNotNil(gradient)
    }
    
}

class SettingsTests: XCTestCase {
    func testUserDefaultsStorage() {
        // Test storing and retrieving a basic value
        let testValue = "TestValue"
        Settings.set(key: .active, value: testValue)
        let retrievedValue = Settings.get(key: .active) as? String
        XCTAssertEqual(testValue, retrievedValue)
    }
    
    // Assuming Days is defined or can be mocked for testing
    func testDaysEncodingAndDecoding() {
        // Mock a Days object (assuming it's a dictionary for simplicity)
        let mockDays: Days = [1: Day()]  // This needs to be adjusted based on the actual Days and Day types
        Settings.setDays(days: mockDays)
        let retrievedDays = Settings.getDays()
        XCTAssertEqual(mockDays, retrievedDays)
    }
    
}

class DoubleTests: XCTestCase {
    
    func testToRadians() {
        let degrees: Double = 180
        XCTAssertEqual(degrees.toRadians(), Double.pi, accuracy: 1e-10)
    }
    
    func testToCGFloat() {
        let doubleValue: Double = 123.45
        let expected: CGFloat = 123.45
        XCTAssertEqual(doubleValue.toCGFloat(), expected)
    }
    
    func testRoundedToNextSignificant() {
        let value: Double = 123.45
        let goal: Double = 10.0
        let expected: Double = 130.0
        XCTAssertEqual(value.rounded(toNextSignificant: goal), expected)
    }
    
    func testRoundedString() {
        let value: Double = 123.4567
        let expected: String = "123.46"
        XCTAssertEqual(value.roundedString(), expected)
    }
    
    func testPercentageToWholeNumber() {
        let value: Double = 0.45
        let expected: String = "45"
        XCTAssertEqual(value.percentageToWholeNumber(), expected)
    }
}

class DateTests: XCTestCase {
    // TODO: Dates are stored in UTC, but printed in local time zone. So theres a discrepancy on the pipeline, because it is in UTC time, and the test fails.
//    func testStringFromDate() {
//        // Test with a specific date
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy/MM/dd"
//        let date = formatter.date(from: "2022/01/01")!
//        XCTAssertEqual(Date.stringFromDate(date: date), "01/01/2022")
//        
//        // Test with current date
//        let currentDate = Date()
//        let components = Calendar.current.dateComponents([.day, .month, .year], from: currentDate)
//        let expectedString = "\(components.month!)/\(components.day! < 10 ? "0" : "")\(components.day!)/\(components.year!)"
//        XCTAssertEqual(Date.stringFromDate(date: currentDate), expectedString)
//        
//        // Test with empty date (edge case)
//        let emptyDate = Date(timeIntervalSince1970: 1000)
//        XCTAssertEqual(Date.stringFromDate(date: emptyDate), "01/01/1970")
//    }
    
    func testDaysBetween() {
        // Test with same day
        let date1 = Date()
        let date2 = Date()
        XCTAssertEqual(Date.daysBetween(date1: date1, date2: date2), 0)
        
        // Test with one day difference
        let oneDayLater = Calendar.current.date(byAdding: .day, value: 1, to: date1)!
        XCTAssertEqual(Date.daysBetween(date1: date1, date2: oneDayLater), 1)
        
        // Test with negative days (date2 is earlier than date1)
        XCTAssertEqual(Date.daysBetween(date1: oneDayLater, date2: date1), 1)
        
        // Test with empty date (edge case)
        let emptyDate = Date(timeIntervalSince1970: 0)
        XCTAssertNotEqual(Date.daysBetween(date1: emptyDate, date2: date1), 0)
    }
    
    func testDateFromString() {
        // Test with valid date string
        XCTAssertNotNil(Date.dateFromString("01.01.2022"))
        
        // Test with invalid date string
        XCTAssertNil(Date.dateFromString("invalid.date"))
        
        // Test with another valid date string
        let expectedDate = Date.dateFromString("12.31.2021")
        XCTAssertNotNil(expectedDate)
    }
    
    func testDateFromStringComponents() {
        // Test with valid date components
        XCTAssertNotNil(Date.dateFromString(month: "01", day: "01", year: "2022"))
        
        // Test with invalid date components
        XCTAssertNil(Date.dateFromString(month: "invalid", day: "date", year: "components"))
    }
    
    func testSubtractDays() {
        let currentDate = Date()
        
        // Test subtracting zero days
        let sameDay = Date.subtract(days: 0, from: currentDate)
        XCTAssertTrue(Date.sameDay(date1: currentDate, date2: sameDay))
        
        // Test subtracting 7 days
        let sevenDaysEarlier = Date.subtract(days: 7, from: currentDate)
        XCTAssertEqual(Date.daysBetween(date1: sevenDaysEarlier, date2: currentDate), 7)
    }
    
    func testSameDay() {
        let date1 = Date()
        
        // Test with the same date
        XCTAssertTrue(Date.sameDay(date1: date1, date2: date1))
        
        // Test with different date
        let date2 = Date.subtract(days: 1, from: date1)
        XCTAssertFalse(Date.sameDay(date1: date1, date2: date2))
    }
    
    func testStartOfDay() {
        let currentDate = Date()
        let startOfDay = Date.startOfDay(currentDate)
        
        // Ensure that the time components are all zero
        let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
        XCTAssertEqual(components.nanosecond, 0)
    }
    
    func testDayOfWeek() {
        // Test with a known date (e.g., 1st January 2022 was a Saturday)
        let knownDate = Date.dateFromString("01.01.2022")!
        XCTAssertEqual(knownDate.dayOfWeek(), "Saturday")
    }
    
}

class TimeTests: XCTestCase {
    func testDoubleToString() {
        // Test with a normal double value
        XCTAssertEqual(Time.doubleToString(double: 12.5), "12:30")
        
        // Test with a whole number
        XCTAssertEqual(Time.doubleToString(double: 10.0), "10:00")
        
        // Test with a very small value (edge case)
        XCTAssertEqual(Time.doubleToString(double: 0.01), "0:01")
        
        // Test with a negative value (edge case)
        XCTAssertEqual(Time.doubleToString(double: -12.5), "-12:30")
        
        // Test with zero (edge case)
        XCTAssertEqual(Time.doubleToString(double: 0.0), "0:00")
        
        // Test with a negative whole number (edge case)
        XCTAssertEqual(Time.doubleToString(double: -10.0), "-10:00")
    }
}


