//
//  Defaults.swift
//  Fitness
//
//  Created by Thomas Goss on 3/1/22.
//

import Foundation

struct Settings {
    enum UserDefaultsKey: String {
        case resting
        case active
        case startDate
        case numberOfRuns
        case individualStatisticsData
    }
    static func set(key: UserDefaultsKey, value: Any) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    static func get(key: UserDefaultsKey) -> Any? {
        UserDefaults.standard.value(forKey: key.rawValue)
    }
}
