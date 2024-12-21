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
    let testDate = Date()
    
    init() {
        calorieManager = CalorieManager(environment: .debug)
    }
    
    func setup() async {
        let twentyDaysAgo = testDate.subtracting(days: 20)
        let tenDaysAgo = testDate.subtracting(days: 10)
        await calorieManager.setup(oldestWeight: Weight(weight: 230, date: twentyDaysAgo), newestWeight: Weight(weight: 200, date: tenDaysAgo), daysBetweenStartAndNow: 20)
    }
    
    @Test func types() {
        #expect(calorieManager.dietaryProtein != nil)
    }
    
    @Test("Health Kit Types have expected values")
    func healthKitTypeProperties() {
        for v in HealthKitType.allCases {
            #expect(v.value != nil, "HealthKit type should have a value")
        }
        #expect(HealthKitType.allCases.count == 4, "Should have exactly 4 HealthKit types")
        
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
        #expect(result == 0)
        result = await calorieManager.sumValueForDay(daysAgo: 0, forType: .dietaryProtein)
        #expect(result == 0)
        
        result = await calorieManager.sumValueForDay(daysAgo: 4, forType: .dietaryEnergyConsumed)
        #expect(result == 1560)
        result = await calorieManager.sumValueForDay(daysAgo: 4, forType: .dietaryProtein)
        #expect(result == 90)
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
    
    @Test("Day calculations are accurate")
    func dayCalculations() async {
        await setup()
        let days = await calorieManager.getDays(forPastDays: 20)
        
        guard let oldestDay = days.oldestDay,
              let newestDay = days.newestDay else {
            Issue.record("Failed to get oldest and newest days")
            return
        }
        
        #expect(days.count == 21, "Should have 21 days including today")
        
        #expect(oldestDay.activeCalories.isApproximately(465.24, accuracy: 0.01))
        #expect(oldestDay.restingCalories.isApproximately(2268.96, accuracy: 0.01))
        #expect(oldestDay.daysAgo == 20)
        #expect(oldestDay.consumedCalories == 0)
        #expect(oldestDay.date == testDate.subtracting(days: 20))
        
        let expectedDeficit = oldestDay.restingCalories + oldestDay.activeCalories
        #expect(oldestDay.runningTotalDeficit.isApproximately(expectedDeficit, accuracy: 0.1))
        #expect(oldestDay.netEnergy.isApproximately(-expectedDeficit, accuracy: 0.1))
        
        let expectedTotalDeficit = days.sum(property: .deficit)
        #expect(expectedTotalDeficit.isApproximately(56220.10, accuracy: 0.1))
        #expect(days.newestDay?.runningTotalDeficit == expectedTotalDeficit)
        
        let expectedTotalNetEnergy = days.sum(property: .netEnergy)
        #expect(expectedTotalNetEnergy.isApproximately(-56220.10, accuracy: 0.1))
        let expectedWeightChange = expectedTotalNetEnergy / Constants.numberOfCaloriesInPound
        #expect(expectedWeightChange.isApproximatelyEqual(to: -12.285714, absoluteTolerance: 0.001, norm: { (x) -> Double in
            return Double(x)
        }))
        let d: Decimal = 0.00500
        #expect(d.isApproximately(0.00510, accuracy: 0.001))
        
        #expect(newestDay.activeCalories == 200)
        #expect(newestDay.restingCalories == 2150)
        #expect(newestDay.consumedCalories == 0)
        #expect(newestDay.date == testDate.subtracting(days: 0))
    }
}
