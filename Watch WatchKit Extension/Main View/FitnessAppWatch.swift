//
//  FitnessApp.swift
//  Watch WatchKit Extension
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI
import ClockKit
import WatchKit

@main
struct FitnessAppWatch: App {
    @State var healthData = HealthData(environment: AppEnvironmentConfig.release)
    @State var watchConnectivityWatch = WatchConnectivityWatch()
    
    @Environment(\.scenePhase) private var scenePhase

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                AppViewWatch()
                    .environmentObject(healthData)
                    .environmentObject(watchConnectivityWatch)
            }.onAppear {
                watchConnectivityWatch.setHealthData(healthData: healthData)
//                watchConnectivityWatch.requestHealthData()
                let server = CLKComplicationServer.sharedInstance()
                server.activeComplications?.forEach { complication in
                  server.reloadTimeline(for: complication)
                }
            }.onChange(of: scenePhase) { oldPhase, newPhase in
                print("old scene phase \(oldPhase) new scene phase \(newPhase)")
                if scenePhase == .background {
                    let server = CLKComplicationServer.sharedInstance()
                    server.activeComplications?.forEach { complication in
                        server.reloadTimeline(for: complication)
                    }
                    print("reloading health data")
//                    watchConnectivityWatch.requestHealthData()
                }
            }
        }
        
//        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: <#T##Date#>, userInfo: <#T##(NSSecureCoding & NSObjectProtocol)?#>, scheduledCompletion: <#T##(Error?) -> Void#>)

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
    
}

struct FitnessAppWatch_Previews: PreviewProvider {
    static var previews: some View {
        AppViewWatch()
            .environmentObject(HealthData(environment: .debug))
//            .environmentObject(WatchConnectivityWatch())
    }
}
