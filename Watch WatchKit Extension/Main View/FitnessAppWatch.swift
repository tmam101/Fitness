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
    @State var watchConnectivityWatch = WatchConnectivityWatch()
    
    @Environment(\.scenePhase) private var scenePhase

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchAppView()
                    .environmentObject(healthData)
                    .environmentObject(watchConnectivityWatch)
            }.onAppear {
                watchConnectivityWatch.setHealthData(healthData: healthData)
                watchConnectivityWatch.requestHealthData()
                let server = CLKComplicationServer.sharedInstance()
                server.activeComplications?.forEach { complication in
                  server.reloadTimeline(for: complication)
                }
            }.onChange(of: scenePhase) { [scenePhase] newPhase in
                if newPhase == .active {
                    let server = CLKComplicationServer.sharedInstance()
                    server.activeComplications?.forEach { complication in
                        server.reloadTimeline(for: complication)
                    }
//                    watchConnectivityWatch.requestHealthData()
                }
            }
        }
        
        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
    

}
