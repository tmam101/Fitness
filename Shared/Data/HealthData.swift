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
    @Published var environment: AppEnvironmentConfig
#if !os(macOS)
    @Published var calorieManager: CalorieManager
#endif
    @Published public var weightManager: WeightManager
    
    @Published public var days: Days = [:]
    @Published public var daysBetweenStartAndNow: Int? = 350 // TODO needed?
    @Published public var hasLoaded: Bool = false
    @Published public var realisticWeights: [Int: Double] = [:]
    @Published public var weights: [Double] = []
    
    // Constants
    var startDate: Date?
    
    //MARK: INIT
    
    init(environment: AppEnvironmentConfig) {
        self.environment = environment
        self.weightManager = WeightManager(environment: environment)
        self.calorieManager = CalorieManager(environment: environment)
        Task {
            if await authorizeHealthKit() {
                setupDates(environment: environment)
                // Use test case if available
                if environment.testCase != nil {
                    let days = Days.testDays(options: environment)
                    self.days = days
                    return
                }
                await setValues(forceLoad: true, completion: nil)
            }
        }
    }
    
    static func getToday(environment: AppEnvironmentConfig) async -> Day {
        let weightManager = WeightManager(environment: environment)
        let calorieManager = CalorieManager(environment: environment)
        await weightManager.setup()
        await calorieManager.setup(startingWeight: weightManager.startingWeight, weightManager: weightManager, daysBetweenStartAndNow: 0, forceLoad: false) // TODO this shouldnt always be
        let today = await calorieManager.getDays(forPastDays: 0)[0]!
        today.weight = weightManager.currentWeight
        return today
    }
        
    init(environment: AppEnvironmentConfig, shouldSetValues: Bool = true, _ completion: @escaping ((_ health: HealthData) -> Void)) {
        self.weightManager = WeightManager(environment: environment)
        self.calorieManager = CalorieManager(environment: environment)
        self.environment = environment
        Task {
            if await authorizeHealthKit() { // TODO necessary?
                setupDates(environment: environment)
                // Use test case if available
                if environment.testCase != nil {
                    let days = Days.testDays(options: environment)
                    self.days = days
                    completion(self)
                }
                if shouldSetValues {
                    await setValues(forceLoad: true, completion: completion)
                }
                completion(self)
            }
        }
    }
    
    //MARK: SET VALUES
    
    @MainActor
    static public func setValues(environment: AppEnvironmentConfig, forceLoad: Bool = false, haveAlreadyRetried: Bool = false) async -> HealthData {
        let health = await withCheckedContinuation { continuation in
            _ = HealthData(environment: environment, shouldSetValues: false) { health in
                continuation.resume(returning: health)
            }
        }
        // Use test case if available
        if environment.testCase != nil {
            let days = Days.testDays(options: environment)
            health.days = days
            return health
        }
        await health.setValues(forceLoad: true, completion: nil)
        return health
    }
    
    /// Set all values of health data critifal for the app. Returns a reference to itself.
    @MainActor
    func setValues(forceLoad: Bool = false, haveAlreadyRetried: Bool = false, completion: ((_ health: HealthData) -> Void)?) async {
        hasLoaded = false
#if os(iOS)
        // Setup managers
        await weightManager.setup(startDate: self.startDate)
        await calorieManager.setup(startingWeight: weightManager.startingWeight, weightManager: weightManager, daysBetweenStartAndNow: self.daysBetweenStartAndNow ?? 0, forceLoad: false)
        
        guard !calorieManager.days.isEmpty else {
            completion?(self)
            return
        }
        
        // Set real weights on days
        weightManager.weightsAfterStartDate.forEach {
            let daysAgo = Date.daysBetween(date1: $0.date, date2: Date())!
            calorieManager.days[daysAgo]?.weight = $0.weight
        }
        calorieManager.days.oldestDay?.weight = weightManager.startingWeight
        // Set self values
        self.days = calorieManager.days
        print("JSON of days dictionary: \n")
        print(days.encodeAsString())
        days.formatAccordingTo(options: environment)
        self.hasLoaded = true
        completion?(self)
            
#endif
#if os(watchOS)
            // On watch, receive relevant data
            //            await setValuesFromNetworkWithDays(reloadToday: true)
            //            self.hasLoaded = true
//            await setValuesLocally()
            completion?(self)
#endif
#if os(macOS)
            // On watch, receive relevant data
            await setValuesFromNetwork()
            self.hasLoaded = true
            completion?(self)
#endif
        }
    
#if  !os(macOS)
    func saveCaloriesEaten(calories: Double) async -> Bool {
        //        guard let calorieManager = self.calorieManager else { return false }
        let r = await CalorieManager(environment: environment).saveCaloriesEaten(calories: Decimal(calories))
        return r
    }
#endif
    
    private func setupDates(environment: AppEnvironmentConfig) {
        // Use the environment's start date if we have it
        if let startDate = environment.startDate {
            self.startDate = startDate
            self.daysBetweenStartAndNow = Date.daysBetween(date1: startDate, date2: Date())
            return
        }
        // Otherwise use settings
        guard let startDateString = Settings.get(key: .startDate) as? String,
              let startDate = Date.dateFromString(startDateString),
              let daysBetweenStartAndNow = Date.daysBetween(date1: startDate, date2: Date())
        else { return }
        
        self.startDate = startDate
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
    }
    
    private func setupDates(startDate: Date?) {
        guard let startDate,
              let daysBetweenStartAndNow = Date.daysBetween(date1: startDate, date2: Date())
        else { return }
        
        self.startDate = startDate
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
    }
    
    // TODO this is running during unit tests
    private func authorizeHealthKit() async -> Bool {
        // TODO add a check for if its xctest?
        if !HKHealthStore.isHealthDataAvailable() { return false }
        
        let readDataTypes: Swift.Set<HKSampleType> = [
            HKSampleType.quantityType(forIdentifier: .bodyMass)!,
            HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKSampleType.quantityType(forIdentifier: .dietaryProtein)!,
            HKSampleType.workoutType(),
            HKSampleType.quantityType(forIdentifier: .heartRate)!,
            HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!]
        let writeDataTypes: Swift.Set<HKSampleType> = [
            HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        ]
        
        do {
            let status = try await HKHealthStore().statusForAuthorizationRequest(toShare: writeDataTypes, read: readDataTypes)
            switch status {
            case .unknown, .unnecessary:
                return true
            case .shouldRequest:
                try await HKHealthStore().requestAuthorization(toShare: writeDataTypes, read: readDataTypes)
                return true
            @unknown default:
                return true
            }
        } catch {
            return false
        }
    }
}
