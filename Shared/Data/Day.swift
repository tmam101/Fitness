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
    static let numberOfCaloriesInPound: Decimal = 3500
    static let maximumWeightChangePerDay: Decimal = 0.2
}

public class Day: Codable, Identifiable, Equatable, HasDate {
    public static func == (lhs: Day, rhs: Day) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(),
         date: Date? = nil,
         daysAgo: Int? = nil,
         activeCalories: Decimal = 0,
         measuredActiveCalories: Decimal = 0,
         restingCalories: Decimal = 0,
         measuredRestingCalories: Decimal = 0,
         consumedCalories: Decimal = 0,
         expectedWeight: Decimal = 0,
         realisticWeight: Decimal = 0,
         weight: Decimal = 0,
         protein: Decimal = 0
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
    
    func copy() -> Day {
        return Day(id: UUID(),
                   date: self.date,
                   daysAgo: self.daysAgo,
                   activeCalories: self.activeCalories,
                   measuredActiveCalories: self.measuredActiveCalories,
                   restingCalories: self.restingCalories,
                   measuredRestingCalories: self.measuredRestingCalories,
                   consumedCalories: self.consumedCalories,
                   expectedWeight: self.expectedWeight,
                   realisticWeight: self.realisticWeight,
                   weight: self.weight,
                   protein: self.protein
                   )
    }
    
    public typealias PrimitivePlottable = String
    
    public var id = UUID()
    var date: Date = Date()
    var daysAgo: Int = -1
    var deficit: Decimal {
        let active = activeCalories // * activeCalorieModifier TODO
        return restingCalories + active - consumedCalories
    }
    var activeCalories: Decimal = 0
    var measuredActiveCalories: Decimal = 0
    var restingCalories: Decimal = 0
    var measuredRestingCalories: Decimal = 0
    var consumedCalories: Decimal = 0
    var runningTotalDeficit: Decimal = 0
    var expectedWeight: Decimal = 0
    var wasModifiedBecauseTheUserDidntEnterData = false
    var expectedWeightTomorrow: Decimal {
        expectedWeight + expectedWeightChangeBasedOnDeficit
    }
    var expectedWeightChangeBasedOnDeficit: Decimal {
        0 - (deficit / Constants.numberOfCaloriesInPound)
    }
    var realisticWeight: Decimal = 0
    var weight: Decimal = 0
    var netEnergy: Decimal {
        deficit * -1
    }
    var activeCalorieToDeficitRatio: Decimal {
        activeCalories / deficit
    }
    var allCaloriesBurned: Decimal {
        activeCalories + restingCalories
    }
    var protein: Decimal = 0
    var proteinPercentage: Decimal {
        let p = (protein * caloriesPerGramOfProtein) / consumedCalories
        return p.isNaN ? 0 : p
    }
    var proteinGoalPercentage: Decimal {
        proteinPercentage / 0.3 // TODO Make settings
    }
    var caloriesPerGramOfProtein: Decimal = 4
    var deficitPercentage: Decimal {
        deficit / (Settings.get(.netEnergyGoal) ?? 1000)
    }
    
    var activeCaloriePercentage: Decimal {
        activeCalories / 900 // TODO Make settings
    }
    var averagePercentage: Decimal {
        (deficitPercentage + proteinGoalPercentage + activeCaloriePercentage) / 3
    }
    var weightChangePercentage: Decimal {
        expectedWeightChangeBasedOnDeficit / (-2/7) // TODO Make settings
    }
    
    var weightWasEstimated = false
    
    var dayOfWeek: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // "EEEE" is the date format for the full name of the day
        let dayOfWeekString = dateFormatter.string(from: date)
        
