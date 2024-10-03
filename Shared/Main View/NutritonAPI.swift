//
//  NutritonAPI.swift
//  Fitness
//
//  Created by Thomas on 9/9/24.
//
#if !os(watchOS)

import Foundation
import SwiftUI
import HealthKit

class ChatGPTService: NutritionAPIProtocol {
    
    var apiKey: String? {
        return Bundle.main.infoDictionary?["API_KEY"] as? String
    }
    
    func sendMessage(prompt: String, completion: @escaping (Data?, URLResponse?, (any Error)?) -> Void) {
        guard let apiKey else {
            completion(nil, nil, nil) // TODO error
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
"name": "<name of food>",
"calories": <your answer>,
"protein": <your answer>
}

if the request contains multiple distinct items, like "sandwich and drink", then return info for both of them separately. like this:

[
{
"name": "sandwich",
"calories": <your answer>,
"protein": <your answer>
},
{
"name": "drink",
"calories": <your answer>,
"protein": <your answer>
}
]

It should accomodate as many or as few items as the request contains, 1 to 5.
Don't include any units of measurement. It should be valid json, with calories and protein as numbers and name as string
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
            completion(data, response, error)
        }.resume()
    }
}

protocol NutritionAPIProtocol {
    func sendMessage(prompt: String, completion: @escaping (Data?, URLResponse?, (any Error)?) -> Void)
}

class MockNutritionAPI: NutritionAPIProtocol {
    func sendMessage(prompt: String, completion: @escaping (Data?, URLResponse?, (any Error)?) -> Void) {
        let mockResponse = """
        {
          "id": "chatcmpl-A61nUW5w0XnMKkmDoNdVtOQOh69Ci",
          "object": "chat.completion",
          "created": 1726000240,
          "model": "gpt-4o-mini-2024-07-18",
          "choices": [
            {
              "index": 0,
              "message": {
                "role": "assistant",
                "content": "{\\n\\"name\\": \\"Big Mac\\",\\n\\"calories\\": 540,\\n\\"protein\\": 25\\n}",
                "refusal": null
              },
              "logprobs": null,
              "finish_reason": "stop"
            }
          ],
          "usage": {
            "prompt_tokens": 181,
            "completion_tokens": 21,
            "total_tokens": 202
          },
          "system_fingerprint": "fp_483d39d857"
        }
        """.data(using: .utf8)
        
        completion(mockResponse, nil, nil)
    }
}

public struct ChatView: View {
    @State private var userInput: String = ""
    @State private var chatResponse: String = ""
    @State private var loggedFoods: [LoggedFood] = []
    @State private var isLoading = false

    let chatService: NutritionAPIProtocol
    
