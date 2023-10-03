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
        case resting
        case active
        case startDate
        case numberOfRuns
        case individualStatisticsData
        case showLinesOnWeightGraph
        case healthData
        case useActiveCalorieModifier
        case days
        case activeCalorieModifier
        case netEnergyGoal
    }
    
    static func set(key: UserDefaultsKey, value: Any) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    static func get(key: UserDefaultsKey) -> Any? {
        UserDefaults.standard.value(forKey: key.rawValue)
    }
    static func getDays() -> Days? {
        if let data = Settings.get(key: .days) as? Data {
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
            Settings.set(key: .days, value: encodedData)
        } catch {
            print("error setDaysToSettings")
        }
    }
}
