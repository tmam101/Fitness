//
//  Day.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 10/19/21.
//

import Foundation
import Charts
import SwiftUI

struct Day: Codable, Identifiable, Plottable {
    var primitivePlottable: String = "Day"
//    private static var gradientColors = {
//        var colors: [Color] = []
//        for _ in 0..<100 {
//            colors.append(.orange)
//        }
//        colors.append(.yellow)
//        return colors
//    }()
//    var gradient: LinearGradient {
//        let gradientPercentage = CGFloat(self.activeCalorieToDeficitRatio)
//            let midPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y * (1 - gradientPercentage))
//            let startPoint = UnitPoint(x: (UnitPoint.bottom.x - UnitPoint.bottom.x / 2), y: UnitPoint.bottom.y)
//        let gradientStyle: LinearGradient = .linearGradient(colors: Day.gradientColors,
//                                                                startPoint: startPoint,
//                                                                endPoint: midPoint)
//            return gradientStyle
//    }
    
    init?(primitivePlottable: String) {
        
    }
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         daysAgo: Int = -1,
         deficit: Double = 0,
         activeCalories: Double = 0,
         realActiveCalories: Double = 0,
         restingCalories: Double = 0,
         realRestingCalories: Double = 0,
         consumedCalories: Double = 0,
         runningTotalDeficit: Double = 0,
         expectedWeight: Double = 0,
         expectedWeightChangedBasedOnDeficit: Double = 0,
         realisticWeight: Double = 0,
         weight: Double = 0,
         protein: Double = 0
    ) {
        self.id = id
        self.date = date
        self.daysAgo = daysAgo
        self.deficit = deficit
        self.activeCalories = activeCalories
        self.realActiveCalories = realActiveCalories
        self.restingCalories = restingCalories
        self.realRestingCalories = realRestingCalories
        self.consumedCalories = consumedCalories
        self.runningTotalDeficit = runningTotalDeficit
        self.expectedWeight = expectedWeight
        self.expectedWeightChangedBasedOnDeficit = expectedWeightChangedBasedOnDeficit
        self.realisticWeight = realisticWeight
        self.weight = weight
        self.protein = protein
    }
    
    typealias PrimitivePlottable = String
    
    var id = UUID()
    var date: Date = Date()
    var daysAgo: Int = -1
    var deficit: Double = 0
    var activeCalories: Double = 0
    var realActiveCalories: Double = 0
    var restingCalories: Double = 0
    var realRestingCalories: Double = 0
    var consumedCalories: Double = 0
    var runningTotalDeficit: Double = 0
    var expectedWeight: Double = 0
    var expectedWeightChangedBasedOnDeficit: Double = 0
    var realisticWeight: Double = 0
    var weight: Double = 0
    var surplus: Double {
        deficit * -1
    }
    var activeCalorieToDeficitRatio: Double {
        activeCalories / deficit
    }
    var protein: Double = 0
    var caloriesPerGramOfProtein: Double = 4
}

/// A collection of days, where passing a number indicates how many days ago the returned day will be.
typealias Days = [Int:Day]

extension Days {
    
    //TODO: Test
    func upTo(date: Date) -> Days {
        return self.filter {
            let days = $0.key - 1
            let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date())
            let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
            return startDate <= date
        }
    }
    
    enum DayProperty {
        case activeCalories
        case restingCalories
        case consumedCalories
        case weight
        case realisticWeight
        case expectedWeight
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
                }
            }
            .reduce(0, { x, y in x + y })
    }
}
