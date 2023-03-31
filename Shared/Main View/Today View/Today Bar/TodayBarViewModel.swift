//
//  TodayBarViewModel.swift
//  Fitness
//
//  Created by Thomas on 3/31/23.
//

import Foundation
import Combine

class TodayBarViewModel: ObservableObject {
    @Published var today: Day
    @Published var maxValue: Double
    @Published var minValue: Double
    @Published var yValues: [Double]
    
    init(today: Day, maxValue: Double, minValue: Double, yValues: [Double]) {
        self.today = today
        self.maxValue = maxValue
        self.minValue = minValue
        self.yValues = yValues
    }
}
