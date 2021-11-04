//
//  Day.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 10/19/21.
//

import Foundation

struct Day {
    var deficit: Double = 0
    var activeCalories: Double = 0
    var consumedCalories: Double = 0

}

typealias Days = [Int: Day]
