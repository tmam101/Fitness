//
//  ExtensionUnitTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 10/16/23.
//

import Testing
@testable import Fitness
import SwiftUI

@Suite 

struct ArrayExtensionTests {

    @Test func sum() {
        // Test with integers
        #expect([1, 2, 3, 4, 5].sum == 15)
        
        // Test with floating-point numbers
        #expect([1.0, 2.0, 3.0, 4.0, 5.0].sum as Double == 15.0)
        
        // Test with empty array (edge case)
        #expect([Int]().sum == 0)
    }

    @Test func average() {
        // Test with integers
        #expect([1, 2, 3, 4, 5].average == 3.0)
        
        // Test with floating-point numbers
        #expect([1.0, 2.0, 3.0, 4.0, 5.0].average == 3.0)
        
        // Test with empty array (edge case)
        #expect([Double]().average == nil)
    }
    
    @Test func decodingArrayJSON() {
        if let array: [Double] = .decode(path: .activeCalories) {
            #expect(array != nil)
            
            let activeCalories: [Double] = [
                530.484, 426.822, 401.081, 563.949, 329.136, 304.808, 1045.074, 447.229, 1140.485, 287.526,
                664.498, 729.646, 141.281, 137.878, 185.565, 524.932, 387.086, 206.355, 895.737, 161.954,
                619.241, 624.191, 284.112, 272.095, 840.536, 158.428, 443.622, 264.205, 1025.872, 394.575,
                135.940, 696.240, 976.788, 383.816, 1057.616, 1056.868, 741.806, 1145.090, 514.840, 674.655,
                620.510, 1151.488, 696.858, 724.303, 953.539, 117.319, 207.876, 884.699, 672.569, 659.526,
                366.072, 672.032, 536.885, 1075.278, 705.510, 362.428, 1157.047, 376.990, 808.443, 1141.884,
                1047.608, 927.059, 1001.858, 364.928, 694.303, 241.747, 852.663, 564.521, 585.509, 970.332
            ]
            
            #expect(array == activeCalories)
        } else {
            Issue.record()
        }
    }
    
