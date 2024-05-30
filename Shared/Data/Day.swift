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

public class Constants {
    static let numberOfCaloriesInPound: Double = 3500
}

public class Day: Codable, Identifiable, Plottable, Equatable, HasDate {
    public static func == (lhs: Day, rhs: Day) -> Bool {
        lhs.id == rhs.id
    }
    
    public var primitivePlottable: String = "Day"
    
    required public init?(primitivePlottable: String) {
        
    }
    
    init(id: UUID = UUID(),
         date: Date? = nil,
         daysAgo: Int? = nil,
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
        self.date = date ?? Date.subtract(days: daysAgo ?? 0, from: Date())
        if let date {
            self.daysAgo = daysAgo ?? (Date.daysBetween(date1: Date(), date2: date) ?? -1)
        } else {
            self.daysAgo = daysAgo ?? -1
        }
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
    
    public typealias PrimitivePlottable = String
    
    public var id = UUID()
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
    var wasModifiedBecauseTheUserDidntEnterData = false
    var expectedWeightTomorrow: Double {
        expectedWeight + expectedWeightChangeBasedOnDeficit
    }
    var expectedWeightChangeBasedOnDeficit: Double {
        0 - (deficit / Constants.numberOfCaloriesInPound)
    }
    var realisticWeight: Double = 0
    var weight: Double = 0
    var netEnergy: Double {
        deficit * -1
    }
    var activeCalorieToDeficitRatio: Double {
        activeCalories / deficit
    }
    var allCaloriesBurned: Double {
        activeCalories + restingCalories
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
    
    var dayOfWeek: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // "EEEE" is the date format for the full name of the day
        let dayOfWeekString = dateFormatter.string(from: date)
        
        return dayOfWeekString
    }
    
    var firstLetterOfDay: String {
        "\(dayOfWeek.prefix(1))"
    }
    
    func estimatedConsumedCaloriesToCause(realisticWeightChange: Double) -> Double {
        var realisticWeightChangeCausedByToday = realisticWeightChange
        var newConsumedCalories: Double = 0
        // If you lost weight,
        if realisticWeightChangeCausedByToday < 0 {
            // Calculate how few calories you must have eaten to lose that much weight.
            realisticWeightChangeCausedByToday = Swift.max(-0.2, realisticWeightChangeCausedByToday)
            let totalBurned = self.activeCalories + self.restingCalories
            let caloriesAssumedToBeBurned = 0 - (realisticWeightChangeCausedByToday * Constants.numberOfCaloriesInPound)
            let caloriesLeftToBeBurned = (caloriesAssumedToBeBurned - totalBurned) > 0
            // If setting 0 calories eaten still leaves you with weight to lose, just set it to 0 calories eaten.
            newConsumedCalories = caloriesLeftToBeBurned ? 0 : totalBurned - caloriesAssumedToBeBurned
        }
        // If you gained weight or maintained,
        else {
            // Calculate how many calories you must have eaten to gain that much weight.
            realisticWeightChangeCausedByToday = Swift.min(0.2, realisticWeightChangeCausedByToday)
            let totalBurned = self.activeCalories + self.restingCalories
            let caloriesAssumedToBeEaten = (realisticWeightChangeCausedByToday * Constants.numberOfCaloriesInPound) + totalBurned
            newConsumedCalories = Double.minimum(5000.0, abs(caloriesAssumedToBeEaten))
        }
        return newConsumedCalories
    }
}


// MARK: DAYS
/// A collection of days, where passing a number indicates how many days ago the returned day will be.
public typealias Days = [Int:Day]

extension Days {
    // TODO Function for adding a new day that pushes everything forward a day
    
    // MARK: Test days
    static func testDays() -> Days {
        testDays(options: nil)
    }
    
