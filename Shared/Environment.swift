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
    
    static var environment = AppEnvironmentConfig.debug
    
}

enum AppEnvironmentConfig {
    case debug
    case release
}
