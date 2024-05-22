//
//  FitnessApp.swift
//  Shared
//
//  Created by Thomas Goss on 1/20/21.
//

import SwiftUI
import WatchConnectivity

@main
struct FitnessApp: App {
    @State var healthData = HealthData(environment: AppEnvironmentConfig.release([.shouldAddWeightsOnEveryDay, .isMissingConsumedCalories(.v3)]))
    @State var watchConnectivityIphone = WatchConnectivityIphone()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
//            AppView()
//                .environmentObject(healthData)
//                .environmentObject(watchConnectivityIphone)
            AppView()
                .environmentObject(healthData)
//                .environmentObject(WatchConnectivityIphone())
        }.onChange(of: scenePhase) {
//            if scenePhase == .background {
//                Task {
//                    WCSession.default.sendMessage(["started":"absolutely"], replyHandler: { response in
//                        print("watch connectivity iphone received \(response)")
//                    }, errorHandler: { error in
//                        print("watch connectivity iphone error \(error)")
//                    })
////                    watchConnectivityIphone = WatchConnectivityIphone()
//                }
//            }
        }
    }
}

struct FitnessApp_Previews: PreviewProvider {
    
    static var previews: some View {
        AppView()
            .environmentObject(HealthData(environment: .debug(nil)))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
//            .environmentObject(WatchConnectivityIphone())
    }
}
