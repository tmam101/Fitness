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

struct Day: Codable, Identifiable, Plottable, Equatable {
    
    var primitivePlottable: String = "Day"
    
    init?(primitivePlottable: String) {
        
    }
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         daysAgo: Int = -1,
         activeCalories: Double = 0,
         measuredActiveCalories: Double = 0,
         restingCalories: Double = 0,
         measuredRestingCalories: Double = 0,
         consumedCalories: Double = 0,
         expectedWeight: Double = 0,
         realisticWeight: Double = 0,
         weight: Double = 0,
         protein: Double = 0
    ) {
        self.id = id
        self.date = date
        self.daysAgo = daysAgo
        self.activeCalories = activeCalories
        self.measuredActiveCalories = measuredActiveCalories
        self.restingCalories = restingCalories
        self.measuredRestingCalories = measuredRestingCalories
        self.consumedCalories = consumedCalories
        self.expectedWeight = expectedWeight
        self.realisticWeight = realisticWeight
        self.weight = weight
        self.protein = protein
    }
    
    typealias PrimitivePlottable = String
    
    var id = UUID()
    var date: Date = Date()
    var daysAgo: Int = -1
    var deficit: Double {
        let active = activeCalories // * activeCalorieModifier TODO
        return restingCalories + active - consumedCalories
    }
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
    var netEnergy: Double {
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
    
    // TODO Function for adding a new day that pushes everything forward a day
    
    static var testDays: Days = {
        var days: Days = [:]
        var activeCalories: [Double] = [
            530.484, 426.822, 401.081, 563.949, 329.136, 304.808, 1045.074, 447.229, 1140.485, 287.526,
            664.498, 729.646, 141.281, 137.878, 185.565, 524.932, 387.086, 206.355, 895.737, 161.954,
            619.241, 624.191, 284.112, 272.095, 840.536, 158.428, 443.622, 264.205, 1025.872, 394.575,
            135.940, 696.240, 976.788, 383.816, 1057.616, 1056.868, 741.806, 1145.090, 514.840, 674.655,
            620.510, 1151.488, 696.858, 724.303, 953.539, 117.319, 207.876, 884.699, 672.569, 659.526,
            366.072, 672.032, 536.885, 1075.278, 705.510, 362.428, 1157.047, 376.990, 808.443, 1141.884,
            1047.608, 927.059, 1001.858, 364.928, 694.303, 241.747, 852.663, 564.521, 585.509, 970.332
        ]

        var restingCalories: [Double] = [
            2076.454, 2042.446, 2287.673, 2278.498, 2064.136, 2185.697, 2255.600, 2064.478, 2042.546, 2260.872,
            2225.101, 2077.174, 2081.573, 2014.575, 2253.578, 2125.535, 2238.620, 2123.777, 2027.833, 2075.052,
            2122.309, 2210.026, 2248.741, 2248.441, 2267.896, 2167.579, 2196.028, 2296.148, 2187.730, 2266.040,
            2197.855, 2284.924, 2171.021, 2108.903, 2283.985, 2010.677, 2256.032, 2193.350, 2159.414, 2290.834,
            2242.151, 2097.752, 2233.537, 2061.468, 2020.333, 2141.652, 2029.953, 2249.580, 2207.639, 2058.964,
            2149.820, 2172.519, 2156.872, 2278.420, 2298.363, 2181.238, 2224.319, 2047.811, 2173.178, 2069.339,
            2021.752, 2110.388, 2000.413, 2077.071, 2065.038, 2006.245, 2189.875, 2002.384, 2217.719, 2081.205
        ]

        var consumedCalories: [Double] = [
            2491.550, 2981.141, 3251.261, 1649.266, 3317.525, 2537.793, 2574.484, 1227.777, 2330.589, 1321.549,
            3132.249, 3471.490, 1519.824, 2076.862, 2215.301, 2609.347, 2166.949, 1082.332, 1724.588, 1945.672,
            1427.247, 1381.015, 2816.176, 1825.608, 1461.852, 1929.458, 1751.465, 3041.235, 3014.910, 2873.213,
            2910.372, 3072.810, 2405.098, 1719.862, 1245.969, 2901.889, 3357.390, 3147.907, 3123.125, 2441.369,
            1885.750, 2087.456, 3344.863, 1501.685, 1602.111, 1317.179, 3303.113, 2179.775, 2354.898, 2076.150,
            1421.452, 1353.783, 1045.187, 1021.009, 1692.573, 2551.751, 1461.937, 2777.730, 3489.914, 3388.308,
            2419.659, 2304.889, 1025.358, 1448.402, 3365.539, 3190.687, 1800.286, 2217.806, 2354.423, 1334.216
        ] 

        
        let count = activeCalories.count - 1
        days[count] = Day(date: Date.subtract(days: count, from: Date()), daysAgo: count, activeCalories: activeCalories[count], restingCalories: restingCalories[count], consumedCalories: consumedCalories[count], expectedWeight: 200, weight: 200)
        for i in (0...count-1).reversed() {
            guard let previousDay = days[i+1] else { return [:] }
            let expectedWeight = previousDay.expectedWeight + previousDay.expectedWeightChangeBasedOnDeficit
            let realWeight = expectedWeight + Double.random(in: -1.0...1.0)
            days[i] = Day(date: Date.subtract(days: i, from: Date()), daysAgo: i, activeCalories: activeCalories[i], restingCalories: restingCalories[i], consumedCalories: consumedCalories[i], expectedWeight: expectedWeight, weight: realWeight) // TODO Not sure exactly how expectedWeight and expectedWeightChangeBasedOnDeficit should relate to each other.
        }
        days.addRunningTotalDeficits()
        days.setRealisticWeights()
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
    
    func subset(from: Int, through: Int) -> Days {
        var extractedDays = Days()
        let min = Swift.min(from, through)
        let max = Swift.max(from, through)
        for i in min...max {
            extractedDays[i] = self[i]
        }
        return extractedDays
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
    
    /**
     These weights represent a smoothed out version of the real weights, so large weight changes based on water or something are less impactful.
     
     Start on first weight
     
     Loop through each subsequent day, finding expected weight loss
     
     Find next weight's actual loss
     
     Set the realistic weight loss to: 0.2 pounds, unless the expected weight loss is greater, or the actual loss is smaller
     */
    mutating func setRealisticWeights() {
        let maximumWeightChangePerDay = 0.2
        
        // Start from the oldest day and work forwards
        for i in stride(from: self.count - 1, through: 0, by: -1) {
            guard let currentDay = self[i] else { continue }
            
            // Oldest day uses its own weight as the realistic weight
            if i == self.count - 1 {
                self[i]?.realisticWeight = currentDay.weight
                continue
            }
            
            guard let previousDay = self[i + 1] else { continue }
            
            // Calculate the realistic weight difference
            let realWeightDifference = (currentDay.weight - previousDay.weight)
            var adjustedWeightDifference = realWeightDifference
            
            // Adjust the weight difference based on the maximum allowed change per day
            if adjustedWeightDifference < -maximumWeightChangePerDay  {
                adjustedWeightDifference = Swift.min(-maximumWeightChangePerDay, previousDay.expectedWeightChangeBasedOnDeficit)
            } else if adjustedWeightDifference > maximumWeightChangePerDay {
                adjustedWeightDifference = Swift.max(maximumWeightChangePerDay, previousDay.expectedWeightChangeBasedOnDeficit)
            }
            
            // Set the realistic weight for the current day
            self[i]?.realisticWeight = previousDay.weight + adjustedWeightDifference
        }
    }
    
    func array() -> [Day] {
        Array(self.values)
    }
    
    enum DayProperty {
        case activeCalories
        case restingCalories
        case consumedCalories
        case weight
        case realisticWeight
        case expectedWeight
        case netEnergy
        case deficit
    }
    
    func mappedToProperty(property: DayProperty) -> [Double] {
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
                case .netEnergy:
                    return $0.netEnergy
                case .deficit:
                    return $0.deficit
                }
            }
    }
    
    func sum(property: DayProperty) -> Double {
        return self.mappedToProperty(property: property).sum
    }
    
    func average(property: DayProperty) -> Double? {
        return self.mappedToProperty(property: property).average
    }
    
    func averageOfPrevious(property: DayProperty, days: Int, endingOnDay day: Int) -> Double? {
        let extracted = self.subset(from: day, through: day + days - 1)
        return extracted.average(property: property)
    }
    
    func averageDeficitOfPrevious(days: Int, endingOnDay day: Int) -> Double? {
        averageOfPrevious(property: .deficit, days: days, endingOnDay: day)
        // TODO This doesn't use runningTotalDeficit. Problem?
    }
}
