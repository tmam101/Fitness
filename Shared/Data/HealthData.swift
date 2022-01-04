//
//  MyHealthKit.swift
//  Fitness
//
//  Created by Thomas Goss on 1/26/21.
//

import Foundation
import HealthKit
#if !os(watchOS)
import WidgetKit
#endif
import SwiftUI
import WatchConnectivity
//import WatchConnectivity

struct DataToSend: Codable {
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
    var daysBetweenStartAndEnd: Int = 0
    var daysBetweenStartAndNow: Int = 0
    var daysBetweenNowAndEnd: Int = 0
    var deficitsThisWeek: [Int:Double] = [:]
    var dailyActiveCalories: [Int:Double] = [:]
    var individualStatistics: [Int:Day] = [:]
    var runs: [Run] = []
    var numberOfRuns: Int = 0
}

// MARK: - DataToReceive
struct DataToReceive: Codable {
    let id: String
    let daysBetweenStartAndNow: Int
    let dailyActiveCalories: [String: Double]
    let averageDeficitSinceStart, projectedAverageWeeklyDeficitForTomorrow, averageDeficitThisWeek: Double
    let daysBetweenStartAndEnd, daysBetweenNowAndEnd, percentWeeklyDeficit: Int
    let expectedWeightLossSinceStart: Double
    let deficitsThisWeek: [String: Double]
    let projectedAverageMonthlyDeficitTomorrow, deficitToGetCorrectDeficit: Double
    let percentDailyDeficit: Int
    let deficitToday, projectedAverageTotalDeficitForTomorrow, averageDeficitThisMonth: Double
    var individualStatistics: [String: Day]
    var runs: [Run]
    var numberOfRuns: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case daysBetweenStartAndNow, dailyActiveCalories, averageDeficitSinceStart, projectedAverageWeeklyDeficitForTomorrow, averageDeficitThisWeek, daysBetweenStartAndEnd, daysBetweenNowAndEnd, percentWeeklyDeficit, expectedWeightLossSinceStart, deficitsThisWeek, projectedAverageMonthlyDeficitTomorrow, deficitToGetCorrectDeficit, percentDailyDeficit, deficitToday, projectedAverageTotalDeficitForTomorrow, averageDeficitThisMonth, individualStatistics, runs, numberOfRuns
    }
}

class HealthData: ObservableObject {
    //MARK: PROPERTIES
    var environment: AppEnvironmentConfig?
    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
    @Published public var fitness = FitnessCalculations(environment: GlobalEnvironment.environment)
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
        
    @Published public var expectedWeightLossSinceStart: Double = 0
    
    // Days
    @Published public var daysBetweenStartAndEnd: Int = 0
    @Published public var daysBetweenStartAndNow: Int = 0
    @Published public var daysBetweenNowAndEnd: Int = 0
    @Published public var deficitsThisWeek: [Int:Double] = [:]
    @Published public var dailyActiveCalories: [Int:Double] = [:]
    
    @Published public var workouts: WorkoutInformation = WorkoutInformation(afterDate: "01.23.2021", environment: .debug)
    
    @Published public var activeCalorieModifier: Double = 1
    @Published public var adjustActiveCalorieModifier = true
    @Published public var runs: [Run] = []


    //todo
    @Published public var runClicked: Run = Run(date: Date(), totalDistance: 0, totalTime: 0, averageMileTime: 0, caloriesBurned: 0, weightAtTime: 0)
    @Published public var numberOfRuns: Int = UserDefaults.standard.value(forKey: "numberOfRuns") as? Int ?? 0
    
    @Published public var individualStatistics: [Int:Day] = [:]
    
    // Constants
    let minimumActiveCalories: Double = 200
    let minimumRestingCalories: Double = 2300
    let goalDeficit: Double = 1000
    let goalEaten: Double = 1500
    let caloriesInPound: Double = 3500
    let startDateString = "01.23.2021"
    var startDate: Date?
    let endDateString = "05.01.2021"
    let formatter = DateFormatter()
    
