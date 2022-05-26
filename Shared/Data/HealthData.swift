//
//  MyHealthKit.swift
//  Fitness
//
//  Created by Thomas Goss on 1/26/21.
//

import Foundation
#if !os(macOS)
import HealthKit
import WatchConnectivity
#endif
#if !os(watchOS)
import WidgetKit
#endif
import SwiftUI
//import WatchConnectivity

//TODO: Should I make this @MainActor? It would resolve some async issues, like dispatch.
class HealthData: ObservableObject {
    
    //MARK: PROPERTIES
    var environment: AppEnvironmentConfig = .debug
#if !os(macOS)
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    @Published var calorieManager: CalorieManager = CalorieManager()
    @Published var runManager: RunManager = RunManager()
    private let network = Network()
#endif
    @Published public var weightManager: WeightManager = WeightManager()
    @Published public var workoutManager: WorkoutManager = WorkoutManager()
    
    // Deficits
//    @State var watchConnectivityIphone = WatchConnectivityIphone()

    @Published public var days: [Int:Day] = [:]
        
    // Days
    @Published public var daysBetweenStartAndNow: Int = 350
    @Published public var dateSaved: Date = Date.distantPast
    
    @Published public var hasLoaded: Bool = false
        
    // Constants
    @State var goalDeficit: Double = 500
    let goalEaten: Double = 1500
    let caloriesInPound: Double = 3500
    var startDateString = "01.23.2021"
    var startDate: Date?
    let formatter = DateFormatter()
    
    //MARK: INIT
    init(environment: AppEnvironmentConfig) {
        Task {
            if await authorizeHealthKit() {
                self.environment = environment
                self.startDateString = Settings.get(key: .startDate) as? String ?? self.startDateString
                await setValues(forceLoad: true, completion: nil)
            }
        }
    }
    
    init() { }
    
    init(environment: AppEnvironmentConfig, _ completion: @escaping ((_ health: HealthData) -> Void)) {
        Task {
            self.environment = environment
            self.startDateString = Settings.get(key: .startDate) as? String ?? self.startDateString
            await setValues(forceLoad: true, completion: completion)
        }
    }
    
    
    
    //MARK: SET VALUES
    
    /// Set all values of health data critifal for the app. Returns a reference to itself.
    func setValues(forceLoad: Bool = false, completion: ((_ health: HealthData) -> Void)?) async {
        hasLoaded = false
        setupDates()
//        watchConnectivityIphone = WatchConnectivityIphone()
        
        switch self.environment {
        case .release:
#if os(iOS)
            // Setup managers
            await weightManager.setup()
            await runManager.setup(fitness: weightManager, startDate: self.startDate ?? Date())
            await calorieManager.setup(startingWeight: weightManager.startingWeight, goalDeficit: goalDeficit, fitness: weightManager, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false)
            await workoutManager.setup(afterDate: self.startDate ?? Date(), environment: environment)
            
            guard !calorieManager.days.isEmpty else {
                completion?(self)
                return
            }
            
            // Set self values
            DispatchQueue.main.async { [self] in
                self.days = calorieManager.days
                self.hasLoaded = true
            }
            
//            createRealisticWeights()
            
            // Post the last thirty days. Larger amounts seem to be too much for the network.
            if calorieManager.days.count > 30 {
                let daysToRetrieve = 31
                let model = getDaysModel(from: days.filter { $0.key <= daysToRetrieve }, activeCalorieModifier: Settings.get(key: .activeCalorieModifier) as? Double ?? 1)
                let _ = await network.postWithDays(object: model)
            }
            completion?(self)
            
#endif
#if os(watchOS)
            // On watch, receive relevant data
            await setValuesFromNetworkWithDays(reloadToday: true)
            self.hasLoaded = true
            completion?(self)
#endif
#if os(macOS)
            // On watch, receive relevant data
            await setValuesFromNetwork()
            self.hasLoaded = true
            completion?(self)
#endif
        case .debug:
            await self.setValuesFromNetworkWithDays()
            completion?(self)
        }
    }
    
