//
//  FitnessApp.swift
//  Watch WatchKit Extension
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI

@main
struct FitnessAppMac: App {
    @State var healthData = HealthData(environment: AppEnvironmentConfig.release)
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                AppViewMac()
                    .environmentObject(healthData)
            }
        }
    }
}
