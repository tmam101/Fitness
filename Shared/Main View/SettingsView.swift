//
//  SettingsView.swift
//  Fitness
//
//  Created by Thomas on 9/21/24.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var healthData: HealthData
    @State var resting = "2200"
    @State var active = "200"
    @State var startDate = "1.23.2021"
    @State var showLinesOnWeightGraph = true
    @State var useActiveCalorieModifier = true
    
    var body: some View {
        VStack {
            Text("Test")
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
                .onChange(of: showLinesOnWeightGraph) { _, new in
                    Settings.set(key: .showLinesOnWeightGraph, value: new)
                }
            }
            HStack {
                Toggle(isOn: $useActiveCalorieModifier) {
                    Text("Use active calorie modifier")
                        .foregroundColor(.white)
                }
                .onChange(of: useActiveCalorieModifier) { _, new in
                    Settings.set(key: .useActiveCalorieModifier, value: new)
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
