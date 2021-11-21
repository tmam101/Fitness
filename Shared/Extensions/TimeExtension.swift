//
//  TimeExtension.swift
//  Fitness
//
//  Created by Thomas Goss on 11/21/21.
//

import Foundation

class Time {
    static func doubleToString(double: Double) -> String {
        let floor = floor(double)
        let x = floor - double
        let y = x * -1
        let z = Int(y * 60)
        let s = z < 10 ? "0\(z)" : "\(z)"
        let isInt = floor == double
        let mileTimeString = isInt ? "\(Int(floor))" : "\(Int(floor)):\(s)"
        return mileTimeString
    }
}
