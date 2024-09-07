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
    @Published var environment: AppEnvironmentConfig = .debug(nil)
#if !os(macOS)
    @Published var calorieManager: CalorieManager = CalorieManager()
//    @Published var runManager: RunManager = RunManager()
    private let network = Network()
#endif
    @Published public var weightManager: WeightManager
    @Published public var workoutManager: WorkoutManager = WorkoutManager()
    
    @Published public var days: Days = [:]
    @Published public var daysBetweenStartAndNow: Int = 350 // TODO needed?
    @Published public var hasLoaded: Bool = false
    @Published public var realisticWeights: [Int: Double] = [:]
    @Published public var weights: [Double] = []
    
    // Constants
    var startDate: Date?
    
    //MARK: INIT
    
    init(environment: AppEnvironmentConfig) {
        self.weightManager = WeightManager(environment: environment)
        Task {
            if await authorizeHealthKit() {
                self.environment = environment
                self.startDateString = Settings.get(key: .startDate) as? String ?? self.startDateString
                await setValues(forceLoad: true, completion: nil)
            }
        }
    }
    
    static func getToday() async -> Day {
        let weightManager = WeightManager()
        let calorieManager = CalorieManager()
        await weightManager.setup()
        await calorieManager.setup(startingWeight: weightManager.startingWeight, weightManager: weightManager, daysBetweenStartAndNow: 0, forceLoad: false, environment: .release(options: nil, weightProcessor: nil)) // TODO this shouldnt always be
        var today = await calorieManager.getDays(forPastDays: 0)[0]!
        today.weight = weightManager.currentWeight
        return today
    }
    
//    init() { }
    
    init(environment: AppEnvironmentConfig, shouldSetValues: Bool = true, _ completion: @escaping ((_ health: HealthData) -> Void)) {
        self.weightManager = WeightManager(environment: environment)
        Task {
            if await authorizeHealthKit() { // TODO necessary?
                self.environment = environment
                self.startDateString = Settings.get(key: .startDate) as? String ?? self.startDateString
                if shouldSetValues {
                    await setValues(forceLoad: true, completion: completion)
                }
                completion(self)
            }
        }
    }
    
    //MARK: SET VALUES
    
//    func load(forceLoad: Bool = false, haveAlreadyRetried: Bool = false) async -> Self {
//        await withCheckedContinuation { continuation in
//            setValues(completion: <#T##((HealthData) -> Void)?##((HealthData) -> Void)?##(_ health: HealthData) -> Void#>)
//        }
//    }
    
    @MainActor
    static public func setValues(environment: AppEnvironmentConfig, forceLoad: Bool = false, haveAlreadyRetried: Bool = false) async -> HealthData {
        let health = await withCheckedContinuation { continuation in
            _ = HealthData(environment: environment, shouldSetValues: false) { health in
//                await health.setValues(forceLoad: true, completion: nil)
                continuation.resume(returning: health)
            }
        }
        await health.setValues(forceLoad: true, completion: nil)
        return health
    }
    
    /// Set all values of health data critifal for the app. Returns a reference to itself.
    @MainActor
    func setValues(forceLoad: Bool = false, haveAlreadyRetried: Bool = false, completion: ((_ health: HealthData) -> Void)?) async {
        hasLoaded = false
        setupDates()
        
        switch self.environment {
        case .release(let options, let weightProcessor):
#if os(iOS)

            if let options {
                for option in options {
                    switch option {
                    case .startDate(let date):
                        
                    }
                }
            }
            // Setup managers
            await weightManager.setup(weightProcessor: weightProcessor)
            
            // Set start date to first recorded weight after the original start date
//            if let startDate = weightManager.weights.sorted(by: { x, y in x.date < y.date }).first?.date {
//                setupDates(startDate: startDate)
//            }
            
//            await runManager.setup(weightManager: weightManager, startDate: self.startDate ?? Date())
            await calorieManager.setup(startingWeight: weightManager.startingWeight, weightManager: weightManager, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false, environment: environment)
            //            await workoutManager.setup(afterDate: self.startDate ?? Date(), environment: environment)
            
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
            DispatchQueue.main.async { [self] in
                self.days = calorieManager.days
                print("JSON of days dictionary: \n")
                print(days.encodeAsString())
                days.formatAccordingTo(options: options)
                self.hasLoaded = true
//                self.realisticWeights = realisticWeights
            }
            
            // Post the last thirty days. Larger amounts seem to be too much for the network.
//            if calorieManager.days.count > 30 {
//                let daysToRetrieve = 31
//                let model = getDaysModel(from: calorieManager.days.filter { $0.key <= daysToRetrieve }, activeCalorieModifier: Settings.get(key: .activeCalorieModifier) as? Double ?? 1)
//                let response = await network.postWithDays(object: model)
//                if !haveAlreadyRetried {
//                    guard response == true else {
//                        await self.setValues(forceLoad: forceLoad, haveAlreadyRetried: true, completion: completion)
//                        return
//                    }
//                }
//            }
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
        case .debug(let options):
            //            await self.setValuesFromNetworkWithDays()
            self.days = Days.testDays(options: options)
//            self.days = Days.testDays(missingData: true, weightsOnEveryDay: true, dayCount: 15)

//            await calorieManager.setValues(from: self.days)
            completion?(self)
            self.hasLoaded = true
        case .widgetRelease:
//            await setValuesLocally()
            //            await setValuesFromNetworkWithDays(reloadToday: true)
            //            self.hasLoaded = true
            completion?(self)
        }
    }
    
    // TODO Refactor later
