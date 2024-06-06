//
//  Run.swift
//  Fitness
//
//  Created by Thomas Goss on 11/7/21.
//

import Foundation

struct Run: Codable {
    var date: Date
    var totalDistance: Decimal
    var totalTime: Decimal
    var averageMileTime: Decimal
    var indoor: Bool = false
    var caloriesBurned: Decimal
    var weightAtTime: Decimal
}
