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
//    @State var day = Day()
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                TabView {
                    FitnessView()
                        .environmentObject(healthData)
                    TodayView() // This is using a different healthData, could be an issue
                        .environmentObject(healthData)
//                        .environmentObject(TodayViewModel(today: Day(), environment: .release))
                    SettingsView()
                        .environmentObject(healthData)
                }.tabViewStyle(.page)
                //                    .environmentObject(watchConnectivityIphone)
            }
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppPreviewProvider.MainPreview()
    }
}

public struct AppPreviewProvider {
    static func MainPreview() -> some View {
        return AppView()
            .environmentObject(HealthData(environment: .debug))
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
    }
}

struct SettingsView: View {
    @EnvironmentObject var healthData: HealthData
    @State var resting = "2200"
    @State var active = "200"
    @State var startDate = "1.23.2021"
    @State var showLinesOnWeightGraph = true
    @State var useActiveCalorieModifier = true

    var body: some View {
        VStack {
            Text("Settings")
                .foregroundColor(.white)
            HStack {
                Text("Minimum resting calories burned")
                    .foregroundColor(.white)
                TextField("", text: $resting)
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
                TextField("", text: $active)
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
                TextField("", text: $startDate)
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
            HStack {
                Toggle(isOn: $useActiveCalorieModifier) {
                    Text("Use active calorie modifier")
                        .foregroundColor(.white)
                }
                .onChange(of: useActiveCalorieModifier) { v in
                    Settings.set(key: .useActiveCalorieModifier, value: v)
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
            if let m = Settings.get(key: .useActiveCalorieModifier) as? Bool {
                useActiveCalorieModifier = m
            }
        }
    }
}
