//
//  FloatingPointExtensions.swift
//  Fitness
//
//  Created by Thomas Goss on 3/19/21.
//

import Foundation
extension FloatingPoint {
    func corrected() -> Self {
        return (self.isNaN || self.isInfinite) ? 0 : self
    }
}
