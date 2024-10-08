//
//  DateExtension.swift
//  Fitness
//
//  Created by Thomas Goss on 6/22/21.
//

import Foundation

extension Date {
    
    // MARK: STATIC
    static func daysBetween(date1: Date, date2: Date) -> Int? {
        let calendar = Calendar.current
        let startOfDay1 = calendar.startOfDay(for: date1)
        let startOfDay2 = calendar.startOfDay(for: date2)
        let components = calendar.dateComponents([.day], from: startOfDay1, to: startOfDay2)
        guard let daysBetween = components.day else { return nil }
        return abs(daysBetween)
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
    
    static func subtract(days: Int, from date: Date) -> Date {
        return Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: date)!)
    }
    
    static func add(days: Int, from date: Date) -> Date {
        return Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: days), to: date)!)
    }
    
    static func sameDay(date1: Date, date2: Date) -> Bool {
        return Calendar.current.startOfDay(for: date1) == Calendar.current.startOfDay(for: date2)
    }
    
    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    // MARK: INSTANCE
    
    func daysAgo() -> Int? {
        Date.daysBetween(date1: Date.startOfDay(Date()), date2: Date.startOfDay(self))
    }
    
    func dayOfWeek() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).capitalized
        // or use capitalized(with: locale) if you want
    }
    
    func subtracting(days: Int) -> Date {
        Date.subtract(days: days, from: self)
    }
    
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        return formatter.string(from: self)
    }
}

extension String {
    /// If the string is in  "MM.dd.yyyy" format
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        return formatter.date(from: self)
    }
}
