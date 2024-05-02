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

enum TestDayOption:Equatable {
    case missingData
    case weightGoingSteadilyDown
    case weightsOnEveryDay
    case testCase(Days.TestFiles)
}
