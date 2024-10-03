//
//  NutrotionAPITests.swift
//  FitnessUnitTests
//
//  Created by Thomas on 9/11/24.
//

import Testing
@testable import Fitness

@Suite
final class NutrotionAPITests {
    var mockAPI: MockNutritionAPI!
    
    init() {
        mockAPI = MockNutritionAPI()
    }
    
    @Test("Nutrition API response")
    @MainActor
    func nutrition() async throws {
        var nutrition: NutritionInfo?
        await confirmation() { confirmation in
            mockAPI.sendMessage(prompt: "Big mac", completion: {data,_,_ in
                guard let data else { return }
                nutrition = ChatView(chatService: self.mockAPI).parseChatResponse(data: data)?.first
                confirmation()
            })
        }
        #expect(nutrition?.name == "Big Mac")
        #expect(nutrition?.calories == 540)
        #expect(nutrition?.protein == 25)
    }
    
}
