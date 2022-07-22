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

//TODO: Should I make this @MainActor? It would resolve some async issues, like dispatch.
class HealthData: ObservableObject {
    
    //MARK: PROPERTIES
    var environment: AppEnvironmentConfig = .debug
#if !os(macOS)
    @Published var calorieManager: CalorieManager = CalorieManager()
    @Published var runManager: RunManager = RunManager()
    private let network = Network()
#endif
    @Published public var weightManager: WeightManager = WeightManager()
    @Published public var workoutManager: WorkoutManager = WorkoutManager()

    @Published public var days: Days = [:]
    @Published public var daysBetweenStartAndNow: Int = 350
    @Published public var hasLoaded: Bool = false
    @Published public var realisticWeights: [Int: Double] = [:]
    @Published public var weights: [Double] = []
        
    // Constants
    var startDateString = "01.23.2021"
    var startDate: Date?
    
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
        
        switch self.environment {
        case .release:
#if os(iOS)
            // Setup managers
            await weightManager.setup()
            await runManager.setup(fitness: weightManager, startDate: self.startDate ?? Date())
            await calorieManager.setup(startingWeight: weightManager.startingWeight, fitness: weightManager, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false)
            await workoutManager.setup(afterDate: self.startDate ?? Date(), environment: environment)
            
            guard !calorieManager.days.isEmpty else {
                completion?(self)
                return
            }
            
            let realisticWeights = createRealisticWeights()
            
            // Set realistic weights on days
            for i in 0..<calorieManager.days.count {
                calorieManager.days[i]?.realisticWeight = realisticWeights[i] ?? 0.0
            }
            
            // Set real weights on days
            // TODO: Have every day have a weight, based on math
            weightManager.weights.forEach {
                let daysAgo = Date.daysBetween(date1: $0.date, date2: Date())!
                calorieManager.days[daysAgo]?.weight = $0.weight
            }
            
            // Set self values
            DispatchQueue.main.async { [self] in
                self.days = calorieManager.days
                self.hasLoaded = true
                self.realisticWeights = realisticWeights
            }
            
            // Post the last thirty days. Larger amounts seem to be too much for the network.
            if calorieManager.days.count > 30 {
                let daysToRetrieve = 31
                let model = getDaysModel(from: calorieManager.days.filter { $0.key <= daysToRetrieve }, activeCalorieModifier: Settings.get(key: .activeCalorieModifier) as? Double ?? 1)
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
    
    func setValuesFromNetworkWithDays(reloadToday: Bool = false) async {
        guard let getResponse = await network.getResponseWithDays() else { return }
        var days: Days = [:]
        for day in getResponse.days {
            days[day.daysAgo] = day
        }
        
        // Get weights
        let weights: [Weight] = Array(days.values).map { Weight(weight: $0.weight, date: $0.date) }.filter { $0.weight != 0.0}
        self.weightManager.weights = weights
        
        // Get expected weights
        let expectedWeights = Array(days.values).map { LineGraph.DateAndDouble(date: $0.date, double: $0.expectedWeight)}
        calorieManager.expectedWeights = expectedWeights
        
        if reloadToday {
            await calorieManager.setup(overrideMinimumRestingCalories:getResponse.minimumRestingCalories, shouldGetDays: false, startingWeight: weightManager.startingWeight, fitness: weightManager, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false)
            var today = await calorieManager.getDays(forPastDays: 0)[0]!
            let diff = today.activeCalories - today.activeCalories * getResponse.activeCalorieModifier
            today.activeCalories = today.activeCalories * getResponse.activeCalorieModifier
            today.deficit = today.deficit - diff
            today.runningTotalDeficit = days[1]!.runningTotalDeficit + today.deficit
            print("today: \(today)")
            days[0]! = today
        }
        let _ = await calorieManager.setValues(from: days)
        // Set self values
        setDaysAndFinish(days: days)
    }
    
    func setDaysAndFinish(days: [Int: Day]) {
        // Set self values
        DispatchQueue.main.async { [self] in
            self.days = days
            self.hasLoaded = true
        }
    }
    
    //MARK: REALISTIC WEIGHTS
    /**
     Return a dictionary of realistic weights, with index 0 being today and x being x days ago. These weights represent a smoothed out version of the real weights, so large weight changes based on water or something are less impactful.
     
     Start on first weight
     
     Loop through each subsequent day, finding expected weight loss
     
     Find next weight's actual loss
     
     Set the realistic weight loss to: 0.2 pounds, unless the expected weight loss is greater, or the actual loss is smaller
     */
    func createRealisticWeights() -> [Int: Double] {
        guard let firstWeight = weightManager.weights.last else { return [:] }
        let maximumWeightChangePerDay = 0.2
        var realisticWeights: [Int: Double] = [:]
        
        for i in stride(from: calorieManager.days.count-1, through: 0, by: -1) {
            let day = calorieManager.days[i]!
            
            guard
                let nextWeight = weightManager.weights.last(where: { Date.startOfDay($0.date) > day.date }),
                day.date >= Date.startOfDay(firstWeight.date)
            else {
                return realisticWeights
            }

            let onFirstDay = i == calorieManager.days.count - 1
            if onFirstDay {
                realisticWeights[i] = firstWeight.weight
            } else {
                let dayDifferenceBetweenNowAndNextWeight = Double(Date.daysBetween(date1: day.date, date2: Date.startOfDay(nextWeight.date))!)
                let realWeightDifference = (nextWeight.weight - realisticWeights[i+1]!) / dayDifferenceBetweenNowAndNextWeight
                var adjustedWeightDifference = realWeightDifference

                if adjustedWeightDifference < -maximumWeightChangePerDay  {
                    adjustedWeightDifference = min(-maximumWeightChangePerDay, day.expectedWeightChangedBasedOnDeficit)
                }
                if adjustedWeightDifference > maximumWeightChangePerDay {
                    adjustedWeightDifference = max(maximumWeightChangePerDay, day.expectedWeightChangedBasedOnDeficit)
                }
                
                realisticWeights[i] = realisticWeights[i+1]! + adjustedWeightDifference
            }
        }
        return realisticWeights
    }
    
    //MARK: MISC
    
    func getDaysModel(from days: [Int: Day], activeCalorieModifier: Double) -> HealthDataPostRequestModelWithDays {
        let d: [Day] = Array(days.values)
        return HealthDataPostRequestModelWithDays(days: d, activeCalorieModifier: activeCalorieModifier, minimumRestingCalories: Settings.get(key: .resting) as? Double ?? 2150)
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
    var minimumRestingCalories: Double = 2100
}

struct HealthDataGetRequestModelWithDays: Codable {
    let id: String
    let days: [Day]
    let createdAt: String
    let activeCalorieModifier: Double
    let minimumRestingCalories: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case days, createdAt, activeCalorieModifier, minimumRestingCalories
    }
}
