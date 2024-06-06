////
////  RunManager.swift
////  Fitness (iOS)
////
////  Created by Thomas Goss on 1/5/22.
////
//
//import Foundation
//import HealthKit
//import SwiftUI
//import Charts
//
//class RunManager: ObservableObject {
//    var weightManager: WeightManager?
//    var startDate: Date?
//    
//    @Published public var runs: [Run] = []
//    @Published public var numberOfRuns: Int = Settings.get(key: .numberOfRuns) as? Int ?? 0
//    
//    
//    func setup(weightManager: WeightManager, startDate: Date) async {
//        self.weightManager = weightManager
//        self.startDate = startDate
//        self.runs = await getRunningWorkouts()
//    }
//    
//    func loadRunningWorkouts() async -> [HKWorkout]? {
//        return await withUnsafeContinuation { continuation in
//            let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
//            
//            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
//                                                  ascending: false)
//            
//            let query = HKSampleQuery(
//                sampleType: .workoutType(),
//                predicate: workoutPredicate,
//                limit: 100,
//                sortDescriptors: [sortDescriptor]) { (query, samples, error) in
//                    guard
//                        let samples = samples as? [HKWorkout],
//                        error == nil
//                    else {
//                        continuation.resume(returning: nil)
//                        return
//                    }
//                    continuation.resume(returning: samples)
//                }
//            HKHealthStore().execute(query)
//        }
//    }
//    
//    func workoutToRun(_ item: HKWorkout) async -> Run {
//        let duration = Double(item.duration) / 60
//        let distance = item.totalDistance?.doubleValue(for: .mile()) ?? 1
//        let average = duration / distance
//        let indoor = item.metadata?["HKIndoorWorkout"] as! Bool
//        let burned = item.totalEnergyBurned?.doubleValue(for: .kilocalorie())
//        let weightAtTime = weightManager?.weight(at: item.startDate) ?? 1
//        let run = Run(date: item.startDate, totalDistance: distance, totalTime: duration, averageMileTime: average, indoor: indoor, caloriesBurned: burned ?? 0, weightAtTime: weightAtTime)
//        return run
//    }
//    
//    func getRunningWorkouts() async -> [Run] {
//        let runningWorkouts = await loadRunningWorkouts()
//        guard let runningWorkouts = runningWorkouts else {
//            return []
//        }
//        var runs: [Run] = []
//        for item in runningWorkouts {
//            await runs.append(workoutToRun(item))
//        }
//        
//        // Handle exceptions
//        //TODO: Make this something possible from within app settings
//        runs = runs.filter { item in
//            let timeIssue = item.totalTime == 49.384849566221234
//            let totalDistance = item.totalDistance == 3.0232693776029285
//            return !(timeIssue && totalDistance)
//        }
//        
//        //TODO Do this somewhere else
//        runs = runs.filter { item in
//            !item.indoor
//        }
//        
//        // Handle date
//        runs = runs.filter { item in
//            return item.date > self.startDate ?? Date()
//        }
//        runs = runs.reversed()
//        return runs
//    }
//}
