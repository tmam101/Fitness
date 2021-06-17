//
//  Weight.swift
//  Fitness
//
//  Created by Thomas Goss on 6/16/21.
//

import Foundation

struct Weight {
    var weight: Double
    var date: Date
    
    static func weightBetweenTwoWeights(date: Date, weight1: Weight?, weight2: Weight?) -> Float {
        guard let weight1 = weight1, let weight2 = weight2 else { return 0 }
        let days = Date.daysBetween(date1: weight1.date, date2: weight2.date)
        guard days != 0 else { return Float(weight1.weight) }
        let progress = Float(Date.daysBetween(date1: weight1.date, date2: date) ?? 1) / Float(days ?? 1)
        let weightProgress = Float(weight2.weight - weight1.weight) * progress
        let weight = Float(weight1.weight) + weightProgress
        return weight
    }
    
    static func closestTwoWeightsToDate(weights: [Weight], date: Date) -> [Weight]? {
        let theseWeights = weights.sorted(by: { $0.date < $1.date })
        for i in stride(from: 0, to: theseWeights.count, by: 1) {
            if theseWeights[i].date >= date {
                return [theseWeights[i-1], theseWeights[i]]
            }
        }
        return [theseWeights.last!]
    }
}
