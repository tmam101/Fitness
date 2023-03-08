//
//  DoubleExtension.swift
//  Fitness
//
//  Created by Thomas Goss on 6/22/21.
//

import Foundation
import SwiftUI

extension Double {
    func toRadians() -> Double {
        return self * Double.pi / 180
    }
    
    func toCGFloat() -> CGFloat {
        return CGFloat(self)
    }
    
    func rounded(toNextSignificant goal: Double) -> Double  {
        switch self > 0 {
        case true:
            return self + (goal - self.truncatingRemainder(dividingBy: goal))
        case false:
            return self - (goal + self.truncatingRemainder(dividingBy: goal))
        }
    }
    
    func roundedString() -> String {
        return String(format: "%.2f", self)
    }
    
    func percentageToWholeNumber() -> String {
        return String(Int(self * 100))
    }
}
