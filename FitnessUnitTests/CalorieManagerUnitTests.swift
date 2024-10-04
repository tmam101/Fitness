//
//  CalorieManagerUnitTests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 6/4/24.
//

import Testing
import HealthKit
@testable import Fitness
import Numerics

@Suite 

struct CalorieManagerUnitTests {
    var calorieManager: CalorieManager!
    
    init() {
        calorieManager = CalorieManager(environment: .debug)
    }
    
    func setup() async {
        let date = Date()
        let twentyDaysAgo = Date.subtract(days: 20, from: date)
        let tenDaysAgo = Date.subtract(days: 10, from: date)
        await calorieManager.setup(oldestWeight: Weight(weight: 230, date: twentyDaysAgo), newestWeight: Weight(weight: 200, date: tenDaysAgo), daysBetweenStartAndNow: 20)
    }
    
    @Test func types() {
        #expect(calorieManager.dietaryProtein != nil)
    }
    
    @Test func specificDayPredicate() {
        guard let _ = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            Issue.record()
            return
        }
        let pred = calorieManager.specificDayPredicate(daysAgo: 2)
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
        #expect(predicate == calorieManager.pastDaysPredicate(days: days), "Past day predicates not equal for daysAgo \(days)")
        // TODO test day 0. Why are we saying Date() unstead of startofday?
        // TODO you can't because it relies on Date(), which changes between lines of code
//        let days = 0
//        let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date())
//        let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictEndDate, .strictStartDate])
//        XCTAssertEqual(predicate, calorieManager.pastDaysPredicate(days: days), "Past day predicates not equal for daysAgo \(days)")
    }
    
    @Test func healthKitType() {
        for v in HealthKitType.allCases {
            #expect(v.value != nil)
        }
        #expect(HealthKitType.allCases.count == 4)
        #expect(HealthKitType.dietaryProtein.value == HKQuantityType(.dietaryProtein))
        #expect(HealthKitType.dietaryEnergyConsumed.value == HKQuantityType(.dietaryEnergyConsumed))
        #expect(HealthKitType.activeEnergyBurned.value == HKQuantityType(.activeEnergyBurned))
        #expect(HealthKitType.basalEnergyBurned.value == HKQuantityType(.basalEnergyBurned))
        
        #expect(HealthKitType.activeEnergyBurned.unit == .kilocalorie())
        #expect(HealthKitType.dietaryProtein.unit == .gram())
        #expect(HealthKitType.dietaryEnergyConsumed.unit == .kilocalorie())
        #expect(HealthKitType.basalEnergyBurned.unit == .kilocalorie())
        }
    
    @Test func convertSumToDecimal() {
        var quantity: HKQuantity? = .init(unit: .gram(), doubleValue: 100)
        
        for h in HealthKitType.allCases {
            switch h {
            case .dietaryProtein:
                #expect(quantity!.is(compatibleWith: h.unit))
            case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed:
                #expect(!quantity!.is(compatibleWith: h.unit))
            }
        }
        #expect(calorieManager.convertSumToDecimal(sum: quantity, type: .dietaryProtein) == 100)
        #expect(calorieManager.convertSumToDecimal(sum: quantity, type: .activeEnergyBurned) == 0)
        quantity = .init(unit: .kilocalorie(), doubleValue: 100)
        for h in HealthKitType.allCases {
            switch h {
            case .dietaryProtein:
                #expect(!quantity!.is(compatibleWith: h.unit))
            case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergyConsumed:
                #expect(quantity!.is(compatibleWith: h.unit))
            }
        }
        #expect(calorieManager.convertSumToDecimal(sum: quantity, type: .dietaryProtein) == 0)
        #expect(calorieManager.convertSumToDecimal(sum: quantity, type: .activeEnergyBurned) == 100)
    }
    
    @Test func sumValueForDay() async {
        var result = await calorieManager.sumValueForDay(daysAgo: 0, forType: .dietaryEnergyConsumed)
        #expect(result == 1000)
        result = await calorieManager.sumValueForDay(daysAgo: 0, forType: .dietaryProtein)
        #expect(result == 1000)
    }
    
    @Test func healthSample() {
        let calories: Decimal = 300
        let twoDaysAgo = Day(daysAgo: 2).date
        let threeDaysAgo = Day(daysAgo: 3).date
        guard let caloriesEatenType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            Issue.record()
            return
        }
        let caloriesEatenQuantity = HKQuantity(unit: HealthKitType.dietaryEnergyConsumed.unit,
                                               doubleValue: Double(calories))
        
        let calorieCountSample = HKQuantitySample(type: caloriesEatenType,
                                                  quantity: caloriesEatenQuantity,
                                                  start: threeDaysAgo,
                                                  end: twoDaysAgo)
        let sample = calorieManager.healthSample(amount: 300, type: .dietaryEnergyConsumed, start: threeDaysAgo, end: twoDaysAgo)
        #expect(calorieCountSample.quantity == sample?.quantity)
        #expect(calorieCountSample.quantityType == sample?.quantityType)
        #expect(calorieCountSample.endDate == sample?.endDate)
        #expect(calorieCountSample.startDate == sample?.startDate)
        #expect(calorieCountSample.count == sample?.count)
    }
    
    @Test func getDays() async {
        await setup()
        let days = await calorieManager.getDays(forPastDays: 20)
        guard let oldestDay = days.oldestDay, let newestDay = days.newestDay else {
            Issue.record()
            return
        }
        // Should have the past x days plus today
        #expect(days.count == 21)
        // Test oldest day properties are set
        #expect(oldestDay.activeCalories == 1000)
        #expect(oldestDay.restingCalories == 2150)
        #expect(oldestDay.consumedCalories == 1000)
//        XCTAssertEqual(oldestDay.expectedWeight, 230)
        // TODO We are now moving expected weight calculation into the Days object. TBD if i want this long term
        #expect(oldestDay.runningTotalDeficit == 2150)
        #expect(oldestDay.date == Date().subtracting(days: 20))
        #expect(oldestDay.protein == 1000)
        #expect(oldestDay.deficit == oldestDay.runningTotalDeficit)
        
        // Test newest day properties are set
        #expect(newestDay.activeCalories == 1000)
        #expect(newestDay.restingCalories == 2150)
        #expect(newestDay.consumedCalories == 1000)
        // Test deficit, net energy, and expected weight change
        let expectedTotalDeficit = days.sum(property: .deficit)
        #expect(expectedTotalDeficit == Decimal(days.count) * Decimal(2150))
        #expect(expectedTotalDeficit == 45150)
        #expect(expectedTotalDeficit == days.newestDay?.runningTotalDeficit)
        let expectedTotalNetEnergy = days.dropping(0).sum(property: .netEnergy)
        #expect(expectedTotalNetEnergy == Decimal(days.count - 1) * Decimal(-2150))
        #expect(expectedTotalNetEnergy == -43000)
        let expectedWeightChange = expectedTotalNetEnergy / Constants.numberOfCaloriesInPound
        #expect(expectedWeightChange.isApproximatelyEqual(to: -12.285714, absoluteTolerance: 0.001, norm: { (x) -> Double in
            return Double(x)
        }))
        let d: Decimal = 0.00500
        #expect(d.isApproximately(0.00510, accuracy: 0.001))
//        XCTAssertEqual(newestDay.expectedWeight, oldestDay.expectedWeight + expectedWeightChange)
        #expect(newestDay.date == Date().subtracting(days: 0))
    }
}
