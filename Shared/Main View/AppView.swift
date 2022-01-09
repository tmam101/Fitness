//
//  AppView.swift
//  Fitness
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI

struct AppView: View {
    @EnvironmentObject var healthData: HealthData
//    @EnvironmentObject var watchConnectivityIphone: WatchConnectivityIphone

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                FitnessView()
                    .environmentObject(healthData)
//                    .environmentObject(watchConnectivityIphone)
            }
        }
    }
}
