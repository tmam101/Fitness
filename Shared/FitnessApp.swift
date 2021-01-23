//
//  FitnessApp.swift
//  Shared
//
//  Created by Thomas Goss on 1/20/21.
//

import SwiftUI

@main
struct FitnessApp: App {
    var body: some Scene {
        WindowGroup {
            FitnessView().environmentObject(FitnessCalculations())
        }
    }
}
