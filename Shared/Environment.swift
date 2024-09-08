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

enum AppEnvironmentConfig {
    case debug(Config?)
    case release(options: Config?)
    case widgetRelease
}

// TODO Refactor to not be an array of options, but an object with properties?
enum ConfigCase: Equatable {
    case isMissingConsumedCalories(Config.MissingConsumedCaloriesStrategy)
    case weightGoingSteadilyDown
    case dayCount(Int)
    case testCase(Filepath.Days)
    case dontAddWeightsOnEveryDay
    case subsetOfDays(Int, Int)
    case startDate(Date)
}

class Config {
    var isMissingConsumedCalories: MissingConsumedCaloriesStrategy? = nil
    var weightGoingSteadilyDown: Bool? = nil
    var dayCount: Int? = nil
    var testCase: Filepath.Days? = nil
    var dontAddWeightsOnEveryDay: Bool? = nil
    var subsetOfDays: (Int, Int)? = nil
    var startDate: Date? = nil
    
    var weightProcessor: WeightProcessorProtocol?
    var healthStorage: HealthStorageProtocol?
    
    enum MissingConsumedCaloriesStrategy {
        case v1
        case v2
        case v3
    }
    
    init(isMissingConsumedCalories: Config.MissingConsumedCaloriesStrategy? = nil, weightGoingSteadilyDown: Bool? = nil, dayCount: Int? = nil, testCase: Filepath.Days? = nil, dontAddWeightsOnEveryDay: Bool? = nil, subsetOfDays: (Int, Int)? = nil, startDate: Date? = nil, weightProcessor: (any WeightProcessorProtocol)? = nil, healthStorage: (any HealthStorageProtocol)? = nil) {
        self.isMissingConsumedCalories = isMissingConsumedCalories
        self.weightGoingSteadilyDown = weightGoingSteadilyDown
        self.dayCount = dayCount
        self.testCase = testCase
        self.dontAddWeightsOnEveryDay = dontAddWeightsOnEveryDay
        self.subsetOfDays = subsetOfDays
        self.startDate = startDate
        self.weightProcessor = weightProcessor
        self.healthStorage = healthStorage
    }
    
    init(_ options: [ConfigCase]?) {
        if let options {
            for c in options {
                switch c {
                case .isMissingConsumedCalories(let strategy):
                    self.isMissingConsumedCalories = strategy
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
}