//    func setValuesLocally() async {
//        let minimumResting = Settings.get(key: .resting) as? Double ?? 2000
//        let minimumActive = Settings.get(key: .active) as? Double ?? 100
//        //        let activeCalorieModifier = Settings.get(key: .activeCalorieModifier) as? Double ?? 1.0
//        
//        await calorieManager.setup(overrideMinimumRestingCalories:minimumResting, overrideMinimumActiveCalories: minimumActive, shouldGetDays: false, startingWeight: 200, weightManager: weightManager, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false, environment: environment)
//        let days = await calorieManager.getDays(forPastDays: 40, dealWithWeights: false)
//        await setDaysAndFinish(days: days)
//    }
    
    // TODO Refactor later
//    func setValuesFromNetworkWithDays(reloadToday: Bool = false) async {
//        var days: Days = [:]
//        let haveLoadedFromNetworkToday = {
//            if let mostRecentDate = Settings.getDays()?[0]?.date {
//                return Date.daysBetween(date1: Date(), date2: mostRecentDate) == 0
//            }
//            return false
//        }()
//        
//        if !haveLoadedFromNetworkToday {
//            guard let getResponse = await network.getResponseWithDays() else { return } //TODO: Some sort of validation in here that we get something good
//            for day in getResponse.days {
//                days[day.daysAgo] = day
//            }
//            
//            // Get weights
//            let weights: [Weight] = Array(days.values).map { Weight(weight: $0.weight, date: $0.date) }.filter { $0.weight != 0.0}
//            self.weightManager.weights = weights
//            
//            // Get expected weights
//            let expectedWeights = Array(days.values).map { DateAndDouble(date: $0.date, double: $0.expectedWeight)}
//            calorieManager.expectedWeights = expectedWeights
//            
//            Settings.setDays(days: days)
//            Settings.set(key: .resting, value: getResponse.minimumRestingCalories)
//            Settings.set(key: .active, value: getResponse.minimumActiveCalories)
//            Settings.set(key: .activeCalorieModifier, value: getResponse.activeCalorieModifier)
//            
//            if reloadToday {
//                await calorieManager.setup(overrideMinimumRestingCalories:getResponse.minimumRestingCalories, overrideMinimumActiveCalories: getResponse.minimumActiveCalories, shouldGetDays: false, startingWeight: weightManager.startingWeight, weightManager: weightManager, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false, environment: environment)
//                var today = await calorieManager.getDays(forPastDays: 0)[0]!
//                //                let diff = today.activeCalories - today.activeCalories * getResponse.activeCalorieModifier
//                //                today.activeCalories = today.activeCalories * getResponse.activeCalorieModifier
//                //                today.deficit = today.deficit - diff
//                if let yesterday = days[1] {
//                    today.runningTotalDeficit = yesterday.runningTotalDeficit + today.deficit
//                }
//                print("today: \(today)")
//                days[0] = today
//            }
//            // Set self values
//            await setDaysAndFinish(days: days)
//        } else if reloadToday, let settingsDays = Settings.getDays() {
//            days = settingsDays
//            
//            // Get weights
//            let weights: [Weight] = Array(days.values).map { Weight(weight: $0.weight, date: $0.date) }.filter { $0.weight != 0.0}
//            self.weightManager.weights = weights
//            
//            // Get expected weights
//            let expectedWeights = Array(days.values).map { DateAndDouble(date: $0.date, double: $0.expectedWeight)}
//            calorieManager.expectedWeights = expectedWeights
//            
//            await calorieManager.setup(shouldGetDays: false, startingWeight: weightManager.startingWeight, weightManager: weightManager, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false, environment: environment)
//            var today = await calorieManager.getDays(forPastDays: 0)[0]!
//            //            let diff = today.activeCalories - today.activeCalories * (Settings.get(key: .activeCalorieModifier) as? Double ?? 1)
//            //            today.activeCalories = today.activeCalories * (Settings.get(key: .activeCalorieModifier) as? Double ?? 1)
//            //            today.deficit = today.deficit - diff
//            if let yesterday = days[1] {
//                today.runningTotalDeficit = yesterday.runningTotalDeficit + today.deficit
//            }
//            print("today: \(today)")
//            days[0] = today
//            await setDaysAndFinish(days: days)
//        }
//    }
    
    func setDaysAndFinish(days: [Int: Day]) async {
        // Set self values
        Task {
            // TODO
//            let _ = await calorieManager.setValues(from: days)
            self.days = days
            self.hasLoaded = true
        }
    }
    
    //MARK: MISC
    
    func getDaysModel(from days: [Int: Day], activeCalorieModifier: Double) -> HealthDataPostRequestModelWithDays {
        let d: [Day] = Array(days.values)
        return HealthDataPostRequestModelWithDays(days: d, activeCalorieModifier: activeCalorieModifier, minimumRestingCalories: Settings.get(key: .resting) as? Double ?? 2150, minimumActiveCalories: Settings.get(key: .active) as? Double ?? 100)
    }
    
#if  !os(macOS)
    func saveCaloriesEaten(calories: Double) async -> Bool {
        //        guard let calorieManager = self.calorieManager else { return false }
        let r = await CalorieManager().saveCaloriesEaten(calories: Decimal(calories))
        return r
    }
#endif
    
    private func setupDates(environment: AppEnvironmentConfig) {
        switch environment {
        case .release(options: let options, weightProcessor: let w):
            if let options {
                for option in options {
                    switch option {
                    case let .startDate(let date):
                        
                    }
                }
            }
        }
        guard let startDate = startDate ?? startString ?? Date.dateFromString(startDateString),
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

//MARK: NETWORK MODELS

struct HealthDataPostRequestModelWithDays: Codable {
    var days: [Day] = []
    var activeCalorieModifier: Double = 1
    var minimumRestingCalories: Double = 2100
    var minimumActiveCalories: Double = 100
}

struct HealthDataGetRequestModelWithDays: Codable {
    let id: String
    let days: [Day]
    let createdAt: String
    let activeCalorieModifier: Double
    let minimumRestingCalories: Double
    let minimumActiveCalories: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case days, createdAt, activeCalorieModifier, minimumRestingCalories, minimumActiveCalories
    }
}
