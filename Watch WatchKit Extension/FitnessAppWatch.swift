//
//  FitnessApp.swift
//  Watch WatchKit Extension
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI
import ClockKit

@main
struct FitnessAppWatch: App {
    @State var healthData = HealthData(environment: GlobalEnvironment.environment)
    @Environment(\.scenePhase) private var scenePhase

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                AppView()
                    .environmentObject(healthData)
            }.onAppear {
                let server = CLKComplicationServer.sharedInstance()
                server.activeComplications?.forEach { complication in
                  server.reloadTimeline(for: complication)
                }
            }.onChange(of: scenePhase, perform: {_ in
                let server = CLKComplicationServer.sharedInstance()
                server.activeComplications?.forEach { complication in
                  server.reloadTimeline(for: complication)
                }
            })
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
    

}
