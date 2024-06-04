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
    
    func testDecodingArrayJSON() {
        if let array: [Double] = .decode(path: .activeCalories) {
            XCTAssertNotNil(array)
            
            let activeCalories: [Double] = [
                530.484, 426.822, 401.081, 563.949, 329.136, 304.808, 1045.074, 447.229, 1140.485, 287.526,
                664.498, 729.646, 141.281, 137.878, 185.565, 524.932, 387.086, 206.355, 895.737, 161.954,
                619.241, 624.191, 284.112, 272.095, 840.536, 158.428, 443.622, 264.205, 1025.872, 394.575,
                135.940, 696.240, 976.788, 383.816, 1057.616, 1056.868, 741.806, 1145.090, 514.840, 674.655,
                620.510, 1151.488, 696.858, 724.303, 953.539, 117.319, 207.876, 884.699, 672.569, 659.526,
                366.072, 672.032, 536.885, 1075.278, 705.510, 362.428, 1157.047, 376.990, 808.443, 1141.884,
                1047.608, 927.059, 1001.858, 364.928, 694.303, 241.747, 852.663, 564.521, 585.509, 970.332
            ]
            
            XCTAssertEqual(array, activeCalories)
        } else {
            XCTFail()
        }
    }
    
    func testEncodingArrayJSON() {
        let array: [Double] = [1.0, 2.0, 3.0]
        XCTAssertEqual(array.encodeAsString(),
"""
[
  1,
  2,
  3
]
"""
        )
    }
    
    func testReversingArray() {
        let weightGoingSteadilyDown: [Double] = [
            200.00, 199.98, 200.00, 199.73, 199.64, 199.92, 199.52, 199.27, 199.20, 199.09, 198.63, 198.49, 198.76, 198.94, 199.10,
            199.09, 199.17, 198.95, 198.47, 198.19, 198.34, 198.43, 198.44, 198.73, 198.91, 198.61, 198.90, 198.55, 198.72, 198.73,
            198.64, 198.80, 199.01, 198.62, 198.57, 198.78, 199.01, 199.13, 199.02, 199.05, 198.73, 198.68, 198.96, 198.75, 198.87,
            199.02, 199.24, 199.40, 199.24, 198.93, 199.06, 199.13, 198.70, 198.86, 198.87, 198.42, 198.51, 198.53, 198.17, 198.33,
            198.03, 198.08, 197.96, 198.10, 198.14, 197.87, 197.79, 197.69, 197.65, 197
        ].reversed()
        print(weightGoingSteadilyDown)
    }
    
    func testSorting() {
        struct TestEvent: HasDate {
            var date: Date
        }
        
        func testSortedMostRecentToLongestAgo() {
            // Arrange
            let now = Date()
            let oneHourAgo = Date(timeIntervalSinceNow: -3600)
            let twoHoursAgo = Date(timeIntervalSinceNow: -7200)
            
            let events = [
                TestEvent(date: twoHoursAgo),
                TestEvent(date: now),
                TestEvent(date: oneHourAgo)
            ]
            
            // Act
            var sortedEvents = events.sorted(.mostRecentToLongestAgo)
            
            // Assert
            XCTAssertEqual(sortedEvents[0].date, now, "The most recent date should be first")
            XCTAssertEqual(sortedEvents[1].date, oneHourAgo, "The second most recent date should be second")
            XCTAssertEqual(sortedEvents[2].date, twoHoursAgo, "The oldest date should be last")
            
            sortedEvents = events.sorted(.longestAgoToMostRecent)
            
            // Assert
            XCTAssertEqual(sortedEvents[0].date, twoHoursAgo, "The oldest date should be first")
            XCTAssertEqual(sortedEvents[1].date, oneHourAgo, "The second oldest date should be second")
            XCTAssertEqual(sortedEvents[2].date, now, "The newest date should be last")
            
        }
        
        func testSortedMostRecentToLongestAgoWithSameDates() {
            // Arrange
            let date = Date()
            
            let events = [
                TestEvent(date: date),
                TestEvent(date: date),
                TestEvent(date: date)
            ]
            
            // Act
            let sortedEvents = events.sorted(.mostRecentToLongestAgo)
            
            // Assert
            XCTAssertEqual(sortedEvents.count, 3, "All events should be present")
            XCTAssertTrue(sortedEvents.allSatisfy { $0.date == date }, "All dates should be the same")
        }
        
        func testSortedMostRecentToLongestAgoWithEmptyArray() {
            // Arrange
            let events: [TestEvent] = []
            
            // Act
            let sortedEvents = events.sorted(.mostRecentToLongestAgo)
            
            // Assert
            XCTAssertTrue(sortedEvents.isEmpty, "The sorted array should be empty")
        }
        testSortedMostRecentToLongestAgo()
        testSortedMostRecentToLongestAgoWithSameDates()
        testSortedMostRecentToLongestAgoWithEmptyArray()
    }
}


class ColorTests: XCTestCase {
    
    func testCustomColors() {
        // Verify that custom colors are correctly initialized
        XCTAssertNotNil(Color.myGray)
        XCTAssertNotNil(Color.expectedWeightYellow)
        XCTAssertNotNil(Color.weightGreen)
        XCTAssertNotNil(Color.realisticWeightGreen)
//        XCTAssertNotNil(Color.green1)
//        XCTAssertNotNil(Color.green2)
//        XCTAssertNotNil(Color.green3)
//        XCTAssertNotNil(Color.yellow1)
//        XCTAssertNotNil(Color.yellow2)
//        XCTAssertNotNil(Color.yellow3)
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
        XCTAssertEqual(450.rounded(toNextSignificant: 500), 500)
        XCTAssertEqual(-450.rounded(toNextSignificant: 500), -500)
        XCTAssertEqual(650.rounded(toNextSignificant: 500), 1000)
        XCTAssertEqual(-650.rounded(toNextSignificant: 500), -1000)
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
        XCTAssert(sevenDaysEarlier < currentDate)
    }
    
    func testAddDays() {
        let currentDate = Date()
        
        // Test subtracting zero days
        let sameDay = Date.add(days: 0, from: currentDate)
        XCTAssertTrue(Date.sameDay(date1: currentDate, date2: sameDay))
        
        // Test subtracting 7 days
        let sevenDaysLater = Date.add(days: 7, from: currentDate)
        XCTAssertEqual(Date.daysBetween(date1: sevenDaysLater, date2: currentDate), 7)
        XCTAssert(sevenDaysLater > currentDate)
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


