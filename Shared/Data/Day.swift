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

public enum SortOrder {
    case longestAgoToMostRecent
    case mostRecentToLongestAgo
}

public class Constants {
    static let numberOfCaloriesInPound: Double = 3500
    static let maximumWeightChangePerDay = 0.2
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
            realisticWeightChangeCausedByToday = Swift.max(-Constants.maximumWeightChangePerDay, realisticWeightChangeCausedByToday)
            let totalBurned = self.allCaloriesBurned
            let caloriesAssumedToBeBurned = 0 - (realisticWeightChangeCausedByToday * Constants.numberOfCaloriesInPound)
            let caloriesLeftToBeBurned = (caloriesAssumedToBeBurned - totalBurned) > 0
            // If setting 0 calories eaten still leaves you with weight to lose, just set it to 0 calories eaten.
            newConsumedCalories = caloriesLeftToBeBurned ? 0 : totalBurned - caloriesAssumedToBeBurned
        }
        // If you gained weight or maintained,
        else {
            // Calculate how many calories you must have eaten to gain that much weight.
            realisticWeightChangeCausedByToday = Swift.min(Constants.maximumWeightChangePerDay, realisticWeightChangeCausedByToday)
            let totalBurned = self.allCaloriesBurned
            let caloriesAssumedToBeEaten = (realisticWeightChangeCausedByToday * Constants.numberOfCaloriesInPound) + totalBurned
            newConsumedCalories = Double.minimum(5000.0, abs(caloriesAssumedToBeEaten))
        }
        return newConsumedCalories
    }
    
    public enum Property {
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
    
    public func set(_ property: Property, to newValue: Double) -> Bool {
        switch property {
        case .activeCalories:
            self.activeCalories = newValue
        case .restingCalories:
            self.restingCalories = newValue
        case .consumedCalories:
            self.consumedCalories = newValue
        case .weight:
            self.weight = newValue
        case .realisticWeight:
            self.realisticWeight = newValue
        case .expectedWeight:
            self.expectedWeight = newValue
        case .netEnergy, .deficit:
            return false
        }
        return true
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
                case .subsetOfDays(_, _):
                    print("TODO")
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
        days.setInitialExpectedWeights()
        if weightsOnEveryDay {
            days.setWeightOnEveryDay()
            days.setRealisticWeights()
        }
        if missingData {
            days.adjustDaysWhereUserDidntEnterDatav3()
        }
        print(days.encodeAsString())
        return days
    }
    
    // MARK: Construction
    
    mutating func formatAccordingTo(options: [TestDayOption]?) {
        self.addRunningTotalDeficits()
        let _ = self.setInitialExpectedWeights()
        if let options {
            if !options.contains(.dontAddWeightsOnEveryDay) {
                self.setWeightOnEveryDay()
                self.setRealisticWeights()
            }
            for option in options {
                if case let .isMissingConsumedCalories(version) = option {
                    switch version {
                    case .v1:
                        self.adjustDaysWhereUserDidntEnterData()
                    case .v2:
                        self.adjustDaysWhereUserDidntEnterDatav2()
                    case .v3:
                        self.adjustDaysWhereUserDidntEnterDatav3()
                    }
                    break
                }
            }
            // TODO test
            for option in options {
                if case let .subsetOfDays(int, int2) = option {
                    self = subset(from: int, through: int2)
                }
            }
        }
    }
    
    func setInitialExpectedWeights() -> Bool {
        guard let oldestDay, let newestDay else { return false }
        oldestDay.expectedWeight = oldestDay.weight // not sure about this, but fine for now
        let subset = subset(from: oldestDay, through: newestDay)
        subset.forEveryDay(.longestAgoToMostRecent) { day in
            guard let dayBefore = subset.dayBefore(day) else {
                return
            } //Good?
            day.expectedWeight = oldestDay.expectedWeight - (dayBefore.runningTotalDeficit / Constants.numberOfCaloriesInPound)
        }
        return true
    }
    
    // TODO: This is mostly a test function, because it's aready done in CalorieManager. But maybe we should just have it be done here.
    mutating func addRunningTotalDeficits() {
        var runningTotalDeficit: Double = 0
        forEveryDay { day in
            runningTotalDeficit = runningTotalDeficit + day.deficit
            day.runningTotalDeficit = runningTotalDeficit
        }
    }
    
    /**
     These weights represent a smoothed out version of the real weights, so large weight changes based on water or something are less impactful.
     
     Start on first day
     
     Loop through each subsequent day, finding expected weight change
     
     Find next weight's actual loss
     
     Set the realistic weight loss to: 0.2 pounds, unless the expected weight loss is greater, or the actual loss is smaller
     */
    // TODO: This doesn't follow expected weight change if it is greater
    func setRealisticWeights() {
        guard self.everyDayHas(.weight) else {
            return
        }
        
        // Start from the oldest day and work forwards
        forEveryDay { currentDay in
            if let previousDay = dayBefore(currentDay) {
                // Calculate the realistic weight difference
                let realWeightDifference = (currentDay.weight - previousDay.realisticWeight)
                
                // Adjust the weight difference based on the maximum allowed change per day
                let adjustedWeightDifference = Swift.max(Swift.min(realWeightDifference, Constants.maximumWeightChangePerDay), -Constants.maximumWeightChangePerDay)
                
                // Set the realistic weight for the current day
                currentDay.realisticWeight = previousDay.realisticWeight + adjustedWeightDifference
            } else {
                // The oldest day uses its own weight as the realistic weight
                currentDay.realisticWeight = currentDay.weight
            }
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
            subset(from: thisDay.daysAgo - 1, through: nextDayWithWeight.daysAgo + 1).forEveryDay { day in
                guard let previousDay = days.dayBefore(day) else {
                    return
                }
                day.weight = previousDay.weight + weightAdjustmentEachDay
            }
        }
        // Make the most recent weights, if they are not recorded, equal to the last recorded weight
        setTrailingDaysPropertyToLastKnown(.weight, .longestAgoToMostRecent)
        
        // Try to make the first days, if you haven't weighted yourself yet, equal to the first weight you eventually record
        setTrailingDaysPropertyToLastKnown(.weight, .mostRecentToLongestAgo)
    }
    
    func setTrailingDaysPropertyToLastKnown(_ property: Day.Property, _ sortOrder: SortOrder) {
        var mostRecentProperty: Double? = nil
        forEveryDay(sortOrder) { day in
            if day[keyPath: property.keyPath] == 0 {
                if let mostRecentProperty {
                    let _ = day.set(property, to: mostRecentProperty)
                }
            } else {
                mostRecentProperty = day[keyPath: property.keyPath]
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
        forEveryDay { day in
            let didUserEnterData = day.consumedCalories != 0
            
            // If we are on the first day, check if user entered data
            guard let yesterday = days.dayBefore(day) else {
                guard let tomorrow = days.dayAfter(day) else {
                    print("Fail") // TODO: Handle this edge case properly
                    return
                }
                if !didUserEnterData {
                    let realisticWeightChangeCausedByToday = tomorrow.realisticWeight - day.expectedWeight
                    day.consumedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: realisticWeightChangeCausedByToday)
                    day.wasModifiedBecauseTheUserDidntEnterData = true
                }
                return
            }
            
            // If we are on today, set expected weight based on yesterday's expected weight tomorrow
            guard let tomorrow = days.dayAfter(day) else {
                day.expectedWeight = yesterday.expectedWeightTomorrow
                return
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
    
    func sorted(_ sortOrder: SortOrder) -> [Day] {
        self.array().sorted(sortOrder)
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
        self.array().sorted(.mostRecentToLongestAgo).last
    }
    
    var newestDay: Day? {
        self.array().sorted(.mostRecentToLongestAgo).first
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
    
    func subset(from: Int, through: Int, inclusiveOfOldestDay: Bool = true, inclusiveOfNewestDay: Bool = true) -> Days {
        var subset = Days()
        // Sort to find the
        var min = Swift.min(from, through)
        var max = Swift.max(from, through)
        min = inclusiveOfNewestDay ? min : min + 1
        max = inclusiveOfOldestDay ? max : max - 1
        if min > max {
            return subset
        }
        for i in min...max {
            subset[i] = self[i]
        }
        return subset
    }
    
    func subset(from: Day, through: Day, inclusiveOfOldestDay: Bool = true, inclusiveOfNewestDay: Bool = true) -> Days {
        return subset(from: from.daysAgo, through: through.daysAgo, inclusiveOfOldestDay: inclusiveOfOldestDay, inclusiveOfNewestDay: inclusiveOfNewestDay)
    }
    
    func subset(from: Date?, through: Date?, inclusiveOfOldestDay: Bool = true, inclusiveOfNewestDay: Bool = true) -> Days {
        guard let from = from?.daysAgo(), let through = through?.daysAgo() else { return Days() }
        return subset(from: from, through: through, inclusiveOfOldestDay: inclusiveOfOldestDay, inclusiveOfNewestDay: inclusiveOfNewestDay)
    }
    
    /// Iterate over every day, oldest to newest, with the option to go from newest to oldest. Complete the action for every day
    func forEveryDay(_ sortOrder: SortOrder = .longestAgoToMostRecent, _ completion: (Day) -> Void) {
        var day: Day? = switch sortOrder {
        case .longestAgoToMostRecent:
            oldestDay
        case .mostRecentToLongestAgo:
            newestDay
        }
        while let currentDay = day {
            completion(currentDay)
            day = switch sortOrder {
            case .longestAgoToMostRecent:
                dayAfter(currentDay)
            case .mostRecentToLongestAgo:
                dayBefore(currentDay)
            }
        }
    }
    
    func filteredBy(_ timeFrame: TimeFrame) -> Days {
        return self.subset(from: -1, through: timeFrame.days)
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
