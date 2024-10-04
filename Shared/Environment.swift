//
//  Environment.swift
//  Fitness
//
//  Created by Thomas Goss on 4/13/21.
//

import Foundation

struct GlobalEnvironment {
    static var isWatch: Bool {
        var isWatch = false
    #if os(watchOS)
        isWatch = true
    #endif
        return isWatch
    }
        
}

enum ConfigCase: Equatable {
    case isMissingConsumedCalories(Bool)
    case weightGoingSteadilyDown
    case dayCount(Int)
    case testCase(Filepath.Days)
    case dontAddWeightsOnEveryDay
    case subsetOfDays(Int, Int)
    case startDate(Date)
}

class AppEnvironmentConfig {
    static var release = AppEnvironmentConfig()
    static var debug = AppEnvironmentConfig(healthStorage: MockHealthStorage())
    
    var isMissingConsumedCalories: Bool = true
    var weightGoingSteadilyDown: Bool? = nil
    var dayCount: Int? = nil
    var testCase: Filepath.Days? = nil
    var dontAddWeightsOnEveryDay: Bool = false
    var subsetOfDays: (Int, Int)? = nil
    var startDate: Date? = nil
    
    var healthStorage: HealthStorageProtocol = HealthStorage()
    
    init(isMissingConsumedCalories: Bool = true, weightGoingSteadilyDown: Bool? = nil, dayCount: Int? = nil, testCase: Filepath.Days? = nil, dontAddWeightsOnEveryDay: Bool = false, subsetOfDays: (Int, Int)? = nil, startDate: Date? = nil, healthStorage: (any HealthStorageProtocol) = HealthStorage()) {
        self.isMissingConsumedCalories = isMissingConsumedCalories
        self.weightGoingSteadilyDown = weightGoingSteadilyDown
        self.dayCount = dayCount
        self.testCase = testCase
        self.dontAddWeightsOnEveryDay = dontAddWeightsOnEveryDay
        self.subsetOfDays = subsetOfDays
        self.startDate = startDate
        self.healthStorage = healthStorage
    }
    
    init(_ options: [ConfigCase]?) {
        if let options {
            for c in options {
                switch c {
                case .isMissingConsumedCalories(let bool):
                    self.isMissingConsumedCalories = bool
                case .weightGoingSteadilyDown:
                    self.weightGoingSteadilyDown = true
                case .dayCount(let count):
                    self.dayCount = count
                case .testCase(let test):
                    self.testCase = test
                case .dontAddWeightsOnEveryDay:
                    self.dontAddWeightsOnEveryDay = true
                case .subsetOfDays(let start, let end):
                    self.subsetOfDays = (start, end)
                case .startDate(let d):
                    self.startDate = d
                }
            }
        }
    }
    
    func isProduction() -> Bool {
        return NSClassFromString("XCTest") == nil
    }
}
