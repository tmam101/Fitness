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

// MARK: Network Models
struct HealthDataPostRequestModel: Codable {
    var deficitToday: Double = 0
    var averageDeficitThisWeek: Double = 0
    var averageDeficitThisMonth: Double = 0
    var projectedAverageMonthlyDeficitTomorrow: Double = 0
    var averageDeficitSinceStart: Double = 0
    var deficitToGetCorrectDeficit: Double = 0
    var percentWeeklyDeficit: Int = 0
    var percentDailyDeficit: Int = 0
    var projectedAverageWeeklyDeficitForTomorrow: Double = 0
    var projectedAverageTotalDeficitForTomorrow: Double = 0
    var expectedWeightLossSinceStart: Double = 0
    var daysBetweenStartAndNow: Int = 0
    var deficitsThisWeek: [Int:Double] = [:]
    var dailyActiveCalories: [Int:Double] = [:]
    var individualStatistics: [Int:Day] = [:]
    var runs: [Run] = []
    var numberOfRuns: Int = 0
    var activeCalorieModifier: Double = 0
    var expectedWeights: [LineGraph.DateAndDouble] = []
    var weights: [Weight] = []
}

struct HealthDataGetRequestModel: Codable {
    let id: String
    let daysBetweenStartAndNow: Int
    let dailyActiveCalories: [String: Double]
    let averageDeficitSinceStart, projectedAverageWeeklyDeficitForTomorrow, averageDeficitThisWeek: Double
    let percentWeeklyDeficit: Int
    let expectedWeightLossSinceStart: Double
    let deficitsThisWeek: [String: Double]
    let projectedAverageMonthlyDeficitTomorrow, deficitToGetCorrectDeficit: Double
    let percentDailyDeficit: Int
    let deficitToday, projectedAverageTotalDeficitForTomorrow, averageDeficitThisMonth: Double
    var individualStatistics: [String: Day]
    var runs: [Run]
    var numberOfRuns: Int
    var activeCalorieModifier: Double
    var expectedWeights: [LineGraph.DateAndDouble]
    var weights: [Weight]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case daysBetweenStartAndNow, dailyActiveCalories, averageDeficitSinceStart, projectedAverageWeeklyDeficitForTomorrow, averageDeficitThisWeek, percentWeeklyDeficit, expectedWeightLossSinceStart, deficitsThisWeek, projectedAverageMonthlyDeficitTomorrow, deficitToGetCorrectDeficit, percentDailyDeficit, deficitToday, projectedAverageTotalDeficitForTomorrow, averageDeficitThisMonth, individualStatistics, runs, numberOfRuns, activeCalorieModifier, expectedWeights, weights
    }
}

class HealthData: ObservableObject {
    
    //MARK: PROPERTIES
    var environment: AppEnvironmentConfig?
    #if !os(macOS)
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    private var calorieManager: CalorieManager?
    #endif
    @Published public var fitness = FitnessCalculations()
    
    // Deficits
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
    
    @Published public var expectedWeightLossSinceStart: Double = 0
    @Published public var individualStatistics: [Int:Day] = [:]

    // Days
    @Published public var daysBetweenStartAndNow: Int = 350
    
    // Workouts
    @Published public var workouts: WorkoutInformation = WorkoutInformation(afterDate: "01.23.2021", environment: .debug)
    
    // Active calorie modifier
    @Published public var activeCalorieModifier: Double = 1
    @Published public var adjustActiveCalorieModifier = true
    
    // Runs
    @Published public var runs: [Run] = []
    @Published public var numberOfRuns: Int = Settings.get(key: .numberOfRuns) as? Int ?? 0
        
    @Published public var hasLoaded: Bool = false
    @Published public var dataToSend: HealthDataPostRequestModel = HealthDataPostRequestModel()
    @Published public var expectedWeights: [LineGraph.DateAndDouble] = []
    
    // Constants
    let goalDeficit: Double = 1000
    let goalEaten: Double = 1500
    let caloriesInPound: Double = 3500
    var startDateString = "01.23.2021"
    var startDate: Date?
    let formatter = DateFormatter()
    
