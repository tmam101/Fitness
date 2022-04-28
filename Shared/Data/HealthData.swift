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
    let dailyActiveCalories: [String: Double]
    let averageDeficitSinceStart, projectedAverageWeeklyDeficitForTomorrow, averageDeficitThisWeek: Double
    let percentWeeklyDeficit: Int
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
        case dailyActiveCalories, averageDeficitSinceStart, projectedAverageWeeklyDeficitForTomorrow, averageDeficitThisWeek, percentWeeklyDeficit, deficitsThisWeek, projectedAverageMonthlyDeficitTomorrow, deficitToGetCorrectDeficit, percentDailyDeficit, deficitToday, projectedAverageTotalDeficitForTomorrow, averageDeficitThisMonth, individualStatistics, runs, numberOfRuns, activeCalorieModifier, expectedWeights, weights
    }
}

struct HealthDataPostRequestModelWithDays: Codable {
    var days: [Int: Day] = [:]
}

// MARK: - DataToReceive
struct HealthDataGetRequestModelWithDays: Codable {
    let id: String
    let days: [String: DayModel] //TODO: Try this
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case days, createdAt
    }
}

// MARK: - Day
struct DayModel: Codable {
    let restingCalories, deficit, expectedWeight: Double
    let date: Int
    let activeCalories, consumedCalories, runningTotalDeficit: Double
}

