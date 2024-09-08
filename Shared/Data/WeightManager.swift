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

protocol WeightProcessorProtocol {
    var query: HKSampleQuery? { get }
    var weights: [Weight] { get }
    func processWeights(continuation: CheckedContinuation<[Weight], Never>, _ query: HKSampleQuery, _ results: [HKSample]?, _ error: (any Error)?) -> Void
}

class WeightProcessor: WeightProcessorProtocol {
    var query: HKSampleQuery?
    
    var weights: [Weight] = [] // TODO necessary?
    
    func processWeights(continuation: CheckedContinuation<[Weight], Never>, _ query: HKSampleQuery, _ results: [HKSample]?, _ error: (any Error)?) {
        if let results = results as? [HKQuantitySample] {
            let weights = results
                .map{ Weight(weight: Decimal($0.quantity.doubleValue(for: HKUnit.pound())), date: $0.endDate) }
                .sorted { $0.date < $1.date }
            self.weights = weights
            self.query = query
            continuation.resume(returning: weights)
            return
        }
    }
}

protocol HealthStorageProtocol {
    func sampleQuery(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void)
}

//TODO: For now, all in one, then separate later
class HealthStorage: HealthStorageProtocol {
    private let healthStore = HKHealthStore()

    func sampleQuery(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors, resultsHandler: resultsHandler)
        healthStore.execute(query)
    }
    
    
}

class MockHealthStorage: HealthStorageProtocol {
    func sampleQuery(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors, resultsHandler: resultsHandler)
        // TODO set up some Days, using testDays probably, then create samples from their weights
        let x: HKQuantitySample = .init(type: .init(.bodyMass), quantity: .init(unit: .pound(), doubleValue: 100), start: Date().subtracting(days: 1), end: Date().subtracting(days: 1))
        resultsHandler(query, [x], nil)
    }
}

class WeightManager: ObservableObject {
    var environment: AppEnvironmentConfig?
    var weightProcessor: WeightProcessorProtocol
    private var healthStorage: HealthStorageProtocol
    
    var startDate: Date?
    @Published var startingWeight: Decimal = 231.8
    @Published var currentWeight: Decimal = 231.8
    @Published var endingWeight: Decimal = 190
    @Published var progressToWeight: Decimal = 0
    @Published var weightLost: Decimal = 0
//    @Published var percentWeightLost: Int = 0
    @Published var weightToLose: Decimal = 0
    @Published var averageWeightLostPerWeek: Decimal = 0
    @Published var weights: [Weight] = []
    @Published var weightsAfterStartDate: [Weight] = []
    @Published var averageWeightLostPerWeekThisMonth: Decimal = 0
    
    init(environment: AppEnvironmentConfig) {
        self.environment = environment
        switch environment {
        case .release(options: let config):
            weightProcessor = config?.weightProcessor ?? WeightProcessor()
            healthStorage = config?.healthStorage ?? HealthStorage() // TODO this is duplicated in setup
        case .debug(let config):
            weightProcessor = config?.weightProcessor ?? WeightProcessor()
            healthStorage = config?.healthStorage ?? HealthStorage() // TODO this is duplicated in setup
        case .widgetRelease:
            weightProcessor = WeightProcessor()
            healthStorage = HealthStorage() // TODO this is duplicated in setup
        }
    }
    
    init() {
        weightProcessor = WeightProcessor()
        healthStorage = HealthStorage()
    }
    
    // TODO use better
    func getProgressToWeight() -> Decimal {
        let lost = startingWeight - currentWeight
        let totalToLose = startingWeight - endingWeight
        let progress = lost / totalToLose
        return progress
    }
    
    @discardableResult
    func setup(
        startDate: Date? = nil,
        startDateString: String? = nil
    ) async -> Bool {
        guard let startDate: Date =
                startDate ??
                startDateString?.toDate() ??
                (Settings.get(key: .startDate) as? String)?.toDate()
         else {
            return false
        }
        self.startDate = startDate
        self.weights = await getWeights()
        self.weightsAfterStartDate = self.weights.filter { $0.date >= startDate }
        
        self.currentWeight = self.weights.last?.weight ?? 1
        
        self.startingWeight = weight(at: startDate) ?? 1 //TODO
        
        self.progressToWeight = self.getProgressToWeight()
        self.weightLost = self.startingWeight - self.currentWeight
        self.weightToLose = self.startingWeight - self.endingWeight
        guard
            let daysBetweenStartAndNow = Date.daysBetween(date1: startDate, date2: Date())
        else { return false }
        
        let weeks: Decimal = Decimal(daysBetweenStartAndNow) / Decimal(7)
        self.averageWeightLostPerWeek = self.weightLost / weeks
        return true
    }
    
    func weight(at date: Date) -> Decimal? {
        // If the user has recorded weights before (and after) the set start date, then calculate what their what on the start date should be
        let firstRecordedWeightAfterDate = self.weights.first(where: { $0.date >= date })
        let lastRecordedWeightBeforeDate = self.weights.first(where: { $0.date < date })
        guard let firstRecordedWeightAfterDate else {
            guard let lastRecordedWeightBeforeDate else {
                return nil
            }
            return lastRecordedWeightBeforeDate.weight
        }
        guard let lastRecordedWeightBeforeDate else {
            return firstRecordedWeightAfterDate.weight
        }
       
        let weightDiff = firstRecordedWeightAfterDate.weight - lastRecordedWeightBeforeDate.weight
        guard let dayDiff = Date.daysBetween(date1: firstRecordedWeightAfterDate.date, date2: lastRecordedWeightBeforeDate.date) else {
            return nil
        }
        let weightDiffPerDay = weightDiff / Decimal(dayDiff)
        guard let daysBetweenWeightBeforeAndAfterDate = Date.daysBetween(date1: lastRecordedWeightBeforeDate.date, date2: date) else {
            return nil
        }
        return lastRecordedWeightBeforeDate.weight + (weightDiffPerDay * Decimal(daysBetweenWeightBeforeAndAfterDate))
    }
    
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
    
#if !os(macOS)
    func getWeights() async -> [Weight] {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            healthStorage.sampleQuery(sampleType: bodyMassType, predicate: nil, limit: 3000, sortDescriptors: [sortDescriptor]) { query, results, error in
                self.weightProcessor.processWeights(continuation: continuation, query, results, error)
            }
        }
    }
#endif
    
//    //TODO: Get this working
//    private func observeCalories() {
//#if os(watchOS)
//        // Create the calorie type.
//        let calorie = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
//
//        // Set up the background delivery rate.
//        healthStore.enableBackgroundDelivery(for: calorie,
//                                          frequency: .immediate) { success, error in
//            if !success {
//                print("Unable to set up background delivery from HealthKit: \(error!.localizedDescription)")
//            } else {
//                print("observing calories")
//            }
//        }
//        // Set up the observer query.
//        let backgroundObserver =
//        HKObserverQuery(sampleType: calorie, predicate: nil)
//        { (query: HKObserverQuery, completionHandler: @escaping () -> Void, error: Error?) in
//            // Query for actual updates here.
//            // When you're done processing the changes, be sure to call the completion handler.
//            let server = CLKComplicationServer.sharedInstance()
//            server.activeComplications?.forEach { complication in
//                server.reloadTimeline(for: complication)
//            }
//            completionHandler()
//        }
//        
//        // If you successfully created the query,  execute it.
//        healthStore.execute(backgroundObserver)
//#endif
//    }
}

