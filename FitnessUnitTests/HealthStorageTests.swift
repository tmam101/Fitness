//
//  HealthStorageTests.swift
//  Fitness
//
//  Created by Thomas Goss on 12/9/24.
//

import Testing
@testable import Fitness
import Combine
import Foundation
import HealthKit

@Suite

final class HealthStorageTests {
    
    @Test func specificDayPredicate() {
        guard let _ = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            Issue.record()
            return
        }
        let pred = HealthStorage().specificDayPredicate(daysAgo: 2)
        let startDate = Date.subtract(days: 2, from: Date())
        let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startDate)
        let testPred = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictEndDate, .strictStartDate])
        #expect(pred == testPred)
    }
    
    @Test("Past Days Predicate", arguments: 1...100)
    func pastDaysPredicate(days: Int) {
        let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date()) // why?
        let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictEndDate, .strictStartDate])
        #expect(predicate == HealthStorage().pastDaysPredicate(days: days), "Past day predicates not equal for daysAgo \(days)")
        // TODO test day 0. Why are we saying Date() unstead of startofday?
        // TODO you can't because it relies on Date(), which changes between lines of code
        //        let days = 0
        //        let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date())
        //        let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
        //        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictEndDate, .strictStartDate])
        //        XCTAssertEqual(predicate, calorieManager.pastDaysPredicate(days: days), "Past day predicates not equal for daysAgo \(days)")
    }
}
