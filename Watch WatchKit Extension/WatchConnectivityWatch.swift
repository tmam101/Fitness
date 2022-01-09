//
//  WatchConnectivityWatch.swift
//  Fitness
//
//  Created by Thomas Goss on 1/8/22.
//

import Foundation
import WatchConnectivity

class WatchConnectivityWatch : NSObject,  WCSessionDelegate, ObservableObject {
    var session: WCSession
    var healthData: HealthData? = nil
    
    init(session: WCSession = .default){
        self.session = session
        super.init()
        session.delegate = self
        session.activate()
        
    }
    
    func setHealthData(healthData: HealthData) {
        self.healthData = healthData
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        requestHealthData()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        replyHandler(["watch connectivity: watch sending this" : message])
        print("watch connectivity: watchOS has received a message")
        let data = message["healthData"]
        guard let unencoded = try? JSONDecoder().decode(HealthDataPostRequestModel.self, from: data as! Data) else { return }
        print("watch connectivity unencoded \(unencoded)")
        print("watch connectivity deficit today \(unencoded.deficitToday)")
        self.healthData?.setValues(from: unencoded)
    }
    
    func requestHealthData() {
        print("watch connectivity: watchOS: has delegate? \(session.delegate != nil)")
        session.sendMessage(["request" : "healthData"], replyHandler: { x in
            print("watch connectivity: ios received request for health data, respose: \(x)")
        }) { (error) in
            print("watch connectivity: error \(error.localizedDescription)")
        }
    }
}