    static func testDays(options: [TestDayOption]?) -> Days {
        var days: Days = [:]
        guard
            let activeCalories: [Double] = .decode(path: .activeCalories),
            let restingCalories: [Double] = .decode(path: .restingCalories),
            let consumedCalories: [Double] = .decode(path: .consumedCalories),
            let upAndDownWeights: [Double] = .decode(path: .upAndDownWeights),
            let missingConsumedCalories: [Double] = .decode(path: .missingConsumedCalories),
            let weightsGoingSteadilyDown: [Double] = .decode(path: .weightGoingSteadilyDown)
        else {
            return days
        }
        
        var missingData = false
        var weightsOnEveryDay = true
        var weightGoingSteadilyDown = false
        var dayCount = activeCalories.count - 1
        if let options {
            for option in options {
                switch option {
                case .isMissingConsumedCalories:
                    missingData = true
                case .weightGoingSteadilyDown:
                    weightGoingSteadilyDown = true
                case .testCase(let file):
                    var days: Days = Days.decode(path: file) ?? [:] // TODO
                    days.formatAccordingTo(options: options)
                    return days
                case .dayCount(let count):
                    dayCount = count
                case .dontAddWeightsOnEveryDay:
                    weightsOnEveryDay = false
                }
            }
        }
        
        days[dayCount] = Day(date: Date.subtract(days: dayCount, from: Date()), daysAgo: dayCount, activeCalories: activeCalories[dayCount], restingCalories: restingCalories[dayCount], consumedCalories: missingData ? missingConsumedCalories[dayCount] : consumedCalories[dayCount], expectedWeight: 200, weight: 200)
        for i in (0...dayCount-1).reversed() {
            guard let previousDay = days[i+1] else { return [:] }
            let expectedWeight = previousDay.expectedWeight + previousDay.expectedWeightChangeBasedOnDeficit
            let realWeight = expectedWeight + Double.random(in: -1.0...1.0)
            let dayHasWeight = Bool.random()
            var weight = dayHasWeight ? realWeight : 0
            weight = weightGoingSteadilyDown ? weightsGoingSteadilyDown[i] : weight
            days[i] = Day(date: Date.subtract(days: i, from: Date()), daysAgo: i, activeCalories: activeCalories[i], restingCalories: restingCalories[i], consumedCalories: missingData ? missingConsumedCalories[i] : consumedCalories[i], expectedWeight: expectedWeight, weight: weight) // TODO Not sure exactly how expectedWeight and expectedWeightChangeBasedOnDeficit should relate to each other.
        }
        //        if let today = days[0] {
        //            days[-1] = Day(date: Date.subtract(days: -1, from: today.date), daysAgo: -1, expectedWeight: today.expectedWeightTomorrow)
        //        }
        days.addRunningTotalDeficits()
        if weightsOnEveryDay {
            days.setWeightOnEveryDay()
            days.setRealisticWeights()
        }
        if missingData {
            days.adjustDaysWhereUserDidntEnterDatav2()
        }
        print(days.encodeAsString())
        return days
    }
    
    // MARK: Construction
    
    mutating func formatAccordingTo(options: [TestDayOption]?) {
        self.addRunningTotalDeficits()
        if let options {
            if !options.contains(.dontAddWeightsOnEveryDay) {
                self.setWeightOnEveryDay()
                self.setRealisticWeights()
            }
            for option in options {
                switch option {
                case .isMissingConsumedCalories(let version):
                    switch version {
                    case .v1:
                        self.adjustDaysWhereUserDidntEnterData()
                    case .v2:
                        self.adjustDaysWhereUserDidntEnterDatav2()
                    case .v3:
                        self.adjustDaysWhereUserDidntEnterDatav3()
                    }
                case .testCase(_), .dayCount(_), .weightGoingSteadilyDown, .dontAddWeightsOnEveryDay:
                    continue
                }
            }
        }
    }
    