    //MARK: INITIALIZATION
    init(environment: AppEnvironmentConfig) {
        Task {
            self.environment = environment
            switch environment {
            case .release:
                await setValues(nil)
            case .debug:
                await setValuesDebug(nil)
            }
        }
        
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
    
    func setValues(_ completion: ((_ health: HealthData) -> Void)?) async {
        
        //MARK: RUNS
        loadRunningWorkouts(completion: { [self] workouts, error in
            if let workouts = workouts {
                var runs = workouts.map { item -> Run in
                    let duration = Double(item.duration) / 60
                    let distance = item.totalDistance?.doubleValue(for: .mile()) ?? 1
                    let average = duration / distance
                    let indoor = item.metadata?["HKIndoorWorkout"] as! Bool
                    let burned = item.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                    let weightAtTime = fitness.weight(at: item.startDate)
                    let run = Run(date: item.startDate, totalDistance: distance, totalTime: duration, averageMileTime: average, indoor: indoor, caloriesBurned: burned ?? 0, weightAtTime: weightAtTime)
                    return run
                }
                print(runs)
                
                // Handle exceptions
                //TODO: Make this something possible from within app settings
                runs = runs.filter { item in
                    let timeIssue = item.totalTime == 49.384849566221234
                    let totalDistance = item.totalDistance == 3.0232693776029285
                    return !(timeIssue && totalDistance)
                }
                
                //TODO Do this somewhere else
                runs = runs.filter { item in
                    !item.indoor
                }
                
                // Handle date
                runs = runs.filter { item in
                    return item.date > self.startDate ?? Date()
                }
                runs = runs.reversed()
                self.runs = runs
            }
        })
        
        setupDates()
        workouts = WorkoutInformation(afterDate: self.startDate ?? Date(), environment: environment ?? .release)
        fitness.getAllStats() // make this async?
        
        if adjustActiveCalorieModifier {
            self.activeCalorieModifier = 1
            let tempAverageDeficitSinceStart = await getAverageDeficit(forPast: self.daysBetweenStartAndNow)
            let activeCalorieModifier = await getActiveCalorieModifier(weightLost: fitness.weightLost, daysBetweenStartAndNow: daysBetweenStartAndNow, averageDeficitSinceStart: tempAverageDeficitSinceStart ?? 0.0)
            DispatchQueue.main.async { [self] in
                self.activeCalorieModifier = activeCalorieModifier
            }
        }
        
        let averageDeficitSinceStart = await getAverageDeficit(forPast: self.daysBetweenStartAndNow) ?? 0
        let deficitToGetCorrectDeficit = await getDeficitToReachIdeal() ?? 0
        let projectedAverageWeeklyDeficitForTomorrow = await getProjectedAverageDeficitForTomorrow(forPast: 6) ?? 0
        let projectedAverageTotalDeficitForTomorrow = await getProjectedAverageDeficitForTomorrow(forPast: self.daysBetweenStartAndNow) ?? 0
        let averageDeficitThisWeek = await getAverageDeficit(forPast: 7) ?? 0
        let averageDeficitThisMonth = await getAverageDeficit(forPast: 30) ?? 0
        let projectedAverageMonthlyDeficitTomorrow = await getProjectedAverageDeficitForTomorrow(forPast: 30) ?? 0
        let deficitToday = await getAverageDeficit(forPast: 0) ?? 0
        let deficitsThisWeek = await getIndividualDeficits(forPastDays: 7)
        let dailyActiveCalories = await getIndividualActiveCalories(forPastDays: 7)
        let individualStatistics = await getIndividualStatistics(forPastDays: 7)
        let percentWeeklyDeficit = Int((averageDeficitThisWeek / goalDeficit) * 100)
        let percentDailyDeficit = Int((deficitToday / deficitToGetCorrectDeficit) * 100)
        let expectedWeightLossSinceStart = (averageDeficitSinceStart * Double(self.daysBetweenStartAndNow)) / Double(3500)
        
#if os(iOS)
        //TODO improve
        // Dont send or use data if its messed up
        if dailyActiveCalories.values.filter({ $0 != 0 }).isEmpty {
            completion?(self)
            return
        }
        // On iOS, send up the relevant data
        let dataToSend = DataToSend(deficitToday: deficitToday,
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
                                    daysBetweenStartAndEnd: daysBetweenStartAndEnd,
                                    daysBetweenStartAndNow: daysBetweenStartAndNow,
                                    daysBetweenNowAndEnd: daysBetweenNowAndEnd,
                                    deficitsThisWeek: deficitsThisWeek,
                                    dailyActiveCalories: dailyActiveCalories,
                                    individualStatistics: individualStatistics,
                                    runs: self.runs,
                                    numberOfRuns: self.numberOfRuns)
        let n = Network()
        let _ = await n.post(object: dataToSend)

        DispatchQueue.main.async { [self] in
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
        }
//        BGTaskScheduler.shared.register(forTaskWithIdentifier: "Me.Fitness2.setValues", using: nil) { task in
//             self.handleAppRefresh(task: task as! BGAppRefreshTask)
//        }
#endif
#if os(watchOS)
        // On watch, receive relevant data
        await setValuesFromNetwork()
#endif
        completion?(self)
    }
    
//    func scheduleAppRefresh() {
//       let request = BGAppRefreshTaskRequest(identifier: "Me.Fitness2.setValues")
//       // Fetch no earlier than 15 minutes from now.
//       request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60)
//
//       do {
//          try BGTaskScheduler.shared.submit(request)
//       } catch {
//          print("Could not schedule app refresh: \(error)")
//       }
//    }
    
//    func handleAppRefresh(task: BGAppRefreshTask) async {
//       // Schedule a new refresh task.
//       scheduleAppRefresh()
//
//       // Create an operation that performs the main part of the background task.
//        let operation = await setValues({ health in
//            task.setTaskCompleted(success: true)})
//
//       // Provide the background task with an expiration handler that cancels the operation.
//       task.expirationHandler = {
////          operation.cancel()
//       }
//
//       // Inform the system that the background task is complete
//       // when the operation completes.
////       operation.completionBlock = {
////          task.setTaskCompleted(success: !operation.isCancelled)
////       }
//
//       // Start the operation.
////       operationQueue.addOperation(operation)
//     }
    
    func setValuesFromNetwork() async {
        let network = Network()
        let getResponse = await network.get()
        
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
        }
    }
    
