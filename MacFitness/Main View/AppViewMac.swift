//
//  WatchAppView.swift
//  Fitness
//
//  Created by Thomas Goss on 1/8/22.
//

import SwiftUI

struct AppViewMac: View {
    @EnvironmentObject var healthData: HealthData

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                FitnessViewMac()
                    .environmentObject(healthData)
            }
        }
    }
}
