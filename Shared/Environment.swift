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
    case debug([TestDayOption]?)
    case release([TestDayOption]?)
    case widgetRelease
}

enum TestDayOption: Equatable {
    case isMissingConsumedCalories(MissingConsumedCaloriesStrategy)
    case weightGoingSteadilyDown
    case shouldAddWeightsOnEveryDay
    case dayCount(Int)
    case testCase(Days.TestFiles)
    
    enum MissingConsumedCaloriesStrategy {
        case v1
        case v2
    }
}

struct TestOptionModel {
    // Default values for options
    var missingData = false
    var isMissingConsumedCalories: TestDayOption
}

extension [TestDayOption] {
    
}
