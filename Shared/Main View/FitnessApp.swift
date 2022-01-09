//
//  FitnessApp.swift
//  Shared
//
//  Created by Thomas Goss on 1/20/21.
//

import SwiftUI

@main
struct FitnessApp: App {
    @State var healthData = HealthData(environment: GlobalEnvironment.environment)
    @State var watchConnectivityIphone = WatchConnectivityIphone()
    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(healthData)
                .environmentObject(watchConnectivityIphone)
        }
    }
}

struct FitnessApp_Previews: PreviewProvider {
    
    static var previews: some View {
        AppView()
            .environmentObject(HealthData(environment: .debug))
    }
}