    func setValuesDebug(_ completion: ((_ health: HealthData) -> Void)?) async {
        await setValuesFromNetwork()
        // Deficits
//        self.deficitToday = 800
//        self.deficitToGetCorrectDeficit = 1200
//        self.averageDeficitThisWeek = 750
//        self.percentWeeklyDeficit = Int((self.averageDeficitThisWeek / goalDeficit) * 100)
//        self.averageDeficitThisMonth = 850
//        self.percentDailyDeficit = Int((self.deficitToday / self.deficitToGetCorrectDeficit) * 100)
//        self.projectedAverageWeeklyDeficitForTomorrow = 900
//        self.projectedAverageTotalDeficitForTomorrow = 760
//        self.deficitsThisWeek = [0: Double(300), 1: Double(1000), 2:Double(500), 3: Double(1200), 4: Double(-300), 5:Double(500),6: Double(300), 7: Double(-1000)]
//
//        self.averageDeficitSinceStart = 750
//        let dataToSend = DataToSend(deficitToday: self.deficitToday,
//                                    averageDeficitThisWeek: self.averageDeficitThisWeek,
//                                    averageDeficitThisMonth: self.averageDeficitThisMonth,
//                                    projectedAverageMonthlyDeficitTomorrow: self.projectedAverageMonthlyDeficitTomorrow,
//                                    averageDeficitSinceStart: self.averageDeficitSinceStart,
//                                    deficitToGetCorrectDeficit: self.deficitToGetCorrectDeficit,
//                                    percentWeeklyDeficit: self.percentWeeklyDeficit,
//                                    percentDailyDeficit: self.percentDailyDeficit,
//                                    projectedAverageWeeklyDeficitForTomorrow: self.projectedAverageWeeklyDeficitForTomorrow,
//                                    projectedAverageTotalDeficitForTomorrow: self.projectedAverageTotalDeficitForTomorrow,
//                                    expectedWeightLossSinceStart: self.expectedWeightLossSinceStart,
//                                    daysBetweenStartAndEnd: self.daysBetweenStartAndEnd,
//                                    daysBetweenStartAndNow: self.daysBetweenStartAndNow,
//                                    daysBetweenNowAndEnd: self.daysBetweenNowAndEnd,
//                                    deficitsThisWeek: self.deficitsThisWeek,
//                                    dailyActiveCalories: self.dailyActiveCalories)
//        let n = Network()
//        n.post(object: dataToSend)
        completion?(self)
    }
    
