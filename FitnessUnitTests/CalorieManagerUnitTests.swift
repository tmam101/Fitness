//
//  CalorieManagerUnitTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 6/4/24.
//

import XCTest
import HealthKit
@testable import Fitness

class CalorieManagerUnitTests: XCTestCase {
    var calorieManager: CalorieManager!
    
    override func setUp() {
        calorieManager = CalorieManager()
        calorieManager.environment = .debug(nil)
    }
    
    func testTypes() {
        XCTAssertNotNil(calorieManager.dietaryProtein)
    }
    
    func testspecificDayPredicate() {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            XCTFail()
            return
        }
        let pred = calorieManager.specificDayPredicate(daysAgo: 2, quantityType: quantityType)
        let startDate = Date.subtract(days: 2, from: Date())
        let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startDate)
        let testPred = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictEndDate, .strictStartDate])
        XCTAssertEqual(pred, testPred)
    }
    
    func testPastDaysPredicate() {
        for days in 1...100 {
            let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date()) // why?
            let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictEndDate, .strictStartDate])
            XCTAssertEqual(predicate, calorieManager.pastDaysPredicate(days: days), "Past day predicates not equal for daysAgo \(days)")
        }
        // TODO test day 0. Why are we saying Date() unstead of startofday?
        // TODO you can't because it relies on Date(), which changes between lines of code
//        let days = 0
//        let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date())
//        let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictEndDate, .strictStartDate])
//        XCTAssertEqual(predicate, calorieManager.pastDaysPredicate(days: days), "Past day predicates not equal for daysAgo \(days)")
    }
    
    func testHealthKitValue() {
        for v in HealthKitValue.allCases {
            XCTAssertNotNil(v.value)
        }
        XCTAssertEqual(HealthKitValue.allCases.count, 4)
        XCTAssertEqual(HealthKitValue.dietaryProtein.value, HKQuantityType(.dietaryProtein))
        XCTAssertEqual(HealthKitValue.dietaryEnergyConsumed.value, HKQuantityType(.dietaryEnergyConsumed))
        XCTAssertEqual(HealthKitValue.activeEnergyBurned.value, HKQuantityType(.activeEnergyBurned))
        XCTAssertEqual(HealthKitValue.basalEnergyBurned.value, HKQuantityType(.basalEnergyBurned))
        
        XCTAssertEqual(HealthKitValue.activeEnergyBurned.unit, .kilocalorie())
        XCTAssertEqual(HealthKitValue.dietaryProtein.unit, .gram())
        XCTAssertEqual(HealthKitValue.dietaryEnergyConsumed.unit, .kilocalorie())
        XCTAssertEqual(HealthKitValue.basalEnergyBurned.unit, .kilocalorie())
        }
    
    func testConvertSumToDouble() {
        var quantity: HKQuantity? = .init(unit: .gram(), doubleValue: 100)
        
        for h in HealthKitValue.allCases {
            switch h {
            case .dietaryProtein:
                XCTAssert(quantity!.is(compatibleWith: h.unit))
            case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed:
                XCTAssertFalse(quantity!.is(compatibleWith: h.unit))
            }
        }
        XCTAssertEqual(calorieManager.convertSumToDouble(sum: quantity, type: .dietaryProtein), 100)
        XCTAssertEqual(calorieManager.convertSumToDouble(sum: quantity, type: .activeEnergyBurned), 0)
        quantity = .init(unit: .kilocalorie(), doubleValue: 100)
        for h in HealthKitValue.allCases {
            switch h {
            case .dietaryProtein:
                XCTAssertFalse(quantity!.is(compatibleWith: h.unit))
            case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed:
                XCTAssert(quantity!.is(compatibleWith: h.unit))
            }
        }
        XCTAssertEqual(calorieManager.convertSumToDouble(sum: quantity, type: .dietaryProtein), 0)
        XCTAssertEqual(calorieManager.convertSumToDouble(sum: quantity, type: .activeEnergyBurned), 100)
    }
    
    func testSumValueForDay() async {
        var result = await calorieManager.sumValueForDay(daysAgo: 0, forType: .dietaryEnergyConsumed)
        XCTAssertEqual(result, 1000)
        result = await calorieManager.sumValueForDay(daysAgo: 0, forType: .dietaryProtein)
        XCTAssertEqual(result, 0)
    }
}