//TODO: Should I make this @MainActor? It would resolve some async issues, like dispatch.
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
    
    init() {
        
    }
    
    init(model: HealthDataPostRequestModel) {
        self.setValues(from: model)
    }
    
    init(environment: AppEnvironmentConfig, _ completion: @escaping ((_ health: HealthData) -> Void)) {
        Task {
            self.environment = environment
            switch environment {
            case .release:
                if let start = Settings.get(key: .startDate) as? String {
                    startDateString = start
                }
                await setValues(forceLoad: true, completion)
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
    
    private func setRuns(_ runs: [Run]) async {
        return await withUnsafeContinuation { continuation in
            DispatchQueue.main.async { [self] in
                self.runs = runs
                continuation.resume()
            }
        }
    }
    
    /// Set all values of health data critifal for the app. Returns a reference to itself.
    func setValues(forceLoad: Bool = false, _ completion: ((_ health: HealthData) -> Void)?) async {
        hasLoaded = false
        setupDates()
#if os(iOS)
        
        let _ = await getValuesFromSettings()
        
        // Fitness
        await fitness.getAllStats()
        
        // Runs
        let runManager = RunManager(fitness: self.fitness, startDate: self.startDate ?? Date())
        let runs = await runManager.getRunningWorkouts()
        await setRuns(runs)
        
        // Calories
        let calorieManager = CalorieManager()
        self.calorieManager = calorieManager
        
        await calorieManager.setup(fitness: self.fitness, daysBetweenStartAndNow: self.daysBetweenStartAndNow, forceLoad: forceLoad)
        // Workouts
        await self.setWorkouts(WorkoutInformation(afterDate: self.startDate ?? Date(), environment: environment ?? .release))
        
        // Gather all information from calorie manager
        
        // If we've saved all days' info today, only reload today's data
        var days = self.getDaysFromSettings() ?? [:]
        let haveLoadedDaysToday = Date.sameDay(date1: Date(), date2: days[0]?.date ?? Date.distantPast)
        if haveLoadedDaysToday && days.count > 5 {
//            self.days = days TODO: need to save days?
//            var today = await calorieManager.getIndividualStatistics(forPastDays: 0)
//            let d = (days[1]?.runningTotalDeficit ?? 0) + (today[0]?.deficit ?? 0)
//            today[0]?.runningTotalDeficit = d
//            days[0] = today[0]
            
            // Reload this week's calories
            var thisWeek = await calorieManager.getIndividualStatistics(forPastDays: 7)
            let earliestDeficit = (days[8]?.runningTotalDeficit ?? 0) + (thisWeek[7]?.deficit ?? 0)
            thisWeek[7]?.runningTotalDeficit = earliestDeficit
            for i in stride(from: 6, through: 0, by: -1) {
                let deficit = (thisWeek[i+1]?.runningTotalDeficit ?? 0) + (thisWeek[i]?.deficit ?? 0)
                thisWeek[i]?.runningTotalDeficit = deficit
            }
            for i in 0...7 {
                days[i] = thisWeek[i]
            }
        } else {
            days = await calorieManager.getEveryDay()
        }
        
        if await self.setValues(from: days) {
//            let dataToSend = self.getModel()
            let dataToSend = self.getDaysModel(from: days)
            let n = Network()
            let r = await n.post(object: dataToSend)
//            self.setValuesToSettings(model: dataToSend)
            self.setDaysToSettings(days: days)
        }
        
#endif
#if os(watchOS)
        // On watch, receive relevant data
        await setValuesFromNetworkWithDays()
        self.hasLoaded = true
        completion?(self)
#endif
#if os(macOS)
        // On watch, receive relevant data
        await setValuesFromNetwork()
        self.hasLoaded = true
        completion?(self)
#endif
    }
    
    func setValuesFromNetworkWithDays() async {
        let network = Network()
        guard let getResponse = await network.getResponseWithDays() else { return }
        print("get response \(getResponse)")
    }
    
    func getDaysModel(from days: [Int: Day]) -> HealthDataPostRequestModelWithDays {
//        let lastFiftyDays = days.filter { $0.key < 8 }
        return HealthDataPostRequestModelWithDays(days: days)
    }
    
    func getModel() -> HealthDataPostRequestModel {
        return HealthDataPostRequestModel(
            deficitToday: self.deficitToday,
            averageDeficitThisWeek: self.averageDeficitThisWeek,
            averageDeficitThisMonth: self.averageDeficitThisMonth,
            projectedAverageMonthlyDeficitTomorrow: self.projectedAverageMonthlyDeficitTomorrow,
            averageDeficitSinceStart: self.averageDeficitSinceStart,
            deficitToGetCorrectDeficit: self.deficitToGetCorrectDeficit,
            percentWeeklyDeficit: self.percentWeeklyDeficit,
            percentDailyDeficit: self.percentDailyDeficit,
            projectedAverageWeeklyDeficitForTomorrow: self.projectedAverageWeeklyDeficitForTomorrow,
            projectedAverageTotalDeficitForTomorrow: self.projectedAverageTotalDeficitForTomorrow,
            deficitsThisWeek: self.deficitsThisWeek,
            dailyActiveCalories: self.dailyActiveCalories,
            individualStatistics: self.individualStatistics,
            runs: self.runs,
            numberOfRuns: self.numberOfRuns,
            activeCalorieModifier: self.activeCalorieModifier,
            expectedWeights: self.expectedWeights,
            weights: fitness.weights
        )
    }
    
    private func getValuesFromSettings() async -> Bool {
        if let data = Settings.get(key: .healthData) as? Data {
            do {
                let unencoded = try JSONDecoder().decode(HealthDataPostRequestModel.self, from: data)
                setValues(from: unencoded)
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    private func setValuesToSettings(model: HealthDataPostRequestModel) {
        do {
            let encodedData = try JSONEncoder().encode(model)
            Settings.set(key: .healthData, value: encodedData)
        } catch { }
    }
    
    private func setDaysToSettings(days: [Int:Day]) {
        do {
            let encodedData = try JSONEncoder().encode(days)
            Settings.set(key: .days, value: encodedData)
        } catch {
            print("error setDaysToSettings")
        }
    }
    
    private func getDaysFromSettings() -> [Int:Day]? {
        if let data = Settings.get(key: .days) as? Data {
            do {
                let unencoded = try JSONDecoder().decode([Int:Day].self, from: data)
                return unencoded
            } catch {
                print("error getDaysFromSettings")
                return nil
            }
        }
        return nil
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
            let expectedWeights = Array(days.values).map { LineGraph.DateAndDouble(date: Date.subtract(days: -1, from: $0.date), double: fitness.startingWeight - (($0.runningTotalDeficit ?? 0) / 3500)) }.sorted { $0.date < $1.date }
            DispatchQueue.main.async { [self] in
                self.deficitsThisWeek = deficitsThisWeek
                self.dailyActiveCalories = dailyActiveCalories
                self.deficitToday = deficitToday
                self.deficitToGetCorrectDeficit = 1000 //todo
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
    
    private func setValuesFromNetwork() async {
        let network = Network()
        guard let getResponse = await network.getResponse() else { return }
//        let activeToday = await calorieManager?.getIndividualStatistics(forPastDays: 0)
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
//                self.expectedWeightLossSinceStart = getResponse.expectedWeightLossSinceStart
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
//        self.dateSaved = model.dateSaved
//        self.days = model.days
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
//        self.expectedWeightLossSinceStart = model.expectedWeightLossSinceStart
//        self.daysBetweenStartAndNow = model.daysBetweenStartAndNow // todo we probably shouldnt be saving this
        self.deficitsThisWeek = model.deficitsThisWeek
        self.dailyActiveCalories = model.dailyActiveCalories
        self.individualStatistics = model.individualStatistics
        self.runs = model.runs
        self.numberOfRuns = model.numberOfRuns
        self.activeCalorieModifier = model.activeCalorieModifier
        self.expectedWeights = model.expectedWeights
        self.fitness.weights = model.weights
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
//        expectedWeightLossSinceStart = 0
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
