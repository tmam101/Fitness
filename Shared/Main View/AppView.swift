//
//  AppView.swift
//  Fitness
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI

public struct InnerContentSize: PreferenceKey {
  public typealias Value = [CGRect]

  public static var defaultValue: [CGRect] = []
  public static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
    value.append(contentsOf: nextValue())
  }
}

struct AppView: View {
    @EnvironmentObject var healthData: HealthData
    //    @EnvironmentObject var watchConnectivityIphone: WatchConnectivityIphone
    //    @State var day = Day()
    @State private var selectedPeriod = 2
    @State private var playerOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            TabView {
                FitnessView(timeFrame: $selectedPeriod)
                    .environmentObject(healthData)
                    .tabItem { Label("Over Time", systemImage: "calendar") }
                TodayView()
                    .environmentObject(healthData)
                    .tabItem { Label("Today", systemImage: "clock") }
                SettingsView()
                    .environmentObject(healthData)
                    .tabItem { Label("Settings", systemImage: "gear") }
                
            }
            .onPreferenceChange(InnerContentSize.self, perform: { value in
                self.playerOffset = geometry.size.height - (value.last?.height ?? 0)
            })
#if !os(watchOS)
            .onAppear(perform: {
                let appearance = UITabBarAppearance()
                appearance.backgroundColor = .black
                appearance.configureWithOpaqueBackground()
                appearance.stackedLayoutAppearance.normal.iconColor = .white
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                
                appearance.stackedLayoutAppearance.selected.iconColor = .yellow
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.yellow)]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            })
            .overlay(
                PickerOverlay(offset: playerOffset, selectedPeriod: $selectedPeriod), alignment: .bottom
            )
#endif
        }
    }
}

#if !os(watchOS)
struct PickerOverlay: View {
    var offset: CGFloat
    @Binding var selectedPeriod: Int
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black)
                .frame(maxHeight: 50)
            TimeFramePicker(selectedPeriod: $selectedPeriod)
                .background(.black)
        }.offset(y: -offset)
    }
}
#endif

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppPreviewProvider.MainPreview()
    }
}

public struct AppPreviewProvider {
    static func MainPreview() -> some View {
        return AppView()
            .environmentObject(HealthData(environment: .debug(nil)))
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
