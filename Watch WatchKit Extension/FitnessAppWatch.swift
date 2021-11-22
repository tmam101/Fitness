//
//  FitnessApp.swift
//  Watch WatchKit Extension
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI

@main
struct FitnessAppWatch: App {
    @State var healthData = HealthData(environment: GlobalEnvironment.environment)
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                let y = x()
                AppView()
                    .environmentObject(healthData)
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
    
    func x() -> String {
        print(UserDefaults.standard.value(forKey: "numberOfRuns"))
        return "x"
    }
}
