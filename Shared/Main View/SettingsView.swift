//
//  SettingsView.swift
//  Fitness
//
//  Created by Thomas on 9/21/24.
//

import SwiftUI
// https://stackoverflow.com/questions/65493916/mockable-appstorage-in-swiftui
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
            Form {
                Section(header: Text("Calories")) {
                    HStack() {
                        Text("Minimum resting calories burned")
                            .foregroundColor(.white)
                        Spacer()
                        TextField("", text: $resting)
                            .onSubmit {
                                print(resting)
                                if let restingValue = Decimal(resting) {
                                    Settings.set(.resting, value: restingValue)
                                }
                            }
                    }
                    HStack {
                        Text("Minimum active calories burned")
                            .foregroundColor(.white)
                        TextField("", text: $active)
                            .onSubmit {
                                print(active)
                                if let activeValue = Decimal(active) {
                                    Settings.set(.active, value: activeValue)
                                }
                            }
                            .foregroundColor(.white)
                    }
                    HStack {
                        Toggle(isOn: $useActiveCalorieModifier) {
                            Text("Use active calorie modifier")
                                .foregroundColor(.white)
                        }
                        .onChange(of: useActiveCalorieModifier) { _, new in
                            Settings.set(.useActiveCalorieModifier, value: new)
                        }
                    }
                }
                Section(header: Text("Start date")) {
                    HStack {
                        Text("Start Date")
                            .foregroundColor(.white)
                        TextField("", text: $startDate)
                            .onSubmit {
                                Task {
                                    print(startDate)
                                    Settings.set(.startDate, value: startDate)
                                    healthData.setupDates(environment: healthData.environment)
                                    await healthData.setValues(completion: nil)
                                }
                            }
                            .foregroundColor(.white)
                    }
                }
                Section(header: Text("UI")) {
                    HStack {
                        Toggle(isOn: $showLinesOnWeightGraph) {
                            Text("Show lines on weight graph")
                                .foregroundColor(.white)
                        }
                        .onChange(of: showLinesOnWeightGraph) { _, new in
                            Settings.set(.showLinesOnWeightGraph, value: new)
                        }
                    }
                }
            }
        }
        .onAppear {
            //TOdo I think accessing empty key here causes a crash
            if let r = Settings.get(.resting) {
                resting = String(r)
            }
            if let a = Settings.get(.active) {
                active = String(a)
            }
            if let s = Settings.get(.startDate) {
                startDate = s
            }
            if let w = Settings.get(.showLinesOnWeightGraph) {
                showLinesOnWeightGraph = w
            }
            if let m = Settings.get(.useActiveCalorieModifier) {
                useActiveCalorieModifier = m
            }
        }
    }
}

#Preview {
    SettingsView()
}
