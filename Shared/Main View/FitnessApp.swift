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
                healthData = HealthData(environment: .init([ .isMissingConsumedCalories(true), .testCase(path)]))
                return
            }
        }
        healthData = HealthData(environment: AppEnvironmentConfig.release)
        Task {
            await healthData.setValues(forceLoad: true, completion: nil)
        }
    }
}

@main
struct MainEntryPoint {
    static func main() {
        guard isProduction() else {
            TestApp.main()
            return
        }
        FitnessApp.main()
    }
    private static func isProduction() -> Bool {
        return NSClassFromString("XCTest") == nil
    }
}

struct TestApp: App {
    var body: some Scene {
        WindowGroup {
        }
    }
}

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
            .environmentObject(HealthData(environment: .init([.testCase(.firstDayNotAdjustingWhenMissing), .isMissingConsumedCalories(true)])))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
//            .environmentObject(WatchConnectivityIphone())
    }
}
