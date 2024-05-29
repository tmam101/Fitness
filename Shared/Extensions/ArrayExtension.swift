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

protocol HasDate {
    var date: Date { get }
}

extension Array where Element: HasDate {
    func sortedMostRecentToLongestAgo() -> [Element] {
        return self.sorted { $0.date > $1.date }
    }
    
    func sortedLongestAgoToMostRecent() -> [Element] {
        return self.sorted { $0.date < $1.date }
    }
}
