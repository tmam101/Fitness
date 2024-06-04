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
    }
    
    func testTypes() {
        XCTAssertNotNil(calorieManager.dietaryProtein)
    }
    
    func testPredicate() {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            XCTFail()
            return
        }
        let pred = calorieManager.predicate(daysAgo: 2, quantityType: quantityType)
        let startDate = Date.subtract(days: 2, from: Date())
        let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startDate)
        let testPred = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictEndDate, .strictStartDate])
        XCTAssertEqual(pred, testPred)
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
}

