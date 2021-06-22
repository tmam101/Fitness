//
//  FitnessApp.swift
//  Shared
//
//  Created by Thomas Goss on 1/20/21.
//

import SwiftUI

@main
struct FitnessApp: App {
    @State var healthKit = MyHealthKit(environment: GlobalEnvironment.environment)
    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(healthKit)
        }
    }
}

struct AppView: View {
    @EnvironmentObject var healthKit: MyHealthKit
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                FitnessView()
                    .environmentObject(healthKit)
            }
        }
    }
}

struct FitnessApp_Previews: PreviewProvider {
    
    static var previews: some View {
        AppView()
            .environmentObject(MyHealthKit(environment: .debug))
    }
}