    @Test func encodingArrayJSON() {
        let array: [Double] = [1.0, 2.0, 3.0]
        #expect(array.encodeAsString() == """
[
  1,
  2,
  3
]
"""
        )
    }
    
    @Test func reversingArray() {
        let weightGoingSteadilyDown: [Double] = [
            200.00, 199.98, 200.00, 199.73, 199.64, 199.92, 199.52, 199.27, 199.20, 199.09, 198.63, 198.49, 198.76, 198.94, 199.10,
            199.09, 199.17, 198.95, 198.47, 198.19, 198.34, 198.43, 198.44, 198.73, 198.91, 198.61, 198.90, 198.55, 198.72, 198.73,
            198.64, 198.80, 199.01, 198.62, 198.57, 198.78, 199.01, 199.13, 199.02, 199.05, 198.73, 198.68, 198.96, 198.75, 198.87,
            199.02, 199.24, 199.40, 199.24, 198.93, 199.06, 199.13, 198.70, 198.86, 198.87, 198.42, 198.51, 198.53, 198.17, 198.33,
            198.03, 198.08, 197.96, 198.10, 198.14, 197.87, 197.79, 197.69, 197.65, 197
        ].reversed()
        print(weightGoingSteadilyDown)
    }
    
    struct TestEvent: HasDate {
        var date: Date
    }
    
    @Test func sortedMostRecentToLongestAgo() {
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
        #expect(sortedEvents[0].date == now, "The most recent date should be first")
        #expect(sortedEvents[1].date == oneHourAgo, "The second most recent date should be second")
        #expect(sortedEvents[2].date == twoHoursAgo, "The oldest date should be last")
        
        sortedEvents = events.sorted(.longestAgoToMostRecent)
        
        // Assert
        #expect(sortedEvents[0].date == twoHoursAgo, "The oldest date should be first")
        #expect(sortedEvents[1].date == oneHourAgo, "The second oldest date should be second")
        #expect(sortedEvents[2].date == now, "The newest date should be last")
        
    }
    
    @Test func sortedMostRecentToLongestAgoWithSameDates() {
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
        #expect(sortedEvents.count == 3, "All events should be present")
        #expect(sortedEvents.allSatisfy { $0.date == date }, "All dates should be the same")
    }
    
    @Test func sortedMostRecentToLongestAgoWithEmptyArray() {
        // Arrange
        let events: [TestEvent] = []
        
        // Act
        let sortedEvents = events.sorted(.mostRecentToLongestAgo)
        
        // Assert
        #expect(sortedEvents.isEmpty, "The sorted array should be empty")
    }
    
    @Test func sortingDates() {
        let oneDayAgo = Day(daysAgo: 1)
        let twoDayAgo = Day(daysAgo: 2)
        let threeDayAgo = Day(daysAgo: 3)
        #expect(oneDayAgo.date.daysAgo() == 1)
        #expect(twoDayAgo.date.daysAgo() == 2)
        #expect(threeDayAgo.date.daysAgo() == 3)
        let dates = [oneDayAgo, twoDayAgo, threeDayAgo]
        #expect(dates.first == oneDayAgo)
        var sorted = dates.sorted(.longestAgoToMostRecent)
        #expect(sorted.first == threeDayAgo)
        #expect(sorted.last == oneDayAgo)
        sorted = dates.sorted(.mostRecentToLongestAgo)
        #expect(sorted.first == oneDayAgo)
        #expect(sorted.last == threeDayAgo)
    }
}


@Suite 


struct ColorTests {
    
    @Test func customColors() {
        // Verify that custom colors are correctly initialized
        #expect(Color.myGray != nil)
        #expect(Color.expectedWeightYellow != nil)
        #expect(Color.weightGreen != nil)
        #expect(Color.realisticWeightGreen != nil)
//        XCTAssertNotNil(Color.green1)
//        XCTAssertNotNil(Color.green2)
//        XCTAssertNotNil(Color.green3)
//        XCTAssertNotNil(Color.yellow1)
//        XCTAssertNotNil(Color.yellow2)
//        XCTAssertNotNil(Color.yellow3)
    }
    
    @Test func solidColorGradient() {
        // Test the solidColorGradient() function
        let gradient = Color.myGray.solidColorGradient()
        #expect(gradient != nil)
    }
    
}

@Suite 

struct SettingsTests {
    @Test func userDefaultsStorage() {
        // Test storing and retrieving a basic value
        let testValue = "TestValue"
        Settings.set(key: .active, value: testValue)
        let retrievedValue = Settings.get(key: .active) as? String
        #expect(testValue == retrievedValue)
    }
    
    // Assuming Days is defined or can be mocked for testing
    @Test func daysEncodingAndDecoding() {
        // Mock a Days object (assuming it's a dictionary for simplicity)
        let mockDays: Days = [1: Day()]  // This needs to be adjusted based on the actual Days and Day types
        Settings.setDays(days: mockDays)
        let retrievedDays = Settings.getDays()
        #expect(mockDays == retrievedDays)
    }
    
}

@Suite 

struct DoubleTests {
    
    @Test func toRadians() {
        let degrees: Double = 180
        #expect(degrees.toRadians() == Double.pi) // TODO swift-numerics isapproximatelyequal from docs
    }
    
    @Test func toCGFloat() {
        let doubleValue: Double = 123.45
        let expected: CGFloat = 123.45
        #expect(doubleValue.toCGFloat() == expected)
    }
    
    @Test func roundedToNextSignificant() {
        let value: Double = 123.45
        let goal: Double = 10.0
        let expected: Double = 130.0
        #expect(value.rounded(toNextSignificant: goal) == expected)
        #expect(450.rounded(toNextSignificant: 500) == 500)
        #expect(-450.rounded(toNextSignificant: 500) == -500)
        #expect(650.rounded(toNextSignificant: 500) == 1000)
        #expect(-650.rounded(toNextSignificant: 500) == -1000)
    }
    
    @Test func roundedString() {
        let value: Double = 123.4567
        let expected: String = "123.46"
        #expect(value.roundedString() == expected)
    }
    
    @Test func percentageToWholeNumber() {
        let value: Double = 0.45
        let expected: String = "45"
        #expect(value.percentageToWholeNumber() == expected)
    }
}

@Suite 

struct DateTests {
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
    
    @Test func daysBetween() {
        // Test with same day
        let date1 = Date()
        let date2 = Date()
        #expect(Date.daysBetween(date1: date1, date2: date2) == 0)
        
        // Test with one day difference
        let oneDayLater = Calendar.current.date(byAdding: .day, value: 1, to: date1)!
        #expect(Date.daysBetween(date1: date1, date2: oneDayLater) == 1)
        
        // Test with negative days (date2 is earlier than date1)
        #expect(Date.daysBetween(date1: oneDayLater, date2: date1) == 1)
        
        // Test with empty date (edge case)
        let emptyDate = Date(timeIntervalSince1970: 0)
        #expect(Date.daysBetween(date1: emptyDate, date2: date1) != 0)
    }
    
    @Test func daysAgo() {
        let twoDaysAgo = Day(daysAgo: 2)
        #expect(twoDaysAgo.daysAgo == twoDaysAgo.date.daysAgo())
        
        let date = Date()
        #expect(date.daysAgo() == 0)
    }
    
    @Test func dateFromString() {
        // Test with valid date string
        #expect(Date.dateFromString("01.01.2022") != nil)
        
        // Test with invalid date string
        #expect(Date.dateFromString("invalid.date") == nil)
        
        // Test with another valid date string
        let expectedDate = Date.dateFromString("12.31.2021")
        #expect(expectedDate != nil)
    }
    
    @Test func dateFromStringComponents() {
        // Test with valid date components
        #expect(Date.dateFromString(month: "01", day: "01", year: "2022") != nil)
        
        // Test with invalid date components
        #expect(Date.dateFromString(month: "invalid", day: "date", year: "components") == nil)
    }
    
    @Test func subtractDays() {
        let currentDate = Date()
        
        // Test subtracting zero days
        let sameDay = Date.subtract(days: 0, from: currentDate)
        #expect(Date.sameDay(date1: currentDate, date2: sameDay))
        
        // Test subtracting 7 days
        let sevenDaysEarlier = Date.subtract(days: 7, from: currentDate)
        #expect(Date.daysBetween(date1: sevenDaysEarlier, date2: currentDate) == 7)
        #expect(sevenDaysEarlier < currentDate)
    }
    
    @Test func addDays() {
        let currentDate = Date()
        
        // Test subtracting zero days
        let sameDay = Date.add(days: 0, from: currentDate)
        #expect(Date.sameDay(date1: currentDate, date2: sameDay))
        
        // Test subtracting 7 days
        let sevenDaysLater = Date.add(days: 7, from: currentDate)
        #expect(Date.daysBetween(date1: sevenDaysLater, date2: currentDate) == 7)
        #expect(sevenDaysLater > currentDate)
    }
    
    @Test func sameDay() {
        let date1 = Date()
        
        // Test with the same date
        #expect(Date.sameDay(date1: date1, date2: date1))
        
        // Test with different date
        let date2 = Date.subtract(days: 1, from: date1)
        #expect(!Date.sameDay(date1: date1, date2: date2))
    }
    
    @Test func startOfDay() {
        let currentDate = Date()
        let startOfDay = Date.startOfDay(currentDate)
        
        // Ensure that the time components are all zero
        let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: startOfDay)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
        #expect(components.nanosecond == 0)
    }
    
    @Test func dayOfWeek() {
        // Test with a known date (e.g., 1st January 2022 was a Saturday)
        let knownDate = Date.dateFromString("01.01.2022")!
        #expect(knownDate.dayOfWeek() == "Saturday")
    }
    
}

@Suite 

struct TimeTests {
    @Test func doubleToString() {
        // Test with a normal double value
        #expect(Time.doubleToString(double: 12.5) == "12:30")
        
        // Test with a whole number
        #expect(Time.doubleToString(double: 10.0) == "10:00")
        
        // Test with a very small value (edge case)
        #expect(Time.doubleToString(double: 0.01) == "0:01")
        
        // Test with a negative value (edge case)
        #expect(Time.doubleToString(double: -12.5) == "-12:30")
        
        // Test with zero (edge case)
        #expect(Time.doubleToString(double: 0.0) == "0:00")
        
        // Test with a negative whole number (edge case)
        #expect(Time.doubleToString(double: -10.0) == "-10:00")
    }
}


