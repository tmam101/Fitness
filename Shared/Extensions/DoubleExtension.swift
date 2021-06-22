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
}
