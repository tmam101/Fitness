//
//  TimeFrame.swift
//  Fitness
//
//  Created by Thomas on 10/12/23.
//

import Foundation

struct TimeFrame: Identifiable {
    var id = UUID()
    var longName: String
    var name: String
    var days: Int
    
    static let allTime =
    TimeFrame(longName: "All Time", name: "All Time", days: 10000) //TODO
    static let month = TimeFrame(longName: "This Month", name: "Month", days: 30)
    static let week = TimeFrame(longName: "This Week", name: "Week", days: 7)
    
    static let timeFrames = [
        TimeFrame.allTime,
        TimeFrame.month,
        TimeFrame.week
    ]
}
