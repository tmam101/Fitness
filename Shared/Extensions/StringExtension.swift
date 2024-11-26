//
//  File.swift
//  Fitness
//
//  Created by Thomas on 10/4/24.
//

import Foundation

extension String {
    init(_ decimal: Decimal) {
        self = String(Double(decimal))
    }
}