    //MARK: INITIALIZATION
    init(environment: AppEnvironmentConfig) {
        Task {
            self.environment = environment
            switch environment {
            case .release:
                if let start = Settings.get(key: .startDate) as? String {
                    startDateString = start
                }
                await setValues(forceLoad: true, nil)
            case .debug:
                await setValuesDebug(nil)
            }
        }
    }
    
    init(model: HealthDataPostRequestModel) {
        self.setValues(from: model)
    }
    
    init(environment: AppEnvironmentConfig, _ completion: @escaping ((_ health: HealthData) -> Void)) {
        Task {
            self.environment = environment
            switch environment {
            case .release:
                await setValues(completion)
            case .debug:
                await setValuesDebug(completion)
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
    
    /// Set all values of health data critifal for the app. Returns a reference to itself.
    func setValues(forceLoad: Bool = false, _ completion: ((_ health: HealthData) -> Void)?) async {
        hasLoaded = false
        setupDates()
#if os(iOS)
        await setValuesFromNetwork()
        // Fitness
        await fitness.getAllStats()
        // Runs
        let runManager = RunManager(fitness: self.fitness, startDate: self.startDate ?? Date())
        let runs = await runManager.getRunningWorkouts()
        // Calories
        let calorieManager = CalorieManager()
        self.calorieManager = calorieManager
        await calorieManager.setup(fitness: self.fitness, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: forceLoad)
        // Workouts
        await self.setWorkouts(WorkoutInformation(afterDate: self.startDate ?? Date(), environment: environment ?? .release))
        // Gather all information from calorie manager
        let averageDeficitSinceStart = await calorieManager.getAverageDeficit(forPast: self.daysBetweenStartAndNow) ?? 0
        let deficitToGetCorrectDeficit = await calorieManager.getDeficitToReachIdeal() ?? 0
        let projectedAverageWeeklyDeficitForTomorrow = await calorieManager.getProjectedAverageDeficitForTomorrow(forPast: 6) ?? 0
        let projectedAverageTotalDeficitForTomorrow = await calorieManager.getProjectedAverageDeficitForTomorrow(forPast: self.daysBetweenStartAndNow) ?? 0
        let averageDeficitThisWeek = await calorieManager.getAverageDeficit(forPast: 7) ?? 0
        let averageDeficitThisMonth = await calorieManager.getAverageDeficit(forPast: 30) ?? 0
        let projectedAverageMonthlyDeficitTomorrow = await calorieManager.getProjectedAverageDeficitForTomorrow(forPast: 30) ?? 0
        let deficitToday = await calorieManager.getAverageDeficit(forPast: 0) ?? 0
        let deficitsThisWeek = await calorieManager.getIndividualDeficits(forPastDays: 7)
        let dailyActiveCalories = await calorieManager.getIndividualActiveCalories(forPastDays: 7)
        let individualStatistics = await calorieManager.getIndividualStatistics(forPastDays: 7)
        let percentWeeklyDeficit = Int((averageDeficitThisWeek / goalDeficit) * 100)
        let percentDailyDeficit = Int((deficitToday / deficitToGetCorrectDeficit) * 100)
        let expectedWeightLossSinceStart = (averageDeficitSinceStart * Double(self.daysBetweenStartAndNow)) / Double(3500) //todo maybe dont use the average but the real
//        let statsEveryDay = await calorieManager.getIndividualDeficits(forPastDays: daysBetweenStartAndNow)
        let expectedWeights = await calorieManager.getExpectedWeights()
        
        //todo it looks like i can get active calories on the watch
        //TODO improve
        // Dont send or use data if its messed up
        if dailyActiveCalories.values.filter({ $0 != 0 }).isEmpty {
            completion?(self)
            return
        }
        // On iOS, send up the relevant data
        let dataToSend = HealthDataPostRequestModel(
            deficitToday: deficitToday,
            averageDeficitThisWeek: averageDeficitThisWeek,
            averageDeficitThisMonth: averageDeficitThisMonth,
            projectedAverageMonthlyDeficitTomorrow: projectedAverageMonthlyDeficitTomorrow,
            averageDeficitSinceStart: averageDeficitSinceStart,
            deficitToGetCorrectDeficit: deficitToGetCorrectDeficit,
            percentWeeklyDeficit: percentWeeklyDeficit,
            percentDailyDeficit: percentDailyDeficit,
            projectedAverageWeeklyDeficitForTomorrow: projectedAverageWeeklyDeficitForTomorrow,
            projectedAverageTotalDeficitForTomorrow: projectedAverageTotalDeficitForTomorrow,
            expectedWeightLossSinceStart: expectedWeightLossSinceStart,
            daysBetweenStartAndNow: daysBetweenStartAndNow,
            deficitsThisWeek: deficitsThisWeek,
            dailyActiveCalories: dailyActiveCalories,
            individualStatistics: individualStatistics,
            runs: runs,
            numberOfRuns: self.numberOfRuns,
            activeCalorieModifier: self.activeCalorieModifier,
            expectedWeights: expectedWeights,
            weights: fitness.weights)
        // if any expected weights are < 130, disregard?
        let n = Network()
        let _ = await n.post(object: dataToSend)
        
        // Set self values
        DispatchQueue.main.async { [self] in
            self.dataToSend = dataToSend
            self.deficitsThisWeek = deficitsThisWeek
            self.dailyActiveCalories = dailyActiveCalories
            self.deficitToday = deficitToday
            self.deficitToGetCorrectDeficit = deficitToGetCorrectDeficit
            self.averageDeficitThisWeek = averageDeficitThisWeek
            self.percentWeeklyDeficit = percentWeeklyDeficit
            self.averageDeficitThisMonth = averageDeficitThisMonth
            self.percentDailyDeficit = percentDailyDeficit
            self.projectedAverageWeeklyDeficitForTomorrow = projectedAverageWeeklyDeficitForTomorrow
            self.projectedAverageTotalDeficitForTomorrow = projectedAverageTotalDeficitForTomorrow
            self.averageDeficitSinceStart = averageDeficitSinceStart
            self.expectedWeightLossSinceStart = expectedWeightLossSinceStart
            self.projectedAverageMonthlyDeficitTomorrow = projectedAverageMonthlyDeficitTomorrow
            self.individualStatistics = individualStatistics
            self.runs = runs
            self.expectedWeights = expectedWeights
            self.hasLoaded = true
            completion?(self)
        }
#endif
#if os(watchOS)
        // On watch, receive relevant data
        await setValuesFromNetwork()
        completion?(self)
#endif
#if os(macOS)
        // On watch, receive relevant data
        await setValuesFromNetwork()
        completion?(self)
#endif
    }
    
    private func setValuesFromNetwork() async {
//        guard let calorieManager = self.calorieManager else {
//            return
//        }
        let network = Network()
        guard let getResponse = await network.getResponse() else { return }
//        let activeToday = await calorieManager.sumValueForDay(daysAgo: 0, forType: .activeEnergyBurned)
        return await withUnsafeContinuation { continuation in
            DispatchQueue.main.async { [self] in
                // Convert string keys to ints
                var deficitsThisWeekCorrected: [Int:Double] = [:]
                for kv in getResponse.deficitsThisWeek {
                    deficitsThisWeekCorrected[Int(kv.key) ?? 0] = kv.value
                }
                var dailyActiveCaloriesCorrected: [Int:Double] = [:]
                for kv in getResponse.dailyActiveCalories {
                    dailyActiveCaloriesCorrected[Int(kv.key) ?? 0] = kv.value
                }
//                // Try to calculate active calories on the watch
//                // Todo: don't think this works right
//                // I think I need to change this value on other things like deficitsThisWeek too
//                let activeBurnedToday = activeToday * getResponse.activeCalorieModifier
//                print("activeBurnedToday \(activeBurnedToday)")
//                print("activeCalorieModifier \(activeCalorieModifier)")
//                dailyActiveCaloriesCorrected[0] = activeToday * getResponse.activeCalorieModifier
                var individualStatisticsFixed: [Int:Day] = [:]
                for kv in getResponse.individualStatistics {
                    individualStatisticsFixed[Int(kv.key) ?? 0] = kv.value
                }
                
                self.deficitsThisWeek = deficitsThisWeekCorrected
                self.dailyActiveCalories = dailyActiveCaloriesCorrected
                self.deficitToday = getResponse.deficitToday
                self.deficitToGetCorrectDeficit = getResponse.deficitToGetCorrectDeficit
                self.averageDeficitThisWeek = getResponse.averageDeficitThisWeek
                self.percentWeeklyDeficit = getResponse.percentWeeklyDeficit
                self.averageDeficitThisMonth = getResponse.averageDeficitThisMonth
                self.percentDailyDeficit = getResponse.percentDailyDeficit
                self.projectedAverageWeeklyDeficitForTomorrow = getResponse.projectedAverageWeeklyDeficitForTomorrow
                self.projectedAverageTotalDeficitForTomorrow = getResponse.projectedAverageTotalDeficitForTomorrow
                self.averageDeficitSinceStart = getResponse.averageDeficitSinceStart
                self.expectedWeightLossSinceStart = getResponse.expectedWeightLossSinceStart
                self.projectedAverageMonthlyDeficitTomorrow = getResponse.projectedAverageMonthlyDeficitTomorrow
                self.individualStatistics = individualStatisticsFixed
                self.runs = getResponse.runs
                self.numberOfRuns = getResponse.numberOfRuns
                self.activeCalorieModifier = getResponse.activeCalorieModifier
                self.expectedWeights = getResponse.expectedWeights
                self.fitness.weights = getResponse.weights
                continuation.resume()
            }
        }
    }
    
    func setValuesDebug(_ completion: ((_ health: HealthData) -> Void)?) async {
        await setValuesFromNetwork()
        completion?(self)
    }
    
    // need a way to await this
    func setValues(from model: HealthDataPostRequestModel) {
        self.deficitToday = model.deficitToday
        self.averageDeficitThisWeek = model.averageDeficitThisWeek
        self.averageDeficitThisMonth = model.averageDeficitThisMonth
        self.projectedAverageMonthlyDeficitTomorrow = model.projectedAverageMonthlyDeficitTomorrow
        self.averageDeficitSinceStart = model.averageDeficitSinceStart
        self.deficitToGetCorrectDeficit = model.deficitToGetCorrectDeficit
        self.percentWeeklyDeficit = model.percentWeeklyDeficit
        self.percentDailyDeficit = model.percentDailyDeficit
        self.projectedAverageWeeklyDeficitForTomorrow = model.projectedAverageWeeklyDeficitForTomorrow
        self.projectedAverageTotalDeficitForTomorrow = model.projectedAverageTotalDeficitForTomorrow
        self.expectedWeightLossSinceStart = model.expectedWeightLossSinceStart
        self.daysBetweenStartAndNow = model.daysBetweenStartAndNow
        self.deficitsThisWeek = model.deficitsThisWeek
        self.dailyActiveCalories = model.dailyActiveCalories
        self.individualStatistics = model.individualStatistics
        self.runs = model.runs
        self.numberOfRuns = model.numberOfRuns
        self.activeCalorieModifier = model.activeCalorieModifier
    }
    
    func eraseValues() {
        deficitToday = 0
        averageDeficitThisWeek = 0
        averageDeficitThisMonth = 0
        projectedAverageMonthlyDeficitTomorrow = 0
        averageDeficitSinceStart = 0
        deficitToGetCorrectDeficit = 0
        percentWeeklyDeficit = 0
        percentDailyDeficit = 0
        projectedAverageWeeklyDeficitForTomorrow = 0
        projectedAverageTotalDeficitForTomorrow = 0
        expectedWeightLossSinceStart = 0
        daysBetweenStartAndNow = 0
        deficitsThisWeek = [:]
        dailyActiveCalories = [:]
        individualStatistics = [:]
        runs = []
        numberOfRuns = 0
        activeCalorieModifier = 0
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
