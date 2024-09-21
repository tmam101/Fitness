//
//  ArrayExtension.swift
//  Fitness
//
//  Created by Thomas on 10/16/23.
//

import Foundation

extension Array where Element: Numeric {
    var sum: Element {
        return self.reduce(0, +)
    }
}

extension Array where Element: BinaryFloatingPoint {
    var average: Element? {
        guard !self.isEmpty else { return nil }
        return self.reduce(0, +) / Element(self.count)
    }
}

extension Array where Element == Decimal {
    var average: Element? {
        guard !self.isEmpty else { return nil }
        return self.reduce(0, +) / Element(self.count)
    }
}

extension Array where Element == Date {
    func sorted(_ sortOrder: SortOrder) -> [Element] {
        switch sortOrder {
        case .longestAgoToMostRecent:
            self.sorted { $0 < $1 }
        case .mostRecentToLongestAgo:
            self.sorted { $0 > $1 }
        }
    }
}

//TODO Move and test
extension Double {
    init(_ decimal: Decimal) {
        self = NSDecimalNumber(decimal: decimal).doubleValue
    }
}
