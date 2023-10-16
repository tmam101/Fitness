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
    func testStringFromDate() {
        // Test with a specific date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let date = formatter.date(from: "2022/01/01")!
        XCTAssertEqual(Date.stringFromDate(date: date), "01/01/2022")
        
        // Test with current date
        let currentDate = Date()
        let components = Calendar.current.dateComponents([.day, .month, .year], from: currentDate)
        let expectedString = "\(components.month!)/\(components.day!)/\(components.year!)"
        XCTAssertEqual(Date.stringFromDate(date: currentDate), expectedString)
        
        // Test with empty date (edge case)
        let emptyDate = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(Date.stringFromDate(date: emptyDate), "12/31/1969")
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


