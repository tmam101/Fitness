//
//  Environment.swift
//  Fitness
//
//  Created by Thomas Goss on 4/13/21.
//

import Foundation

struct GlobalEnvironment {
    static var environment = AppEnvironmentConfig.release
}

enum AppEnvironmentConfig {
    case debug
    case release
}