        return dayOfWeekString
    }
    
    var firstLetterOfDay: String {
        "\(dayOfWeek.prefix(1))"
    }
    
    func estimatedConsumedCaloriesToCause(realisticWeightChange: Decimal) -> Decimal {
        var realisticWeightChangeCausedByToday = realisticWeightChange
        var newConsumedCalories: Decimal = 0
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
            newConsumedCalories = Swift.min(5000.0, abs(caloriesAssumedToBeEaten))
        }
        return newConsumedCalories
    }
    
    public enum Property: String {
        case activeCalories
        case restingCalories
        case consumedCalories
        case weight
        case realisticWeight
        case expectedWeight = "expected weight"
        case netEnergy
        case deficit
        
        var keyPath: KeyPath<Day, Decimal> {
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
        
        var color: Color? {
            switch self {
            case .expectedWeight:
                return .yellow
            case .weight:
                return .green
            case .activeCalories, .restingCalories, .consumedCalories, .realisticWeight, .netEnergy, .deficit:
                return nil
            }
        }
    }
    
    public func set(_ property: Property, to newValue: Decimal) -> Bool {
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
        return testDays(options: nil)
    }
    
    static func testDays(options: AppEnvironmentConfig?) -> Days {
        var days: Days = [:]
        guard
            let activeCalories: [Decimal] = .decode(path: .activeCalories),
            let restingCalories: [Decimal] = .decode(path: .restingCalories),
            let consumedCalories: [Decimal] = .decode(path: .consumedCalories),
            let _: [Decimal] = .decode(path: .upAndDownWeights),
            let missingConsumedCalories: [Decimal] = .decode(path: .missingConsumedCalories),
            let weightsGoingSteadilyDown: [Decimal] = .decode(path: .weightGoingSteadilyDown)
        else {
            return days
        }
        
        var missingData = false
        var weightsOnEveryDay = true
        var weightGoingSteadilyDown = false
        var dayCount = activeCalories.count - 1
        if let options {
            if options.isMissingConsumedCalories {
                missingData = true
            }
            if let w = options.weightGoingSteadilyDown {
                weightGoingSteadilyDown = w
            }
            if let file = options.testCase {
                var days: Days = Days.decode(path: file) ?? [:] // TODO
                days.array().forEach { day in
                    day.date = Date().subtracting(days: day.daysAgo)
                }
                days.formatAccordingTo(options: options)
                return days
            }
            if let count = options.dayCount {
                dayCount = count
            }
            if options.dontAddWeightsOnEveryDay {
                weightsOnEveryDay = false
            }
        }
        
        days[dayCount] = Day(date: Date.subtract(days: dayCount, from: Date()), daysAgo: dayCount, activeCalories: activeCalories[dayCount], restingCalories: restingCalories[dayCount], consumedCalories: missingData ? missingConsumedCalories[dayCount] : consumedCalories[dayCount], expectedWeight: 200, weight: 200)
        for i in (0...dayCount-1).reversed() {
            guard let previousDay = days[i+1] else { return [:] }
            let expectedWeight = previousDay.expectedWeight + previousDay.expectedWeightChangeBasedOnDeficit
            let realWeight = expectedWeight + Decimal(Double.random(in: -1.0...1.0))
            let dayHasWeight = Bool.random()
            var weight = dayHasWeight ? realWeight : 0
            weight = weightGoingSteadilyDown ? weightsGoingSteadilyDown[i] : weight
            days[i] = Day(date: Date.subtract(days: i, from: Date()), daysAgo: i, activeCalories: activeCalories[i], restingCalories: restingCalories[i], consumedCalories: missingData ? missingConsumedCalories[i] : consumedCalories[i], expectedWeight: expectedWeight, weight: weight) // TODO Not sure exactly how expectedWeight and expectedWeightChangeBasedOnDeficit should relate to each other.
        }
        //        if let today = days[0] {
        //            days[-1] = Day(date: Date.subtract(days: -1, from: today.date), daysAgo: -1, expectedWeight: today.expectedWeightTomorrow)
        //        }
        days.addRunningTotalDeficits()
        let _ = days.setInitialExpectedWeights()
        if weightsOnEveryDay {
            days.setWeightOnEveryDay()
            days.setRealisticWeights()
        }
        if missingData {
            days.adjustDaysWhereUserDidntEnterDatav3()
        }
        return days
    }
    
    // MARK: Construction
    
    mutating func formatAccordingTo(options: AppEnvironmentConfig?) {
        self.addRunningTotalDeficits()
        let _ = self.setInitialExpectedWeights()
        if let options {
            if !options.dontAddWeightsOnEveryDay {
                self.setWeightOnEveryDay()
                self.setRealisticWeights()
                if options.isMissingConsumedCalories {
                    self.adjustDaysWhereUserDidntEnterDatav3()
                }
            }
            // TODO test
            if let subsetOfDays = options.subsetOfDays {
                self = subset(from: subsetOfDays.0, through: subsetOfDays.1)
            }
        }
    }
    
    func setInitialExpectedWeights() -> Bool {
        guard let oldestDay, let newestDay else { return false }
        oldestDay.expectedWeight = oldestDay.weight // not sure about this, but fine for now
        // fallback to settings
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
        var runningTotalDeficit: Decimal = 0
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
            let weightAdjustmentEachDay = weightBetween / Decimal(daysBetween)
            subset(from: thisDay.daysAgo - 1, through: nextDayWithWeight.daysAgo + 1).forEveryDay { day in
                guard let previousDay = days.dayBefore(day) else {
                    return
                }
                day.weight = previousDay.weight + weightAdjustmentEachDay
                day.weightWasEstimated = true
            }
        }
        // Make the most recent weights, if they are not recorded, equal to the last recorded weight
        setTrailingDaysPropertyToLastKnown(.weight, .longestAgoToMostRecent)
        
        // Try to make the first days, if you haven't weighted yourself yet, equal to the first weight you eventually record
        setTrailingDaysPropertyToLastKnown(.weight, .mostRecentToLongestAgo)
    }
    
    func setTrailingDaysPropertyToLastKnown(_ property: Day.Property, _ sortOrder: SortOrder) {
        var mostRecentProperty: Decimal? = nil
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
    
    @discardableResult
    func adjustDaysWhereUserDidntEnterDatav3() -> Bool {
            // Ensure all days have weight and realistic weight data
            guard self.everyDayHas(.weight) else {
                print("Cannot adjust missing data: Not all days have weight data.")
                return false
            }
            
            guard self.everyDayHas(.realisticWeight) else {
                print("Cannot adjust missing data: Not all days have realistic weight data.")
                return false
            }
            
            // Iterate over each day from oldest to newest
            self.forEveryDay(.longestAgoToMostRecent) { day in
                let hasUserData = day.consumedCalories != 0
                
                if hasUserData {
                    // User entered data; no adjustment needed
                    // Update expected weight based on yesterday's data
                    if let yesterday = self.dayBefore(day) {
                        day.expectedWeight = yesterday.expectedWeightTomorrow
                    }
                    return
                }
                
                // User did not enter data; need to estimate consumedCalories
                if let yesterday = self.dayBefore(day) {
                    if let tomorrow = self.dayAfter(day) {
                        // Estimate based on the difference between tomorrow's realistic weight and yesterday's expected weight
                        let realisticWeightChange = tomorrow.realisticWeight - yesterday.expectedWeightTomorrow
                        let estimatedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: realisticWeightChange)
                        day.consumedCalories = estimatedCalories
                        day.wasModifiedBecauseTheUserDidntEnterData = true
                    } else {
                        // No tomorrow data; cannot estimate accurately
                        print("Cannot estimate consumed calories for day \(day.daysAgo): Missing tomorrow's weight data.")
                        // Optionally, set consumedCalories to a default value or skip
                    }
                    // Update expected weight
                    day.expectedWeight = yesterday.expectedWeightTomorrow
                } else {
                    // No yesterday data; this is the first day
                    if let tomorrow = self.dayAfter(day) {
                        let realisticWeightChange = tomorrow.realisticWeight - day.expectedWeight
                        let estimatedCalories = day.estimatedConsumedCaloriesToCause(realisticWeightChange: realisticWeightChange)
                        day.consumedCalories = estimatedCalories
                        day.wasModifiedBecauseTheUserDidntEnterData = true
                    } else {
                        // Only one day exists; cannot estimate
                        print("Cannot estimate consumed calories for the first day: Missing surrounding weight data.")
                        // Optionally, set consumedCalories to a default value or skip
                    }
                    // Update expected weight
                    // Since no yesterday, expectedWeight remains as is or based on other logic
                }
            }
            
            return true
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
        
        var keyPath: KeyPath<Day, Decimal> {
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
    
    func mappedToProperty(property: DayProperty) -> [Decimal] {
        return Array(self.values)
            .map {
                $0[keyPath: property.keyPath]
            }
    }
    
    func sum(property: DayProperty) -> Decimal {
        return self.mappedToProperty(property: property).sum
    }
    
    func average(property: DayProperty) -> Decimal? {
        return self.mappedToProperty(property: property).average
    }
    
    func averageOfPrevious(property: DayProperty, days: Int, endingOnDay day: Int) -> Decimal? {
        let extracted = self.subset(from: day, through: day + days - 1)
        return extracted.average(property: property)
    }
    
    func averageDeficitOfPrevious(days: Int, endingOnDay day: Int) -> Decimal? {
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
    
    func dropping(_ day: Day) -> Days {
        dropping(day.daysAgo)
    }
    
    func dropping(_ day: Int) -> Days {
        var copy = self.copy()
        copy[day] = nil
        return copy
    }
    
    func copy() -> Days {
        var days = Days()
        forEveryDay { day in
            days[day.daysAgo] = day.copy()
        }
        return days
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
    
    // TODO should this copy the days? Right now editing a day in the subset edits a day in the original.
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
    
    /// Iterate over every day, oldest to newest, with the option to go from newest to oldest. Complete the action for every day
    func forEveryDay(_ sortOrder: SortOrder = .longestAgoToMostRecent, _ completion: @escaping (Day) async -> Void) async {
        var day: Day? = switch sortOrder {
        case .longestAgoToMostRecent:
            oldestDay
        case .mostRecentToLongestAgo:
            newestDay
        }
        while let currentDay = day {
            await completion(currentDay)
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
    
//    func filter(_ isIncluded: (Dictionary<Key, Value>.Element) throws -> Bool) rethrows -> [Key : Value]
//    {
//        self.array().filter(isIncluded).toDays()
//    }
    
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

protocol HasDate {
    var date: Date { get }
}

extension Array where Element: HasDate {
    func sorted(_ sortOrder: SortOrder) -> [Element] {
        switch sortOrder {
        case .longestAgoToMostRecent:
            self.sorted { $0.date < $1.date }
        case .mostRecentToLongestAgo:
            self.sorted { $0.date > $1.date }
        }
        
    }
}
