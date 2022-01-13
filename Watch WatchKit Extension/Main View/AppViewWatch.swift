//
//  WatchAppView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/8/22.
//

import SwiftUI

struct AppViewWatch: View {
    @EnvironmentObject var healthData: HealthData
//    @EnvironmentObject var watchConnectivityWatch: WatchConnectivityWatch

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
//                TabView {
                FitnessViewWatch()
                    .environmentObject(healthData)
//                    Text("Hey")
//                }.tabViewStyle(.page)
//                    .environmentObject(watchConnectivityWatch)
            }
        }
    }
}

struct AppViewWatch_Previews: PreviewProvider {
    static var previews: some View {
        AppViewWatch()
            .environmentObject(HealthData(environment: .debug))
        
    }
}
