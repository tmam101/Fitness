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
        for path in Filepath.Days.allCases {
            if ProcessInfo.processInfo.arguments.contains(path.rawValue) {
                healthData = HealthData(environment: .debug([ .isMissingConsumedCalories(.v3), .testCase(path)]))
                return
            }
        }
        healthData = HealthData(environment: AppEnvironmentConfig.release([ .isMissingConsumedCalories(.v3)]))
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
            .environmentObject(HealthData(environment: .debug([.testCase(.firstDayNotAdjustingWhenMissing), .isMissingConsumedCalories(.v3)])))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
//            .environmentObject(WatchConnectivityIphone())
    }
}
