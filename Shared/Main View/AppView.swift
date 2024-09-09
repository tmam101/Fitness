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
    @State private var selectedPeriod = 2
    @State private var playerOffset: CGFloat = 0

    var body: some View {
#if !os(watchOS)
        GeometryReader { geometry in
            TabView {
#if !os(watchOS)
                ChatView()
                #endif
                HomeScreen(timeFrame: $selectedPeriod)
                    .environmentObject(healthData)
                    .tabItem { Label("Over Time", systemImage: "calendar") }
                
                .safeAreaInset(edge: .bottom) {
                    PickerOverlay(offset: playerOffset, selectedPeriod: $selectedPeriod)
                }
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
//            .overlay(
//                PickerOverlay(offset: playerOffset, selectedPeriod: $selectedPeriod), alignment: .bottom
//            )
        }
#endif

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
                .frame(maxHeight: 50)
        }
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

#if !os(watchOS)

class ChatGPTService {
    
    var apiKey: String? {
        return Bundle.main.infoDictionary?["API_KEY"] as? String
    }
    
    func sendMessage(prompt: String, completion: @escaping (String?) -> Void) {
        guard let apiKey else {
            completion(nil)
            return
        }
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": """
                    Expect a question about nutrition. You should respond in json format so that it can be parsed by an app. Like this: 
{
calories: <your answer>,
protein: <your answer>
}

only respond with calories or protein info, and dont return one if it seems unnecessary to the request.
"""
                      ],
                [
                    "role": "user",
                    "content": "\(prompt)"
                ]
            ],
            "max_tokens": 1000,
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            guard let text = self.parseChatResponse(data: data) else {
                completion(nil)
                return
            }
            completion(text.calories.description.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
    // Function to decode JSON using Codable
    func parseChatResponse(data: Data) -> NutritionInfo? {
        do {
            // Decode the initial chat response
            let response = try JSONDecoder().decode(ChatResponse.self, from: data)
            
            // Extract the content from the message
            if let content = response.choices.first?.message.content {
                
                // Try to decode the content string into a NutritionInfo object
                let contentData = Data(content.utf8)
                let nutritionInfo = try JSONDecoder().decode(NutritionInfo.self, from: contentData)
                
                return nutritionInfo
            }
        } catch {
            print("Error decoding JSON: \(error)")
        }
        return nil
    }
}

struct ChatView: View {
    @State private var userInput: String = ""
    @State private var chatResponse: String = ""
    @State private var isLoading = false

    private let chatService = ChatGPTService()

    var body: some View {
        VStack {
            TextField("Enter your message", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: sendMessage) {
                Text("Send")
            }
            .disabled(userInput.isEmpty || isLoading)
            .padding()

            if isLoading {
                ProgressView()
                    .padding()
            }

            Text(chatResponse)
                .padding()
        }
        .padding()
    }

    private func sendMessage() {
        isLoading = true
        chatService.sendMessage(prompt: userInput) { response in
            DispatchQueue.main.async {
                chatResponse = response ?? "Failed to get response"
                isLoading = false
            }
        }
    }
}
#endif

// Define Codable structures to represent the JSON response
struct ChatResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let role: String
    let content: String
}

struct NutritionInfo: Codable {
    let calories: Int
    let protein: Int
}
