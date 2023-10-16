//
//  TimeExtension.swift
//  Fitness
//
//  Created by Thomas Goss on 11/21/21.
//

import Foundation

class Time {
    static func doubleToString(double: Double) -> String {
        let absDouble = abs(double)
        let floorValue = Foundation.floor(absDouble)
        let decimalPart = absDouble - floorValue
        let z = Int(round(decimalPart * 60))
        let s = z < 10 ? "0\(z)" : "\(z)"
        let sign = double < 0 ? "-" : ""
        let mileTimeString = "\(sign)\(Int(floorValue)):\(s)"
        return mileTimeString
    }
}



