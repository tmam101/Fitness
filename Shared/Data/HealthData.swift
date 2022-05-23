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
    private var calorieManager: CalorieManager?
    private let network = Network()
#endif
    @Published public var fitness = FitnessCalculations()
    
    // Deficits
//    @State var watchConnectivityIphone = WatchConnectivityIphone()

    @Published public var days: [Int:Day] = [:]
    @Published public var deficitToday: Double = 0
    @Published public var averageDeficitThisWeek: Double = 0
    @Published public var averageDeficitThisMonth: Double = 0
    @Published public var projectedAverageMonthlyDeficitTomorrow: Double = 0
    @Published public var averageDeficitSinceStart: Double = 0
    @Published public var deficitToGetCorrectDeficit: Double = 0
    @Published public var percentWeeklyDeficit: Int = 0
    @Published public var percentDailyDeficit: Int = 0
    @Published public var projectedAverageWeeklyDeficitForTomorrow: Double = 0
    @Published public var projectedAverageTotalDeficitForTomorrow: Double = 0
    @Published public var deficitsThisWeek: [Int:Double] = [:]
    @Published public var dailyActiveCalories: [Int:Double] = [:]
    
    @Published public var individualStatistics: [Int:Day] = [:]
    
    // Days
    @Published public var daysBetweenStartAndNow: Int = 350
    @Published public var dateSaved: Date = Date.distantPast
    
    // Workouts
    @Published public var workouts: WorkoutInformation = WorkoutInformation(afterDate: "01.23.2021", environment: .debug)
    
    // Runs
    @Published public var runs: [Run] = []
    @Published public var numberOfRuns: Int = Settings.get(key: .numberOfRuns) as? Int ?? 0
    
    @Published public var hasLoaded: Bool = false
    @Published public var expectedWeights: [LineGraph.DateAndDouble] = []
    
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
            self.environment = environment
            self.startDateString = Settings.get(key: .startDate) as? String ?? self.startDateString
            await setValues(forceLoad: true, completion: nil)
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
            await fitness.getAllStats()
            let runManager = RunManager(fitness: self.fitness, startDate: self.startDate ?? Date())
            let runs = await runManager.getRunningWorkouts()
            await setRuns(runs)
            let calorieManager = CalorieManager()
            self.calorieManager = calorieManager
            await calorieManager.setup(goalDeficit: goalDeficit, fitness: self.fitness, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false)
            await self.setWorkouts(WorkoutInformation(afterDate: self.startDate ?? Date(), environment: environment ?? .release))
            let days = await calorieManager.getDays()
            guard !days.isEmpty else {
                completion?(self)
                return
            }
            
            //TODO: Finish creating realisticWeights
            // Start on first weight
            // Loop through each subsequent day, finding expected weight loss
            // Find next weight's actual loss
            // Set the realistic weight loss to: half a pound, unless the expected weight loss is greater, or the actual loss is smaller
            var realisticWeights: [Int: Double] = [:]
            var currentWeight = fitness.weights.first
            
            for i in stride(from: days.count - 1, through: 0, by: -1) {
                abc(i, days)
            }
            
            if await self.setValues(from: days) {
                // Post the last thirty days. Larger amounts seem to be too much for the network.
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
    
    func abc(_ i: Int, _ days: [Int:Day]) {
        let day = days[i]!
        let date = day.date
        let nextWeight = fitness.weights.last(where: { $0.date < date })
        let nextWeightDate = Date.startOfDay(nextWeight?.date ?? Date())
        if date < Date.startOfDay(fitness.weights.last!.date) {
            return
        }
        let expectedWeightLoss = day.deficit / 3500
        if i == days.count - 1 {
//                    realisticWeights[i] = fitness.weights
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
            await calorieManager.setup(goalDeficit: goalDeficit, fitness: self.fitness, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: false)
            var today = await calorieManager.getDays(forPastDays: 0)[0]!
            let diff = today.activeCalories - today.activeCalories * getResponse.activeCalorieModifier
            today.activeCalories = today.activeCalories * getResponse.activeCalorieModifier
            today.deficit = today.deficit - diff
            today.runningTotalDeficit = days[1]!.runningTotalDeficit + today.deficit
            print("today: \(today)")
            days[0]! = today
        }
        let _ = await setValues(from: days)
    }
    
    func getDaysModel(from days: [Int: Day], activeCalorieModifier: Double) -> HealthDataPostRequestModelWithDays {
        let d: [Day] = Array(days.values)
        return HealthDataPostRequestModelWithDays(days: d, activeCalorieModifier: activeCalorieModifier)
    }
    
    func setValues(from days: [Int: Day]) async -> Bool {
        return await withUnsafeContinuation { continuation in
            if days.count < 30 { continuation.resume(returning: false) }
            let averageDeficitSinceStart = (days[0]?.runningTotalDeficit ?? 0) / Double(daysBetweenStartAndNow)
            let projectedAverageWeeklyDeficitForTomorrow = ((days[0]?.runningTotalDeficit ?? 0) - (days[7]?.runningTotalDeficit ?? 0)) / 7
            let averageDeficitThisWeek = ((days[1]?.runningTotalDeficit ?? 0) - (days[8]?.runningTotalDeficit ?? 0)) / 7
            let averageDeficitThisMonth = ((days[1]?.runningTotalDeficit ?? 0) - (days[31]?.runningTotalDeficit ?? 0)) / 30
            let projectedAverageMonthlyDeficitForTomorrow = ((days[0]?.runningTotalDeficit ?? 0) - (days[30]?.runningTotalDeficit ?? 0)) / 30
            let deficitToday = days[0]?.deficit ?? 0
            let daysThisWeek = days.filter { $0.key < 8 }
            let deficitsThisWeek = daysThisWeek.mapValues{ $0.deficit }
            let dailyActiveCalories = daysThisWeek.mapValues{ $0.activeCalories }
            let individualStatistics = daysThisWeek
            let percentWeeklyDeficit = Int((averageDeficitThisWeek / goalDeficit) * 100)
            let expectedWeights = Array(days.values).map { LineGraph.DateAndDouble(date: Date.subtract(days: -1, from: $0.date), double: fitness.startingWeight - ($0.runningTotalDeficit / 3500)) }.sorted { $0.date < $1.date }
            DispatchQueue.main.async { [self] in
                self.deficitsThisWeek = deficitsThisWeek
                self.dailyActiveCalories = dailyActiveCalories
                self.deficitToday = deficitToday
                self.deficitToGetCorrectDeficit = self.goalDeficit //todo
                self.days = days
                self.averageDeficitThisWeek = averageDeficitThisWeek
                self.percentWeeklyDeficit = percentWeeklyDeficit
                self.averageDeficitThisMonth = averageDeficitThisMonth
                self.percentDailyDeficit = percentDailyDeficit
                self.projectedAverageWeeklyDeficitForTomorrow = projectedAverageWeeklyDeficitForTomorrow
                self.averageDeficitSinceStart = averageDeficitSinceStart
                self.projectedAverageMonthlyDeficitTomorrow = projectedAverageMonthlyDeficitForTomorrow
                self.individualStatistics = individualStatistics
                self.runs = runs
                self.expectedWeights = expectedWeights
                self.hasLoaded = true //todo want this?
                continuation.resume(returning: true)
            }
        }
    }
    
    private func setWorkouts(_ workouts: WorkoutInformation) async {
        return await withUnsafeContinuation { continuation in
            DispatchQueue.main.async { [self] in
                self.workouts = workouts
                continuation.resume()
            }
        }
    }
    
    private func setRuns(_ runs: [Run]) async {
        return await withUnsafeContinuation { continuation in
            DispatchQueue.main.async { [self] in
                self.runs = runs
                continuation.resume()
            }
        }
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