    func setupDates() {
        guard let startDate = Date.dateFromString(startDateString),
              let endDate = Date.dateFromString(endDateString),
              let daysBetweenStartAndEnd = Date.daysBetween(date1: startDate, date2: endDate),
              let daysBetweenStartAndNow = Date.daysBetween(date1: startDate, date2: Date()),
              let daysBetweenNowAndEnd = Date.daysBetween(date1: Date(), date2: endDate)
        else { return }
        
        self.startDate = startDate
        self.daysBetweenStartAndEnd = daysBetweenStartAndEnd
        self.daysBetweenStartAndNow = daysBetweenStartAndNow
        self.daysBetweenNowAndEnd = daysBetweenNowAndEnd
    }
    
    func getIndividualDeficits(forPastDays days: Int) async -> [Int:Double] {
        var deficits: [Int:Double] = [:]
        for i in 0...days {
            let deficit = await getDeficitForDay(daysAgo: i)
            deficits[i] = deficit
            if deficits.count == days + 1 {
                return deficits
            }
        }
        return [0:0]
    }
    
    func getIndividualActiveCalories(forPastDays days: Int) async -> [Int:Double] {
        var activeCalories: [Int:Double] = [:]
        for i in 0...days {
            let active = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            activeCalories[i] = active
            if activeCalories.count == days + 1 {
                return activeCalories
            }
        }
        return [0:0]
    }
    
    func getIndividualStatistics(forPastDays days: Int) async -> [Int:Day] {
        var dayInformation: [Int:Day] = [:]
        for i in 0...days {
            let active = await sumValueForDay(daysAgo: i, forType: .activeEnergyBurned) * activeCalorieModifier
            let deficit = await getDeficitForDay(daysAgo: i) ?? 0
            let eaten = await sumValueForDay(daysAgo: i, forType: .dietaryEnergyConsumed)
            let day = Day(deficit: deficit, activeCalories: active, consumedCalories: eaten)
            dayInformation[i] = day
            if dayInformation.count == days + 1 {
                return dayInformation
            }
        }
        return [:]

    }
    
    func loadRunningWorkouts(completion:
      @escaping ([HKWorkout]?, Error?) -> Void) {
        
      let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
      
      let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                            ascending: false)
        
        let query = HKSampleQuery(
          sampleType: .workoutType(),
          predicate: workoutPredicate,
          limit: 100,
          sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            DispatchQueue.main.async {
              guard
                let samples = samples as? [HKWorkout],
                error == nil
                else {
                  completion(nil, error)
                  return
              }
              completion(samples, nil)
            }
          }

