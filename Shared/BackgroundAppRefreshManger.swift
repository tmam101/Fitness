//
//  BackgroundAppRefreshManger.swift
//  Watch WatchKit Extension
//
//  Created by Thomas Goss on 1/4/22.
//

//TODO implement
import Foundation
//        BGTaskScheduler.shared.register(forTaskWithIdentifier: "Me.Fitness2.setValues", using: nil) { task in
//             self.handleAppRefresh(task: task as! BGAppRefreshTask)
//        }
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