    public var body: some View {
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
            
            Button(action: save) {
                Text("Save")
            }
            
            Button(action: loadRecentFoods) {
                Text("load")
            }
            VStack(alignment: .leading) {
                ForEach(loggedFoods) { food in
                    Group {
                        Text("Calories: \(food.calories ?? 0)")
                        Text("Protein: \(food.protein ?? 0)")
                    }
                    .background(Color.myGray)
                    .cornerRadius(10)
                    .border(.red)
                }
            }
        }
        .padding()
    }
    
    private func save() {
        /*let c = CalorieManager(environment: .release)*/ // TODO
//        c.saveCaloriesEaten(calories: <#T##Decimal#>)
    }

    private func sendMessage() {
        isLoading = true
        chatService.sendMessage(prompt: userInput) { data,urlResponse,error  in
//            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    // TODO
                    return
                }
                
                guard let info = self.parseChatResponse(data: data) else {
                    // TODO
                    isLoading = false
                    chatResponse = "Failed to load"
                    return
                }
            var string = ""
            for text in info {
                string.append(
                    """
                    \(text.name ?? "")
                    Calories: \(text.calories ?? 0)
                    Protein: \(text.protein ?? 0)
                    \n
                    """
                )
            }
                chatResponse = string
                isLoading = false
            }
        }
    
    // Function to decode JSON using Codable
    func parseChatResponse(data: Data) -> [NutritionInfo]? {
        do {
            // Step 1: Decode the ChatResponse to get the content string
            let response = try JSONDecoder().decode(ChatResponse.self, from: data)
            
            // Extract the content string from the message
            if let content = response.choices.first?.message.content {
                
                // Step 2: Convert the content string into Data to decode it into NutritionInfo
                let contentData = Data(content.utf8)
                if let nutritionInfoArray = try? JSONDecoder().decode([NutritionInfo].self, from: contentData) {
                    return nutritionInfoArray
                }
                
                let singleNutritionInfo = try JSONDecoder().decode(NutritionInfo.self, from: contentData)
                return [singleNutritionInfo]
            }
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
        return nil
    }
    
    private func loadRecentFoods() {
        let healthStore = HKHealthStore()
        func fetchFoodLogsWithEnergyAndProtein(completion: @escaping ([LoggedFood]) -> Void) {
            // Define the types for energy (calories) and protein
            let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            
            // Create a predicate (optional) to limit the results, for example, to today's logs
            let predicate = HKQuery.predicateForSamples(withStart: Date().subtracting(days: 1), end: Date(), options: [])
            
            // Create a dispatch group to handle the two queries concurrently
            let dispatchGroup = DispatchGroup()
            
            var energySamples: [HKQuantitySample] = []
            var proteinSamples: [HKQuantitySample] = []
            
            // Query for dietary energy consumed (calories)
            dispatchGroup.enter()
            let energyQuery = HKSampleQuery(sampleType: energyType, predicate: predicate, limit: 0, sortDescriptors: nil) { (_, results, error) in
                if let results = results as? [HKQuantitySample], error == nil {
                    energySamples = results
                }
                dispatchGroup.leave()
            }
            
            // Query for dietary protein
            dispatchGroup.enter()
            let proteinQuery = HKSampleQuery(sampleType: proteinType, predicate: predicate, limit: 0, sortDescriptors: nil) { (_, results, error) in
                if let results = results as? [HKQuantitySample], error == nil {
                    proteinSamples = results
                }
                dispatchGroup.leave()
            }
            
            healthStore.execute(energyQuery)
            healthStore.execute(proteinQuery)
            
            // Once both queries are done, match the samples by date
            dispatchGroup.notify(queue: .main) {
                var combinedResults: [(energy: HKQuantitySample?, protein: HKQuantitySample?)] = []
                
                // Match samples based on start and end date
                for energySample in energySamples {
                    let matchingProteinSample = proteinSamples.first {
                        var matching = $0.startDate == energySample.startDate && $0.endDate == energySample.endDate
                        if let meal1 = $0.metadata?["Meal"] as? String, let meal2 = energySample.metadata?["Meal"] as? String {
                            matching = matching && meal1 == meal2
                        }
                        return matching
                    }
                    
                    combinedResults.append((energy: energySample, protein: matchingProteinSample))
                }
                
                // Handle protein samples without matching energy samples
                for proteinSample in proteinSamples where !combinedResults.contains(where: { $0.protein == proteinSample }) {
                    combinedResults.append((energy: nil, protein: proteinSample))
                }
                
                completion(combinedResults.map { LoggedFood(protein: $0.protein?.quantity.doubleValue(for: .gram()), calories: $0.energy?.quantity.doubleValue(for: .kilocalorie())) })
            }
        }
        fetchFoodLogsWithEnergyAndProtein() { loggedFood in
            self.loggedFoods = loggedFood
        }
    }
}

struct LoggedFood: Identifiable {
    var id = UUID() // TODO
    var name: String?
    var protein: Double?
    var calories: Double?
    
    init(name: String? = nil, protein: Double? = nil, calories: Double? = nil) {
        self.name = name
        self.protein = protein
        self.calories = calories
    }
}

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
    let name: String?
    let calories: Int?
    let protein: Int?
}

#Preview {
    ChatView(chatService: MockNutritionAPI())
}

#endif
