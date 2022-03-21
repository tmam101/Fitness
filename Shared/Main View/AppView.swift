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
                TabView {
                    FitnessView()
                        .environmentObject(healthData)
                    SettingsView()
                        .environmentObject(healthData)
                }.tabViewStyle(.page)
                //                    .environmentObject(watchConnectivityIphone)
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var healthData: HealthData
    @State var resting = "2200"
    @State var active = "200"
    @State var startDate = "1.23.2021"
    @State var showLinesOnWeightGraph = true

    var body: some View {
        VStack {
            Text("Settings")
                .foregroundColor(.white)
            HStack {
                Text("Minimum resting calories burned")
                    .foregroundColor(.white)
                TextField("2200", text: $resting)
                    .onSubmit {
                        print(resting)
                        if let restingValue = Double(resting) {
                            Settings.set(key: .resting, value: restingValue)
                        }
                    }
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Minimum active calories burned")
                    .foregroundColor(.white)
                TextField("2200", text: $active)
                    .onSubmit {
                        print(active)
                        if let activeValue = Double(active) {
                            Settings.set(key: .active, value: activeValue)
                        }
                    }
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Start Date")
                    .foregroundColor(.white)
                TextField("2200", text: $startDate)
                    .onSubmit {
                        print(startDate)
                        Settings.set(key: .startDate, value: startDate)
                    }
                    .foregroundColor(.white)
            }
            HStack {
                Toggle(isOn: $showLinesOnWeightGraph) {
                    Text("Show lines on weight graph")
                        .foregroundColor(.white)
                }
                .onChange(of: showLinesOnWeightGraph) { v in
                    Settings.set(key: .showLinesOnWeightGraph, value: v)
                }
            }
        }
        .onAppear {
            //TOdo I think accessing empty key here causes a crash
            if let r = Settings.get(key: .resting) as? Double {
                resting = String(r)
            }
            if let a = Settings.get(key: .active) as? Double {
                active = String(a)
            }
            if let s = Settings.get(key: .startDate) as? String {
                startDate = s
            }
            if let w = Settings.get(key: .showLinesOnWeightGraph) as? Bool {
                showLinesOnWeightGraph = w
            }
        }
    }
}
