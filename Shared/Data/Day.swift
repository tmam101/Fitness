//
//  Day.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 10/19/21.
//

import Foundation
import Charts
import SwiftUI

// MARK: DAY

struct Day: Codable, Identifiable, Plottable {
    
    var primitivePlottable: String = "Day"
    
    init?(primitivePlottable: String) {
        
    }
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         daysAgo: Int = -1,
         deficit: Double = 0,
         activeCalories: Double = 0,
         measuredActiveCalories: Double = 0,
         restingCalories: Double = 0,
         measuredRestingCalories: Double = 0,
         consumedCalories: Double = 0,
         runningTotalDeficit: Double = 0,
         expectedWeight: Double = 0,
         realisticWeight: Double = 0,
         weight: Double = 0,
         protein: Double = 0
    ) {
        self.id = id
        self.date = date
        self.daysAgo = daysAgo
        self.deficit = deficit
        self.activeCalories = activeCalories
        self.measuredActiveCalories = measuredActiveCalories
        self.restingCalories = restingCalories
        self.measuredRestingCalories = measuredRestingCalories
        self.consumedCalories = consumedCalories
        self.runningTotalDeficit = runningTotalDeficit
        self.expectedWeight = expectedWeight
        self.realisticWeight = realisticWeight
        self.weight = weight
        self.protein = protein
    }
    
    // TODO: WIP: make an initializer that accepts active calories, consumed, and resting, so we can calculate the deficit internally. 
//    init(id: UUID = UUID(),
//         date: Date = Date(),
//         daysAgo: Int = -1,
//         activeCalories: Double = 0,
//         measuredActiveCalories: Double = 0,
//         restingCalories: Double = 0,
//         measuredRestingCalories: Double = 0,
//         consumedCalories: Double = 0,
//         runningTotalDeficit: Double = 0,
//         expectedWeight: Double = 0,
//         realisticWeight: Double = 0,
//         weight: Double = 0,
//         protein: Double = 0
//    ) {
//        self.id = id
//        self.date = date
//        self.daysAgo = daysAgo
//        self.deficit =
//        self.activeCalories = activeCalories
//        self.measuredActiveCalories = measuredActiveCalories
//        self.restingCalories = restingCalories
//        self.measuredRestingCalories = measuredRestingCalories
//        self.consumedCalories = consumedCalories
//        self.runningTotalDeficit =
//        self.expectedWeight = expectedWeight
//        self.realisticWeight = realisticWeight
//        self.weight = weight
//        self.protein = protein
//    }
//    
//    func calculateDeficit() {
//        return (resting + (active * activeCalorieModifier)) - eaten
//    }
    
    typealias PrimitivePlottable = String
    
    var id = UUID()
    var date: Date = Date()
    var daysAgo: Int = -1
    var deficit: Double = 0
    var activeCalories: Double = 0
    var measuredActiveCalories: Double = 0
    var restingCalories: Double = 0
    var measuredRestingCalories: Double = 0
    var consumedCalories: Double = 0
    var runningTotalDeficit: Double = 0
    var expectedWeight: Double = 0
    var expectedWeightTomorrow: Double {
        expectedWeight + expectedWeightChangeBasedOnDeficit
    }
    var expectedWeightChangeBasedOnDeficit: Double {
        0 - (deficit / 3500)
    }
    var realisticWeight: Double = 0
    var weight: Double = 0
    var surplus: Double {
        deficit * -1
    }
    var activeCalorieToDeficitRatio: Double {
        activeCalories / deficit
    }
    var protein: Double = 0
    var proteinPercentage: Double {
        let p = (protein * caloriesPerGramOfProtein) / consumedCalories
        return p.isNaN ? 0 : p
    }
    var proteinGoalPercentage: Double {
        proteinPercentage / 0.3 // TODO Make settings
    }
    var caloriesPerGramOfProtein: Double = 4
    var deficitPercentage: Double {
        deficit / (Settings.get(key: .netEnergyGoal) as? Double ?? 1000)
    }
    
    var activeCaloriePercentage: Double {
        activeCalories / 900 // TODO Make settings
    }
    var averagePercentage: Double {
        (deficitPercentage + proteinGoalPercentage + activeCaloriePercentage) / 3
    }
    var weightChangePercentage: Double {
        expectedWeightChangeBasedOnDeficit / (-2/7) // TODO Make settings
    }

}
// MARK: DAYS
/// A collection of days, where passing a number indicates how many days ago the returned day will be.
typealias Days = [Int:Day]