    func createRealisticWeights() async {
        //TODO: Finish creating realisticWeights
        // Start on first weight
        // Loop through each subsequent day, finding expected weight loss
        // Find next weight's actual loss
        // Set the realistic weight loss to: half a pound, unless the expected weight loss is greater, or the actual loss is smaller
        var realisticWeights: [Int: Double] = [:]
        var currentWeight = weightManager.weights.last
        
        for i in stride(from: days.count - 1, through: 0, by: -1) {
            await abc(i, days)
        }
        
        func abc(_ i: Int, _ days: [Int:Day]) async {
            let day = days[i]!
            let date = day.date
            let nextWeight = await weightManager.weights.last(where: { $0.date < date })
            let nextWeightDate = Date.startOfDay(nextWeight?.date ?? Date())
            if await date < Date.startOfDay(weightManager.weights.last!.date) {
                return
            }
            let expectedWeightLoss = day.deficit / 3500
            if i == days.count - 1 {
                //                    realisticWeights[i] = fitness.weights
            }
        }
    }
    
    
    func setValuesFromNetworkWithDays(reloadToday: Bool = false) async {
        guard let getResponse = await network.getResponseWithDays() else { return }
        var days: [Int:Day] = [:]
        for day in getResponse.days {
            days[day.daysAgo] = day
        }
        
        if reloadToday {
            let calorieManager = CalorieManager()
            self.calorieManager = calorieManager
            await calorieManager.setup(startingWeight: weightManager.startingWeight, goalDeficit: goalDeficit, fitness: weightManager, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false)
            var today = await calorieManager.getDays(forPastDays: 0)[0]!
            let diff = today.activeCalories - today.activeCalories * getResponse.activeCalorieModifier
            today.activeCalories = today.activeCalories * getResponse.activeCalorieModifier
            today.deficit = today.deficit - diff
            today.runningTotalDeficit = days[1]!.runningTotalDeficit + today.deficit
            print("today: \(today)")
            days[0]! = today
        }
        let _ = await calorieManager.setValues(from: days)
    }
    
    func getDaysModel(from days: [Int: Day], activeCalorieModifier: Double) -> HealthDataPostRequestModelWithDays {
        let d: [Day] = Array(days.values)
        return HealthDataPostRequestModelWithDays(days: d, activeCalorieModifier: activeCalorieModifier)
    }
    
#if  !os(macOS)
    func saveCaloriesEaten(calories: Double) async -> Bool {
        //        guard let calorieManager = self.calorieManager else { return false }
        let r = await CalorieManager().saveCaloriesEaten(calories: calories)
        return r
    }
#endif
    
    private func setupDates() {
        guard let startDate = Date.dateFromString(startDateString),
              let daysBetweenStartAndNow = Date.daysBetween(date1: startDate, date2: Date())
        else { return }
        
        self.startDate = startDate
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
    }
    
    private func authorizeHealthKit() async -> Bool {
            if !HKHealthStore.isHealthDataAvailable() { return false }
            
            let readDataTypes: Swift.Set<HKSampleType>? = [
                HKSampleType.quantityType(forIdentifier: .bodyMass)!,
                HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!,
                HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
                HKSampleType.workoutType(),
                HKSampleType.quantityType(forIdentifier: .heartRate)!,
                HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!]
            let writeDataTypes: Swift.Set<HKSampleType>? = [
                HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            ]
        
        do {
            try await HKHealthStore().requestAuthorization(toShare: writeDataTypes!, read: readDataTypes!)
            return true
        } catch {
            return false
        }
    }
}

//MARK: NETWORK MODELS

struct HealthDataPostRequestModelWithDays: Codable {
    var days: [Day] = []
    var activeCalorieModifier: Double = 1
}

struct HealthDataGetRequestModelWithDays: Codable {
    let id: String
    let days: [Day]
    let createdAt: String
    let activeCalorieModifier: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case days, createdAt, activeCalorieModifier
    }
}
