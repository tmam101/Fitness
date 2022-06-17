//
//  Day.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 10/19/21.
//

import Foundation

struct Day: Codable {
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
}

/// A collection of days, where passing a number indicates how many days ago the returned day will be.
typealias Days = [Int:Day]
