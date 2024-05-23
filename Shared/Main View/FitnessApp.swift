//
//  FitnessApp.swift
//  Shared
//
//  Created by Thomas Goss on 1/20/21.
//

import SwiftUI
import WatchConnectivity

class AppSettings: ObservableObject {
    @Published var healthData: HealthData
    init() {
        if  ProcessInfo.processInfo.arguments.contains("UITEST") {
            healthData = HealthData(environment: .debug([.shouldAddWeightsOnEveryDay, .isMissingConsumedCalories(.v3), .testCase(.firstDayNotAdjustingWhenMissing)]))
        } else {
            healthData = HealthData(environment: AppEnvironmentConfig.release([.shouldAddWeightsOnEveryDay, .isMissingConsumedCalories(.v3)]))

        }
    }
}

@main
struct FitnessApp: App {
//    @StateObject var healthData = HealthData(environment: AppEnvironmentConfig.release([.shouldAddWeightsOnEveryDay, .isMissingConsumedCalories(.v3)]))
//    @State var watchConnectivityIphone = WatchConnectivityIphone()
//    @Environment(\.scenePhase) private var scenePhase
    @StateObject var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
//            AppView()
//                .environmentObject(healthData)
//                .environmentObject(watchConnectivityIphone)
            AppView()
                .environmentObject(settings.healthData)
//                .environmentObject(WatchConnectivityIphone())
        }
//        .onChange(of: scenePhase) {
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
//        }
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
