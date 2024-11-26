//
//  AppView.swift
//  Fitness
//
//  Created by Thomas Goss on 11/21/21.
//
#if !os(watchOS)
import SwiftUI

struct AppView: View {
    @EnvironmentObject var healthData: HealthData
    @State private var selectedPeriod = 2
    @State private var playerOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            TabView {
                HomeScreen(timeFrame: $selectedPeriod)
                    .environmentObject(healthData)
                    .tabItem { Label("Over Time", systemImage: "calendar") }
                    .safeAreaInset(edge: .bottom) {
                        PickerOverlay(offset: playerOffset, selectedPeriod: $selectedPeriod)
                    }
                ChatView(chatService: ChatGPTService())
                    .tabItem { Label("Log", systemImage: "square.and.pencil") }
                
                WeightView(weightManager: healthData.weightManager)
                    .tabItem { Label("Log", systemImage: "scalemass") }
                
                
                TodayView()
                    .environmentObject(healthData)
                    .tabItem { Label("Today", systemImage: "clock") }
                
                SettingsView()
                    .environmentObject(healthData)
                    .tabItem { Label("Settings", systemImage: "gear") }
                
            }
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
        }
    }
}

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
                .frame(maxHeight: 50)
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
#endif
