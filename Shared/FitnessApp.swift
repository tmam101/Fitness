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
    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(healthData)
        }
    }
}

struct AppView: View {
    @EnvironmentObject var healthData: HealthData
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                FitnessView()
                    .environmentObject(healthData)
            }
        }
    }
}

struct FitnessApp_Previews: PreviewProvider {
    
    static var previews: some View {
        AppView()
            .environmentObject(HealthData(environment: .debug))
    }
}
