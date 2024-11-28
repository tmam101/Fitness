//
//  TimeFrame.swift
//  Fitness
//
//  Created by Thomas on 10/12/23.
//

import Foundation

public enum TimeFrame: CaseIterable {
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
