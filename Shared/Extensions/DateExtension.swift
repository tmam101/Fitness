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
    
    //TODO: I think this can be wrong if the order of the dates is wrong. need to fix
    static func daysBetween(date1: Date, date2: Date) -> Int? {
        let components1 = Calendar.current.dateComponents([.day, .month, .year], from: date1)
        let day1String = "\(components1.month!).\(components1.day!).\(components1.year!)"
        let components2 = Calendar.current.dateComponents([.day, .month, .year], from: date2)
        let day2String = "\(components2.month!).\(components2.day!).\(components2.year!)"
//        let date1String = "\(Calendar.current.dateComponents([.month], from: date1).month!).\(Calendar.current.dateComponents([.day], from: date1).day!).\(Calendar.current.dateComponents([.year], from: date1).year!)"
        let newDate1 = dateFromString(day1String) ?? Date()
        let newDate2 = dateFromString(day2String) ?? Date()
        return Calendar
            .current
            .dateComponents([.day], from: newDate1, to: newDate2)
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
    
    static func subtract(days: Int, from date: Date) -> Date {
        return Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: date)!)
    }
    
    static func sameDay(date1: Date, date2: Date) -> Bool {
        return Calendar.current.startOfDay(for: date1) == Calendar.current.startOfDay(for: date2)
    }
    
    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    func dayOfWeek() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).capitalized
        // or use capitalized(with: locale) if you want
    }
}
