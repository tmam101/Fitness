//
//  FitnessApp.swift
//  Shared
//
//  Created by Thomas Goss on 1/20/21.
//

import SwiftUI
import WatchConnectivity

class AppSettings: ObservableObject {
    @Published var healthData: HealthData = HealthData(environment: .debug)
    
    init() {
        for path in Filepath.Days.allCases {
            if ProcessInfo.processInfo.arguments.contains(path.rawValue) {
                healthData = HealthData(environment: .init([ .isMissingConsumedCalories(true), .testCase(path)]))
                return
            }
        }
        healthData = HealthData(environment: AppEnvironmentConfig.release)
        Task {
            await healthData.setValues(forceLoad: true, completion: nil) // TODO doesnt this happen inside the healthdata init
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
    @StateObject var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(settings.healthData)
        }
    }
}

struct FitnessApp_Previews: PreviewProvider {
    
    static var previews: some View {
        AppView()
            .environmentObject(HealthData(environment: .init([.testCase(.firstDayNotAdjustingWhenMissing), .isMissingConsumedCalories(true)])))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
    }
}
