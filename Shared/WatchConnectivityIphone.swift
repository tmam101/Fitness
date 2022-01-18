//
//  WatchData.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 1/8/22.
//

import Foundation
import WatchConnectivity
import SwiftUI

class WatchConnectivityIphone: NSObject, WCSessionDelegate, ObservableObject {
    var session: WCSession
    @Published var messageString = ""
    
    init(session: WCSession = .default){
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("watch connectivity iphone activationDidComplete")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
//    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
//        DispatchQueue.main.async {
//            self.messageString = message["message"] as? String ?? "Unknown"
//        }
//    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("watch connectivity iOS has receieved a message \(message)")
        replyHandler(["success" : "it worked!"])
        DispatchQueue.main.async {
            self.messageString = message["request"] as? String ?? "Unknown"
        }
//        let _ = HealthData(environment: GlobalEnvironment.environment) { healthData in
//            let dataToSend = healthData.dataToSend
//            do {
//                let encodedData = try JSONEncoder().encode(dataToSend)
//                session.sendMessage(["healthData" :encodedData], replyHandler: { response in
//                    print("watch connectivity iphone sent response correctly, received this \(response)")
//                }, errorHandler: {error in
//                    print("watch connectivity iphone error \(error)")
//                })
//            } catch {
//                return
//            }
//        }
    }
}
