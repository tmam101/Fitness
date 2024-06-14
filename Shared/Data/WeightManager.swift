//
//  FitnessCalculations.swift
//  Fitness
//
//  Created by Thomas Goss on 1/20/21.
//

import Foundation
#if !os(macOS)
import HealthKit
#endif
#if !os(watchOS)
import WidgetKit
#endif
import ClockKit

class WeightManager: ObservableObject {
    var environment: AppEnvironmentConfig?
    
    var startDateString = "01.23.2021"
    let endDateString = "05.01.2021"
    @Published var startingWeight: Decimal = 231.8
    @Published var currentWeight: Decimal = 231.8
    @Published var endingWeight: Decimal = 190
    @Published var progressToWeight: Decimal = 0
    @Published var weightLost: Decimal = 0
//    @Published var percentWeightLost: Int = 0
    @Published var weightToLose: Decimal = 0
    @Published var averageWeightLostPerWeek: Decimal = 0
    @Published var weights: [Weight] = []
    @Published var averageWeightLostPerWeekThisMonth: Decimal = 0
    
    @Published var shouldShowBars = true
    

    
    init(environment: AppEnvironmentConfig) {
        self.environment = environment
        switch environment {
//        case .debug:
//            getAllStatsDebug(completion: nil)
        default:
            return
        }
    }
    
    init() {
    }
    
    func getProgressToWeight() -> Decimal {
        let lost = startingWeight - currentWeight
        let totalToLose = startingWeight - endingWeight
        let progress = lost / totalToLose
        return progress
    }
    
    func progressString(from float: Decimal) -> String {
        return String(format: "%.2f", Double(float) * 100)
    }
    
    func setup() async {
        self.startDateString = Settings.get(key: .startDate) as? String ?? self.startDateString
        self.weights = await getWeights()
        self.currentWeight = self.weights.first?.weight ?? 1
        self.startingWeight = self.weights.last?.weight ?? self.startingWeight
        
        self.progressToWeight = self.getProgressToWeight()
        self.weightLost = self.startingWeight - self.currentWeight
        self.weightToLose = self.startingWeight - self.endingWeight
//        self.percentWeightLost = Int((self.weightLost / self.weightToLose) * 100)
        guard
            let startDate = Date.dateFromString(self.startDateString),
            let daysBetweenStartAndNow = Date.daysBetween(date1: startDate, date2: Date())
        else { return }
        
        let weeks: Decimal = Decimal(daysBetweenStartAndNow) / Decimal(7)
        self.averageWeightLostPerWeek = self.weightLost / weeks
    }
    
    func getWeightFromAMonthAgo() {
        var index: Int = 0
        var days: Int = 0
        var finalWeight: Weight
        
        for i in stride(from: 0, to: self.weights.count, by: 1) {
            let weight = self.weights[i]
            let date = weight.date
            guard
                let dayCount = Date.daysBetween(date1: date, date2: Date())
            else {
                print("Date that's fucked: \(date)")
                return
            }
            print("dayCount: \(dayCount)")
            if dayCount >= 30 {
                index = i
                days = dayCount
                break
            }
        }
        let newIndex = index - 1
        print(newIndex)
        print(weights)
        print(weights.count)
        let newDays = Date.daysBetween(date1: self.weights[newIndex].date, date2: Date())!
        let between1 = abs(days - 30)
        let between2 = abs(newDays - 30)
        
        if between1 <= between2 {
            finalWeight = self.weights[index]
        } else {
            finalWeight = self.weights[newIndex]
            days = newDays
        }
        let difference = finalWeight.weight - self.weights.first!.weight
        let weeklyAverageThisMonth = (difference / Decimal(days)) * Decimal(7)
        self.averageWeightLostPerWeekThisMonth = weeklyAverageThisMonth
        
    }
    
    func weight(at date: Date) -> Decimal {
        let d = Date.startOfDay(date)
        var weight1: Weight?
        var weight2: Weight?
        
        for i in stride(from: 0, to: self.weights.count, by: 1) {
            let w = Date.startOfDay(weights[i].date)
            if w == d {
                return weights[i].weight
            }
            if Date.startOfDay(weights[0].date) < d {
                return weights[0].weight
            }
            if w < d {
                weight1 = weights[i]
                weight2 = weights[i-1]
                break
            }
        }
        guard let weight1 = weight1, let weight2 = weight2 else { return 0 }
//        let maxWeight = max(weight1.weight, weight2.weight)
//        let minWeight = min(weight1.weight, weight2.weight)
        let weightDifference = weight1.weight - weight2.weight
        let dayDifferenceBetweenWeights = Date.daysBetween(date1: weight1.date, date2: weight2.date) ?? 0
        let dayDifferenceBetweenWeightAndDate = Date.daysBetween(date1: weight1.date, date2: date) ?? 0
        let proportion = weightDifference * (Decimal(dayDifferenceBetweenWeightAndDate) / Decimal(dayDifferenceBetweenWeights))
        let weightAtDate = weight1.weight - proportion
        return weightAtDate
    }
    
    // MARK - weight
    #if !os(macOS)
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    private func getWeights() async -> [Weight] {
        return await withUnsafeContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 3000, sortDescriptors: [sortDescriptor]) { (query, results, error) in
                if let results = results as? [HKQuantitySample] {
                    let weights = results
                        .map{ Weight(weight: Decimal($0.quantity.doubleValue(for: HKUnit.pound())), date: $0.endDate) }
                        .filter { $0.date >= Date.dateFromString(self.startDateString)!}
                    
                    continuation.resume(returning: weights)
                    return
                }
                
                continuation.resume(returning: [])
            }
            healthStore.execute(query)
        }
    }
    #endif
    
    //TODO: Get this working
    private func observeCalories() {
#if os(watchOS)
        // Create the calorie type.
        let calorie = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!

        // Set up the background delivery rate.
        healthStore.enableBackgroundDelivery(for: calorie,
                                          frequency: .immediate) { success, error in
            if !success {
                print("Unable to set up background delivery from HealthKit: \(error!.localizedDescription)")
            } else {
                print("observing calories")
            }
        }
        // Set up the observer query.
        let backgroundObserver =
        HKObserverQuery(sampleType: calorie, predicate: nil)
        { (query: HKObserverQuery, completionHandler: @escaping () -> Void, error: Error?) in
            // Query for actual updates here.
            // When you're done processing the changes, be sure to call the completion handler.
            let server = CLKComplicationServer.sharedInstance()
            server.activeComplications?.forEach { complication in
                server.reloadTimeline(for: complication)
            }
            completionHandler()
        }
        
        // If you successfully created the query,  execute it.
        healthStore.execute(backgroundObserver)
#endif
    }
}

