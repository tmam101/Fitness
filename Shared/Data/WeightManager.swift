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

class WeightManager: ObservableObject { // TODO should we adjust weights in here? Add a weight for every day when they are missing?
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
        healthStorage = environment.healthStorage
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
                (Settings.get(.startDate))
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
        
#if !os(macOS)
    func getWeights() async -> [Weight] {
        return await withCheckedContinuation { continuation in
            healthStorage.getAllWeights { query, results, error in
                if let results = results as? [HKQuantitySample] {
                    let weights = results
                        .map{ Weight(weight: Decimal($0.quantity.doubleValue(for: HKUnit.pound())), date: $0.endDate) }
                        .sorted { $0.date < $1.date }
                    self.weights = weights
                    continuation.resume(returning: weights)
                    return
                }
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

