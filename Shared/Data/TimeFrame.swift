//
//  TimeFrame.swift
//  Fitness
//
//  Created by Thomas on 10/12/23.
//

import Foundation

public enum TimeFrameType {
    case allTime
    case month
    case week
    
    var shortName: String {
        switch self {
        case .allTime:
            "All Time"
        case .month:
            "Month"
        case .week:
            "Week"
        }
    }
    
    var longName: String {
        switch self {
        case .allTime:
            "All Time"
        case .month:
            "This Month"
        case .week:
            "This Week"
        }
    }
    
    var days: Int {
        switch self {
        case .allTime:
            10000 // TODO
        case .month:
            30
        case .week:
            7
        }
    }
}

public struct TimeFrame: Identifiable {
    public var id = UUID()
    var type: TimeFrameType
    
    static let allTime = TimeFrame(type: .allTime)
    static let month = TimeFrame(type: .month)
    static let week = TimeFrame(type: .week)
    
    static let timeFrames: [TimeFrame] = [
        .allTime, .month, .week
    ]
    
    var days: Int {
        type.days
    }
    
    var shortName: String {
        type.shortName
    }
    
    var longName: String {
        type.longName
    }
}