    // TODO Test?
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
    // TODO: This doesn't follow expected weight change if it is greater
    func setRealisticWeights() {
        guard self.everyDayHas(.weight) else {
            return
        }
        let maximumWeightChangePerDay = 0.2
        
        // Start from the oldest day and work forwards
        var day: Day? = oldestDay
        while let currentDay = day {
            if let previousDay = dayBefore(currentDay) {
                // Calculate the realistic weight difference
                let realWeightDifference = (currentDay.weight - previousDay.realisticWeight)
                
                // Adjust the weight difference based on the maximum allowed change per day
                let adjustedWeightDifference = Swift.max(Swift.min(realWeightDifference, maximumWeightChangePerDay), -maximumWeightChangePerDay)
                
                // Set the realistic weight for the current day
                currentDay.realisticWeight = previousDay.realisticWeight + adjustedWeightDifference
            } else {
                // The oldest day uses its own weight as the realistic weight
                currentDay.realisticWeight = currentDay.weight
            }
            day = dayAfter(currentDay)
        }
    }
    
    func setWeightOnEveryDay() {
        let days = self
        let daysWithWeights = days.daysWith(.weight)
        guard daysWithWeights.count > 0 else { return } //todo test
        for day in daysWithWeights {
            let thisDay = day.value
            guard let nextDayWithWeight = daysWithWeights.dayAfter(day.value) else {
                continue
            }
            let daysBetween = thisDay.daysAgo - nextDayWithWeight.daysAgo
            if daysBetween == 1 {
                continue
            }
            let weightBetween = nextDayWithWeight.weight - thisDay.weight
            let weightAdjustmentEachDay = weightBetween / Double(daysBetween)
            for day in subset(from: thisDay.daysAgo - 1, through: nextDayWithWeight.daysAgo + 1)
                .array()
                .sortedLongestAgoToMostRecent() {
                guard let previousDay = days.dayBefore(day) else {
                    continue
                }
                day.weight = previousDay.weight + weightAdjustmentEachDay
            }
        }
        // Make the most recent weights, if they are not recorded, equal to the last recorded weight
        var mostRecentWeight: Double? = nil
        for day in days.array().sortedLongestAgoToMostRecent() {
            if day.weight == 0 {
                if let mostRecentWeight {
                    day.weight = mostRecentWeight
                }
            } else {
                mostRecentWeight = day.weight
            }
        }
    }
    
