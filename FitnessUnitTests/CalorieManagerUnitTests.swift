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
    
    func setup() async {
        let date = Date()
        let twentyDaysAgo = Date.subtract(days: 20, from: date)
        let tenDaysAgo = Date.subtract(days: 10, from: date)
        await calorieManager.setup(oldestWeight: Weight(weight: 230, date: twentyDaysAgo), newestWeight: Weight(weight: 200, date: tenDaysAgo), daysBetweenStartAndNow: 20, environment: .debug(nil))
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
    
    func testHealthKitType() {
        for v in HealthKitType.allCases {
            XCTAssertNotNil(v.value)
        }
        XCTAssertEqual(HealthKitType.allCases.count, 4)
        XCTAssertEqual(HealthKitType.dietaryProtein.value, HKQuantityType(.dietaryProtein))
        XCTAssertEqual(HealthKitType.dietaryEnergyConsumed.value, HKQuantityType(.dietaryEnergyConsumed))
        XCTAssertEqual(HealthKitType.activeEnergyBurned.value, HKQuantityType(.activeEnergyBurned))
        XCTAssertEqual(HealthKitType.basalEnergyBurned.value, HKQuantityType(.basalEnergyBurned))
        
        XCTAssertEqual(HealthKitType.activeEnergyBurned.unit, .kilocalorie())
        XCTAssertEqual(HealthKitType.dietaryProtein.unit, .gram())
        XCTAssertEqual(HealthKitType.dietaryEnergyConsumed.unit, .kilocalorie())
        XCTAssertEqual(HealthKitType.basalEnergyBurned.unit, .kilocalorie())
        }
    
    func testConvertSumToDouble() {
        var quantity: HKQuantity? = .init(unit: .gram(), doubleValue: 100)
        
        for h in HealthKitType.allCases {
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
        for h in HealthKitType.allCases {
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
        XCTAssertEqual(result, 1000)
    }
    
    func testHealthSample() {
        let calories: Double = 300
        let twoDaysAgo = Day(daysAgo: 2).date
        let threeDaysAgo = Day(daysAgo: 3).date
        guard let caloriesEatenType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            XCTFail()
            return
        }
        let caloriesEatenQuantity = HKQuantity(unit: HealthKitType.dietaryEnergyConsumed.unit,
                                               doubleValue: calories)
        
        let calorieCountSample = HKQuantitySample(type: caloriesEatenType,
                                                  quantity: caloriesEatenQuantity,
                                                  start: threeDaysAgo,
                                                  end: twoDaysAgo)
        let sample = calorieManager.healthSample(amount: 300, type: .dietaryEnergyConsumed, start: threeDaysAgo, end: twoDaysAgo)
        XCTAssertEqual(calorieCountSample.quantity, sample?.quantity)
        XCTAssertEqual(calorieCountSample.quantityType, sample?.quantityType)
        XCTAssertEqual(calorieCountSample.endDate, sample?.endDate)
        XCTAssertEqual(calorieCountSample.startDate, sample?.startDate)
        XCTAssertEqual(calorieCountSample.count, sample?.count)
    }
    
    func testGetDays() async {
        await setup()
        let days = await calorieManager.getDays(forPastDays: 20)
        guard let oldestDay = days.oldestDay, let newestDay = days.newestDay else {
            XCTFail()
            return
        }
        XCTAssertEqual(oldestDay.activeCalories, 1000)
        XCTAssertEqual(oldestDay.restingCalories, 2150)
        XCTAssertEqual(oldestDay.consumedCalories, 1000)
        XCTAssertEqual(oldestDay.expectedWeight, 230)
        XCTAssertEqual(oldestDay.runningTotalDeficit, 2150)
        XCTAssertEqual(oldestDay.deficit, oldestDay.runningTotalDeficit)
        
        XCTAssertEqual(newestDay.activeCalories, 1000)
        XCTAssertEqual(newestDay.restingCalories, 2150)
        XCTAssertEqual(newestDay.consumedCalories, 1000)
        let expectedTotalDeficit = days.sum(property: .deficit)
        XCTAssertEqual(expectedTotalDeficit, Double(days.count) * Double(2150))
        XCTAssertEqual(expectedTotalDeficit, 45150)
        XCTAssertEqual(expectedTotalDeficit, days.newestDay?.runningTotalDeficit)
        let expectedTotalNetEnergy = days.sum(property: .netEnergy)
        XCTAssertEqual(expectedTotalNetEnergy, Double(days.count) * Double(-2150))
        XCTAssertEqual(expectedTotalNetEnergy, -45150)
        let expectedWeightChange = expectedTotalNetEnergy / Constants.numberOfCaloriesInPound
        XCTAssertEqual(expectedWeightChange, -12.9)
        XCTAssertEqual(newestDay.expectedWeight, oldestDay.expectedWeight + expectedWeightChange)
//        XCTAssertEqual(newestDay.expectedWeight, 230 - expectedWeight)
    }
}

