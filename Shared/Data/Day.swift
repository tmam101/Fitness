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
    var wasModifiedBecauseTheUserDidntEnterData = false
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
    
    var dayOfWeek: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // "EEEE" is the date format for the full name of the day
        let dayOfWeekString = dateFormatter.string(from: date)
        
        return dayOfWeekString
    }
    
}
// MARK: DAYS
/// A collection of days, where passing a number indicates how many days ago the returned day will be.
typealias Days = [Int:Day]

extension Days {
    
    enum TestFiles: String {
        case missingDataIssue = "missingDataIssue"
    }
    // TODO Function for adding a new day that pushes everything forward a day
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
        var weightsOnEveryDay = false
        var weightGoingSteadilyDown = false
        var dayCount = activeCalories.count - 1 /*activeCalories.count - 1*/
        if let options {
            for option in options {
                switch option {
                case .isMissingConsumedCalories:
                    missingData = true
                case .weightGoingSteadilyDown:
                    weightGoingSteadilyDown = true
                case .shouldAddWeightsOnEveryDay:
                    weightsOnEveryDay = true
                case .testCase(let file):
                    switch file {
                    case .missingDataIssue:
                        var days: Days = Days.decode(path: .missingDataIssue) ?? [:] // TODO
                        days.formatAccordingTo(options: options)
                        return days
                    }
                case .dayCount(let count):
                    dayCount = count
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
        days.setRealisticWeights()
        if weightsOnEveryDay {
            days.setWeightOnEveryDay()
        }
        if missingData {
            days.adjustDaysWhereUserDidntEnterDatav2()
        }
        print(days.encodeAsString())
        return days
    }
    
    mutating func formatAccordingTo(options: [TestDayOption]?) {
        self.addRunningTotalDeficits()
        self.setRealisticWeights()
        if let options {
            for option in options {
                switch option {
                case .isMissingConsumedCalories(let version):
                    switch version {
                    case .v1:
                        self.adjustDaysWhereUserDidntEnterData()
                    case .v2:
                        self.adjustDaysWhereUserDidntEnterDatav2()
                    }
                case .shouldAddWeightsOnEveryDay:
                    self.setWeightOnEveryDay()
                case .testCase(_), .dayCount(_), .weightGoingSteadilyDown:
                    return
                }
            }
        }
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
    
    mutating func setWeightOnEveryDay() {
        let weights = self.array().filter { $0.weight != 0 }.sorted(by: {x, y in x.daysAgo > y.daysAgo })
        guard weights.count > 0 else { return } //todo test
        for i in 0..<weights.count-1 {
            let thisDay = weights[i]
            let nextDay = weights[i+1]
            let daysBetween = thisDay.daysAgo - nextDay.daysAgo
            if daysBetween == 1 {
                continue
            }
            let weightBetween = nextDay.weight - thisDay.weight
            let weightAdjustmentEachDay = weightBetween / Double(daysBetween)
            for j in stride(from: thisDay.daysAgo - 1, to: nextDay.daysAgo, by: -1) {
                guard let _ = self[j], let _ = self[j+1] else {
                    // if we are at the longest ago day, and its 0, we set it to the next weight that exists
                    continue
                }
                self[j]!.weight = self[j+1]!.weight + weightAdjustmentEachDay
            }
        }
        // Make the most recent weights, if they are not recorded, equal to the last recorded weight
        var mostRecentWeight: Double? = nil
        for i in stride(from: self.count - 1, through: 0, by: -1) {
            if self[i]?.weight == 0 {
                if let mostRecentWeight {
                    self[i]?.weight = mostRecentWeight
                }
            } else {
                mostRecentWeight = self[i]?.weight
            }
        }
    }
    
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
                    let caloriesAssumedToBeBurned = 0 - (todaysWeightMinusYesterdaysExpectedWeight * 3500)
                    let caloriesLeftToBeBurned = (caloriesAssumedToBeBurned - totalBurned) > 0
                    if caloriesLeftToBeBurned {
                        newConsumedCalories = 0
                    } else {
                        newConsumedCalories = totalBurned - caloriesAssumedToBeBurned // maybe
                    }
                } else {
                    let totalBurned = day.activeCalories + day.restingCalories
                    let caloriesAssumedToBeEaten = (todaysWeightMinusYesterdaysExpectedWeight * 3500) + totalBurned
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
                    let caloriesAssumedToBeBurned = 0 - (weightChangecausedByToday * 3500)
                    let caloriesLeftToBeBurned = (caloriesAssumedToBeBurned - totalBurned) > 0
                    if caloriesLeftToBeBurned {
                        newConsumedCalories = 0
                    } else {
                        newConsumedCalories = totalBurned - caloriesAssumedToBeBurned // maybe
                    }
                } else {
                    let totalBurned = day.activeCalories + day.restingCalories
                    let caloriesAssumedToBeEaten = (weightChangecausedByToday * 3500) + totalBurned
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
    
    //MARK: REALISTIC WEIGHTS
    /**
     Return a dictionary of realistic weights, with index 0 being today and x being x days ago. These weights represent a smoothed out version of the real weights, so large weight changes based on water or something are less impactful.
     
     Start on first weight
     
     Loop through each subsequent day, finding expected weight loss
     
     Find next weight's actual loss
     
     Set the realistic weight loss to: 0.2 pounds, unless the expected weight loss is greater, or the actual loss is smaller
     */
    //    mutating func createRealisticWeights() {
    //        guard let firstWeight = self[self.count-1]?.weight else { return }
    //        let maximumWeightChangePerDay = 0.2
    //        var realisticWeights: [Int: Double] = [:]
    //
    //        for i in stride(from: self.count-1, through: 0, by: -1) {
    //            let day = self[i]!
    //
    //            guard
    //                let nextWeight = self.array()
    //                    .sorted(by: { x, y in x.daysAgo > y.daysAgo })
    //                    .last(where: { Date.startOfDay($0.date) > day.date}),
    ////                    .map({x in x.weight}),
    ////                let nextWeight = weightManager.weights.last(where: { Date.startOfDay($0.date) > day.date }),
    //                day.date >= Date.startOfDay(firstWeight.date)
    //            else {
    //                return realisticWeights
    //            }
    //
    //            let onFirstDay = i == calorieManager.days.count - 1
    //            if onFirstDay {
    //                realisticWeights[i] = firstWeight.weight
    //            } else {
    //                let dayDifferenceBetweenNowAndNextWeight = Double(Date.daysBetween(date1: day.date, date2: Date.startOfDay(nextWeight.date))!)
    //                let realWeightDifference = (nextWeight.weight - realisticWeights[i+1]!) / dayDifferenceBetweenNowAndNextWeight
    //                var adjustedWeightDifference = realWeightDifference
    //
    //                if adjustedWeightDifference < -maximumWeightChangePerDay  {
    //                    adjustedWeightDifference = min(-maximumWeightChangePerDay, day.expectedWeightChangedBasedOnDeficit)
    //                }
    //                if adjustedWeightDifference > maximumWeightChangePerDay {
    //                    adjustedWeightDifference = max(maximumWeightChangePerDay, day.expectedWeightChangedBasedOnDeficit)
    //                }
    //
    //                realisticWeights[i] = realisticWeights[i+1]! + adjustedWeightDifference
    //            }
    //        }
    //        return realisticWeights
    //    }
    
    func array() -> [Day] {
        Array(self.values).sorted(by: { x, y in x.daysAgo > y.daysAgo })
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

extension Days {
    //    func encodeAsString() -> String {
    //        let jsonEncoder = JSONEncoder()
    //        jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
    //        guard
    //            let jsonData = try? jsonEncoder.encode(self),
    //            let json = String(data: jsonData, encoding: String.Encoding.utf8) else {
    //            return "Failed"
    //        }
    //        print(json)
    //        return json
    //    }
    //
    //    func encode() -> Data? {
    //        let jsonEncoder = JSONEncoder()
    //        guard
    //            let jsonData = try? jsonEncoder.encode(self) else {
    //            return nil
    //        }
    //        return jsonData
    //    }
    
    //    static func decode(path: String) -> Days? { // Pass in options here? format in here?
    //        Decoder<Days>.decode(path: path)
    //    }
}
//
//#Preview("Missing data issue") {
//    FitnessPreviewProvider.missingDataIssue()
//}