extension Days {
    
    static var testDays: Days = {
        // TODO add running total deficit
        // TODO add active calories
        var days: Days = [:]
        var netEnergies: [Double] = [
            100, 200, 291, -32, -570, 334, -46, 794, -861, -310,
            951, -662, 332, 892, 482, 596, -312, -599, 36, 829,
            330, 232, 14, 153, -781, 654, -309, 830, 408, 272,
            405, 200, 291, -32, -570, 334, -46, 794, -861, -310,
            951, -662, 332, 892, 482, 596, -312, -599, 36, 829,
            330, 232, 14, 153, -781, 654, -309, 830, 408, 272,
            405, 232, 14, 153, -781, 654, -309, 830, 408, 272,
            405
        ]
        let count = netEnergies.count - 1
        days[count] = Day(date: Date.subtract(days: count, from: Date()), daysAgo: count, deficit: netEnergies[count], expectedWeight: 200)
        for i in (0...count-1).reversed() {
            guard let previousDay = days[i+1] else { return [:] }
            let previousWeight = previousDay.expectedWeight
            let expectedWeight = previousWeight + previousDay.expectedWeightChangeBasedOnDeficit
            days[i] = Day(date: Date.subtract(days: i, from: Date()), daysAgo: i, deficit: netEnergies[i], expectedWeight: expectedWeight) // TODO Not sure exactly how expectedWeight and expectedWeightChangeBasedOnDeficit should relate to each other.
        }
        days.addRunningTotalDeficits()
        return days
    }()
    
    //TODO: Test
    func upTo(date: Date) -> Days {
        return self.filter {
            let days = $0.key - 1
            let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date())
            let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
            return startDate <= date
        }
    }
    
    mutating func addRunningTotalDeficits() {
        var i = self.count - 1
        var runningTotalDeficit: Double = 0
        while i >= 0 {
            let deficit = self[i]?.deficit ?? 0
            runningTotalDeficit = runningTotalDeficit + deficit
            self[i]?.runningTotalDeficit = runningTotalDeficit
            i -= 1
        }
    }
    
    enum DayProperty {
        case activeCalories
        case restingCalories
        case consumedCalories
        case weight
        case realisticWeight
        case expectedWeight
        case surplus
        case deficit
    }
    
    func sum(property: DayProperty) -> Double {
        return Array(self.values)
            .map {
                switch property {
                case .activeCalories:
                    return $0.activeCalories
                case .restingCalories:
                   return $0.restingCalories
                case .consumedCalories:
                   return $0.consumedCalories
                case .weight:
                    return $0.weight
                case .realisticWeight:
                    return $0.realisticWeight
                case .expectedWeight:
                    return $0.expectedWeight
                case .surplus:
                    return $0.surplus
                case .deficit:
                    return $0.deficit
                }
            }
            .reduce(0, { x, y in x + y })
    }
    
//    func averageDeficitOfPreviousWeek() -> Double? {
//        guard let yesterday = self[1], let firstDayOfWeek = self[8] else { return nil }
//        return (yesterday.runningTotalDeficit  - firstDayOfWeek.runningTotalDeficit) / 7
//    }
    
    // TODO Unit test. Is this right?
    func averageDeficitOfPrevious(days: Int, endingOnDay day: Int) -> Double? {
        guard 
            let lastDay = self[day],
            let firstDay = self[Swift.min(self.keys.count - 1, days - day)]
        else { return nil }
        return (lastDay.runningTotalDeficit  - firstDay.runningTotalDeficit) / Double(days - day)
    }
    
//    func averageDeficitOfPreviousMonth() -> Double? {
//        guard let yesterday = self[1], let firstDayOfMonth = self[31] else { return nil }
//        return (yesterday.runningTotalDeficit  - firstDayOfMonth.runningTotalDeficit) / 7
//    }
}
