//
//  DateExtension.swift
//  Fitness
//
//  Created by Thomas Goss on 6/22/21.
//

import Foundation

extension Date {
    
    static func stringFromDate(date: Date) -> String {
        let components = Calendar.current.dateComponents([.day, .month, .year], from: date)
        let string = "\(components.month ?? 0)/\(components.day ?? 0)/\((components.year ?? 0) - 2000)"
        return string
    }
    
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
