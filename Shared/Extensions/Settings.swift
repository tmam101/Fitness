//
//  Defaults.swift
//  Fitness
//
//  Created by Thomas Goss on 3/1/22.
//

import Foundation

//TODO Send this to backend so watch or widget can access
struct Settings {
    enum UserDefaultsKey: String {
        case numberOfRuns
        case individualStatisticsData
        case healthData
        case activeCalorieModifier
    }
    
    enum UserDefaultsDecimal: String {
        case resting
        case active
        case netEnergyGoal
    }
    enum UserDefaultsBool: String {
        case showLinesOnWeightGraph
        case useActiveCalorieModifier
    }
    enum UserDefaultsString: String {
        case startDate
    }
    enum UserDefaultsData: String {
        case days
    }
    static func get(_ key: UserDefaultsDecimal) -> Decimal? {
        UserDefaults.standard.value(forKey: key.rawValue) as? Decimal
    }
    static func get(_ key: UserDefaultsBool) -> Bool? {
        UserDefaults.standard.value(forKey: key.rawValue) as? Bool
    }
    static func get(_ key: UserDefaultsString) -> String? {
        UserDefaults.standard.value(forKey: key.rawValue) as? String
    }
    static func get(_ key: UserDefaultsData) -> Data? {
        UserDefaults.standard.value(forKey: key.rawValue) as? Data
    }
    
    static func set(_ key: UserDefaultsDecimal, value: Decimal) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    static func set(_ key: UserDefaultsBool, value: Bool) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    static func set(_ key: UserDefaultsString, value: String) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    static func set(_ key: UserDefaultsData, value: Data) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    static func getDays() -> Days? {
        if let data = Settings.get(.days) {
            do {
                let unencoded = try JSONDecoder().decode(Days.self, from: data)
                return unencoded
            } catch {
                print("error getDaysFromSettings")
                return nil
            }
        }
        return nil
    }
    
    static func setDays(days: Days) {
        do {
            let encodedData = try JSONEncoder().encode(days)
            Settings.set(.days, value: encodedData)
        } catch {
            print("error setDaysToSettings")
        }
    }
}
