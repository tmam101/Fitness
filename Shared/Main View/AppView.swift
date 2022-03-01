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

struct Defaults {
    enum UserDefaultsKey: String {
        case resting
        case active
        case startDate
    }
    static func set(key: UserDefaultsKey, value: Any) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    static func get(key: UserDefaultsKey) -> Any? {
        UserDefaults.standard.value(forKey: key.rawValue)
    }
}

struct SettingsView: View {
    @EnvironmentObject var healthData: HealthData
    @State var resting = "2200"
    @State var active = "200"
    @State var startDate = "12-12-12"
    
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
                            Defaults.set(key: .resting, value: restingValue)
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
                            Defaults.set(key: .active, value: activeValue)
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
                        if let activeValue = Double(active) {
                            Defaults.set(key: .active, value: activeValue)
                        }
                    }
                    .foregroundColor(.white)
            }
        }.onAppear {
            //TOdo I think accessing empty key here causes a crash
            if let r = Defaults.get(key: .resting) as? Double {
                resting = String(r)
            }
            if let a = Defaults.get(key: .active) as? Double {
                resting = String(a)
            }
            if let r = Defaults.get(key: .resting) as? Double {
                resting = String(r)
            }
        }
    }
}