        HKHealthStore().execute(query)
    }
    
    //MARK: PRIVATE
    private func sumValue(forPast days: Int, forType type: HKQuantityTypeIdentifier, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: type) else {
            print("*** Unable to create a type ***")
            return
        }
        let now = days == 0 ?
        Date() :
        Calendar.current.startOfDay(for: Date())
        let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictEndDate, .strictStartDate])
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.kilocalorie()))
        }
        healthStore.execute(query)
        
    }
    
    private func sumValueForDay(daysAgo: Int, forType type: HKQuantityTypeIdentifier) async -> Double {
        return await withUnsafeContinuation { continuation in
            guard let quantityType = HKObjectType.quantityType(forIdentifier: type) else {
                print("*** Unable to create a type ***")
                continuation.resume(returning: 0.0)
                return
            }
            let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -daysAgo), to: Date())!)
            let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: startDate)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictEndDate, .strictStartDate])
            
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: HKUnit.kilocalorie()))
            }
            healthStore.execute(query)
        }
    }
    
    func getActiveCalorieModifier(weightLost: Double, daysBetweenStartAndNow: Int, averageDeficitSinceStart: Double) async -> Double {
        let weightLost = fitness.weightLost
        let caloriesLost = weightLost * 3500
        let active = await getActiveCaloriesBurned(forPast: daysBetweenStartAndNow)
        let currentCalorieCalculation = Double(daysBetweenStartAndNow) * averageDeficitSinceStart
        let resting = currentCalorieCalculation - active
        // todo the modifier is only supposed to apply to active calories!
        let modifier = (caloriesLost - resting) / active
        if modifier == Double.nan || modifier == Double.infinity {
            return 1
        }
        return Double(modifier)
    }
    
    func getDeficit(resting: Double, active: Double, eaten: Double) -> Double {
        return (resting + (active * activeCalorieModifier)) - eaten
    }
    
    //MARK: BURNED
    
    func getDeficitForDay(daysAgo: Int) async -> Double? {
        let resting = await sumValueForDay(daysAgo: daysAgo, forType: .basalEnergyBurned)
        let active = await sumValueForDay(daysAgo: daysAgo, forType: .activeEnergyBurned)
        let eaten = await sumValueForDay(daysAgo: daysAgo, forType: .dietaryEnergyConsumed)
        let realResting = max(resting, 2300)
        let realActive = max(active, 200)
        print("\(daysAgo) days ago: resting: \(realResting) active: \(realActive) eaten: \(eaten)")
        let deficit = self.getDeficit(resting: realResting, active: realActive, eaten: eaten)
        return deficit
    }
    
    //MARK: EATEN
    
    func getCaloriesEatenToday(completion: @escaping ((_ eaten: Double?) -> Void)) {
        sumValue(forPast: 0, forType: .dietaryEnergyConsumed, completion: completion)
    }
    
    func getAverageCaloriesEatenThisWeek() async -> Double? {
        let total = await getTotalCaloriesEaten(forPast: 7)
        return total / 7
    }
    
    func getProjectedAverageDeficitForTomorrow(forPast days: Int) async -> Double? {
        let pastDeficit = await getAverageDeficit(forPast: days)
        let dailyDeficit = await getAverageDeficit(forPast: 0)
        guard
            let pastDeficit = pastDeficit,
            let dailyDeficit = dailyDeficit else {
                return nil
            }
        let projectedAverageDeficitForTomorrow = ((pastDeficit * Double(days)) + dailyDeficit) / (Double(days) + 1)
        return projectedAverageDeficitForTomorrow
        
    }
    
    // async await
    
    func getDeficitToReachIdeal() async -> Double? {
        let averageDeficitForPast6Days = await getAverageDeficit(forPast: 6)
        let plan = (1000*7) - ((averageDeficitForPast6Days ?? 1) * 6)
        return plan
    }
    
    func getAverageDeficit(forPast days: Int) async -> Double? {
        let resting = await getRestingCaloriesBurned(forPast: days)
        let active = await getActiveCaloriesBurned(forPast: days)
        let eaten = await getTotalCaloriesEaten(forPast: days)
        let realDays: Double = Double(days == 0 ? 1 : days)
        let realResting = max(Double(minimumRestingCalories) * realDays, resting)
        let realActive = max(Double(minimumActiveCalories) * realDays, active)
        let deficit = getDeficit(resting: realResting, active: realActive, eaten: eaten)
        let average = deficit / realDays
        return average
    }
    
    func getActiveCaloriesBurned(forPast days: Int) async -> Double {
        return await sumValue(forPast: days, forType: .activeEnergyBurned) // todo when summing these things, we don't account for the minimum of 200 active calories
    }
    
    func getTotalCaloriesEaten(forPast days: Int) async -> Double {
        return await sumValue(forPast: days, forType: .dietaryEnergyConsumed)
    }
    
    func getRestingCaloriesBurned(forPast days: Int) async -> Double {
        return await sumValue(forPast: days, forType: .basalEnergyBurned)
    }
    
    private func sumValue(forPast days: Int, forType type: HKQuantityTypeIdentifier) async -> Double {
        return await withUnsafeContinuation { continuation in
            guard let quantityType = HKObjectType.quantityType(forIdentifier: type) else {
                print("*** Unable to create a type ***")
                continuation.resume(returning: 0.0)
                return
            }
            let now = days == 0 ? Date() : Calendar.current.startOfDay(for: Date())
            let startDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: -days), to: now)!)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictEndDate, .strictStartDate])
            
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                
                if error != nil {
                    continuation.resume(returning: 0.0)
                } else {
                    guard let result = result, let sum = result.sumQuantity() else {
                        continuation.resume(returning: 0.0)
                        return
                    }
                    continuation.resume(returning: sum.doubleValue(for: HKUnit.kilocalorie()))
                }
            }
            healthStore.execute(query)
        }
    }
}