    func adjustDaysWhereUserDidntEnterDatav3() {
        let days = self
        
        // Ensure all days have weights
        if !days.everyDayHas(.weight) {
            days.setWeightOnEveryDay()
        }
        
        // Ensure all days have realistic weights
        if !days.everyDayHas(.realisticWeight) {
            days.setRealisticWeights()
        }
        
        // Iterate over days sorted from the oldest to the most recent
        for day in days.array().sortedLongestAgoToMostRecent() {
            let didUserEnterData = day.consumedCalories != 0
            
            // If we are on the first day, check if user entered data
            guard let yesterday = days.dayBefore(day) else {
                guard let tomorrow = days.dayAfter(day) else {
                    print("Fail") // TODO: Handle this edge case properly
                    continue
                }
                if !didUserEnterData {
                    let realisticWeightChangeCausedByToday = tomorrow.realisticWeight - day.expectedWeight
                    day.consumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: realisticWeightChangeCausedByToday)
                    day.wasModifiedBecauseTheUserDidntEnterData = true
                }
                continue
            }
            
            // If we are on today, set expected weight based on yesterday's expected weight tomorrow
            guard let tomorrow = days.dayAfter(day) else {
                day.expectedWeight = yesterday.expectedWeightTomorrow
                continue
            }
            
            // Adjust days where user didn't enter data
            if !didUserEnterData {
                let realisticWeightChangeCausedByToday = tomorrow.realisticWeight - yesterday.expectedWeightTomorrow
                day.consumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: realisticWeightChangeCausedByToday)
                day.wasModifiedBecauseTheUserDidntEnterData = true
            }
            day.expectedWeight = yesterday.expectedWeightTomorrow
        }
    }
    
    // MARK: Convenience
    
    func array() -> [Day] {
        Array(self.values).sorted(by: { x, y in x.daysAgo > y.daysAgo })
    }
    
    func everyDayHas(_ property: DayProperty) -> Bool {
        let properties = mappedToProperty(property: property)
        let propertiesThatAreZero = properties.filter { $0 == 0 }
        return propertiesThatAreZero.count == 0
    }
    
    func daysWith(_ property: DayProperty) -> Days {
        self.filter { $0.value[keyPath: property.keyPath] != 0 }
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
        
        var keyPath: KeyPath<Day, Double> {
            switch self {
            case .activeCalories:
                return \Day.activeCalories
            case .restingCalories:
                return \Day.restingCalories
            case .consumedCalories:
                return \Day.consumedCalories
            case .weight:
                return \Day.weight
            case .realisticWeight:
                return \Day.realisticWeight
            case .expectedWeight:
                return \Day.expectedWeight
            case .netEnergy:
                return \Day.netEnergy
            case .deficit:
                return \Day.deficit
            }
        }
    }
    
    func mappedToProperty(property: DayProperty) -> [Double] {
        return Array(self.values)
            .map {
                $0[keyPath: property.keyPath]
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
    
    var oldestDay: Day? {
        self.array().sortedMostRecentToLongestAgo().last
    }
    
    var newestDay: Day? {
       self.array().sortedMostRecentToLongestAgo().first
    }
    
    mutating func append(_ day: Day) -> Bool {
        if self[day.daysAgo] == nil {
            self[day.daysAgo] = day
            return true
        }
        return false
    }
    
    mutating func append(_ days: [Day]) -> Bool {
        for day in days {
            if self[day.daysAgo] != nil {
                return false
            }
        }
        for day in days {
            self[day.daysAgo] = day
        }
        return true
    }
    
    func dayAfter(_ day: Day?) -> Day? {
        guard let day else { return nil }
        let sortedKeys = self.keys.sorted(by: >)
        
        // Iterate through sorted keys to find the next smallest key
        for sortedKey in sortedKeys {
            if sortedKey < day.daysAgo {
                return self[sortedKey]
            }
        }
        
        // If no smaller key is found, return nil
        return nil
    }
    
    func dayBefore(_ day: Day?) -> Day? {
        guard let day else { return nil }
        let sortedKeys = self.keys.sorted(by: <)
        
        // Iterate through sorted keys to find the next biggest key
        for sortedKey in sortedKeys {
            if sortedKey > day.daysAgo {
                return self[sortedKey]
            }
        }
        
        // If no bigger key is found, return nil
        return nil
    }
    
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
    
    // MARK: OLD WAYS OF ADJUSTING DAYS
    
    // Need to look at tomorrow's weight, not yesterday's weight, right?
    mutating func adjustDaysWhereUserDidntEnterData() {
        if self.array().filter({ $0.weight == 0 }).count != 0 {
            self.setWeightOnEveryDay()
        }
        for i in stride(from: self.count - 1, through: 0, by: -1) {
            guard let day = self[i] else { return }
            let didUserEnterData = day.consumedCalories != 0
            guard let yesterday = self[i+1] else { continue }
            // Tomorrow
            guard self[i-1] != nil else {
                // If we're on today
                if !didUserEnterData {
                    self[i]?.expectedWeight = yesterday.expectedWeightTomorrow
                } else {
                    if let expectedWeightChangeBasedOnDeficit = self[i]?.expectedWeightChangeBasedOnDeficit {
                        self[i]?.expectedWeight = yesterday.expectedWeightTomorrow + expectedWeightChangeBasedOnDeficit
                    }
                }
                continue
            }
            if !didUserEnterData {
                let todaysWeightMinusYesterdaysExpectedWeight = day.weight - yesterday.expectedWeight
                var newConsumedCalories: Double = 0
                if todaysWeightMinusYesterdaysExpectedWeight < 0 {
                    let totalBurned = day.activeCalories + day.restingCalories
                    let caloriesAssumedToBeBurned = 0 - (todaysWeightMinusYesterdaysExpectedWeight * Constants.numberOfCaloriesInPound)
                    let caloriesLeftToBeBurned = (caloriesAssumedToBeBurned - totalBurned) > 0
                    if caloriesLeftToBeBurned {
                        newConsumedCalories = 0
                    } else {
                        newConsumedCalories = totalBurned - caloriesAssumedToBeBurned // maybe
                    }
                } else {
                    let totalBurned = day.activeCalories + day.restingCalories
                    let caloriesAssumedToBeEaten = (todaysWeightMinusYesterdaysExpectedWeight * Constants.numberOfCaloriesInPound) + totalBurned
                    newConsumedCalories = Double.minimum(5000.0, abs(caloriesAssumedToBeEaten))
                }
                self[i]?.consumedCalories = newConsumedCalories
                self[i]?.wasModifiedBecauseTheUserDidntEnterData = true
            }
            if let expectedWeightChange = self[i]?.expectedWeightChangeBasedOnDeficit {
                self[i]?.expectedWeight = yesterday.expectedWeight + expectedWeightChange
            }
        }
        print(self)
    }
    
    mutating func adjustDaysWhereUserDidntEnterDatav2() {
        if self.array().filter({ $0.weight == 0 }).count != 0 {
            self.setWeightOnEveryDay()
        }
        for i in stride(from: self.count - 1, through: 0, by: -1) {
            guard let day = self[i] else { return }
            let didUserEnterData = day.consumedCalories != 0
            guard let yesterday = self[i+1] else { continue }
            // Tomorrow
            guard let tomorrow = self[i-1] else {
                // If we're on today
                if !didUserEnterData {
                    self[i]?.expectedWeight = yesterday.expectedWeightTomorrow
                } else {
                    if let expectedWeightChangeBasedOnDeficit = self[i]?.expectedWeightChangeBasedOnDeficit {
                        self[i]?.expectedWeight = yesterday.expectedWeightTomorrow + expectedWeightChangeBasedOnDeficit
                    }
                }
                continue
            }
            if !didUserEnterData {
                let weightChangecausedByToday = tomorrow.weight - day.weight
                var newConsumedCalories: Double = 0
                if weightChangecausedByToday < 0 {
                    let totalBurned = day.activeCalories + day.restingCalories
                    let caloriesAssumedToBeBurned = 0 - (weightChangecausedByToday * Constants.numberOfCaloriesInPound)
                    let caloriesLeftToBeBurned = (caloriesAssumedToBeBurned - totalBurned) > 0
                    if caloriesLeftToBeBurned {
                        newConsumedCalories = 0
                    } else {
                        newConsumedCalories = totalBurned - caloriesAssumedToBeBurned // maybe
                    }
                } else {
                    let totalBurned = day.activeCalories + day.restingCalories
                    let caloriesAssumedToBeEaten = (weightChangecausedByToday * Constants.numberOfCaloriesInPound) + totalBurned
                    newConsumedCalories = Double.minimum(5000.0, abs(caloriesAssumedToBeEaten))
                }
                self[i]?.consumedCalories = newConsumedCalories
                self[i]?.wasModifiedBecauseTheUserDidntEnterData = true
            }
            // Should make sure this isnt too high or low
            if var expectedWeightChange = self[i]?.expectedWeightChangeBasedOnDeficit {
                if expectedWeightChange > 0.5 {
                    expectedWeightChange = 0.5
                } else if expectedWeightChange < -0.5 {
                    expectedWeightChange = -0.5
                }
                self[i]?.expectedWeight = yesterday.expectedWeight + expectedWeightChange
            }
        }
        print(self)
    }
}

// TODO Test
extension [Day] {
    func toDays() -> Days {
        var days = Days()
        for day in self {
            days[day.daysAgo] = day
        }
        return days
    }
}
