//
//  DecimalExtension.swift
//  Fitness
//
//  Created by Thomas on 6/20/24.
//

import Foundation

extension Decimal {
    var plusIfNecessary: String {
        guard self != 0 else { return "" }
        return self > 0 ? "+" : ""
    }
    
    var toInt: Int {
        Int(Double(self))
    }
    
    var stringWithPlusIfNecessary: String {
        "\(plusIfNecessary)\(toInt)"
    }
}
