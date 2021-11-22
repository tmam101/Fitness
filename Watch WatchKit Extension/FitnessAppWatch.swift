//
//  FitnessApp.swift
//  Watch WatchKit Extension
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI

@main
struct FitnessAppWatch: App {
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
