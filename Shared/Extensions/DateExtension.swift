//
//  DateExtension.swift
//  Fitness
//
//  Created by Thomas Goss on 6/22/21.
//

import Foundation

extension Date {
    static func daysBetween(date1: Date, date2: Date) -> Int? {
        return Calendar
            .current
            .dateComponents([.day], from: date1, to: date2)
            .day
    }
    
    static func dateFromString(_ string: String) -> Date?  {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        return formatter.date(from: string)
    }
    
    // MM.dd.yy
    static func dateFromString(month: String, day: String, year: String) -> Date?  {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        return formatter.date(from: "\(month).\(day).\(year)")
    }
}
