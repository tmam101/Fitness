//
//  WatchConnectivityWatch.swift
//  Fitness
//
//  Created by Thomas Goss on 1/8/22.
//

import Foundation
import WatchConnectivity
import ClockKit

class WatchConnectivityWatch : NSObject,  WCSessionDelegate, ObservableObject {
    var session: WCSession
    var healthData: HealthData? = nil
    
    init(session: WCSession = .default){
        self.session = session
        super.init()
        switch healthData?.environment {
        case .debug(_):
            return
        case .widgetRelease, .release, .none:
            break // TODO
        }
        session.delegate = self
        session.activate()
    }
    
    func setHealthData(healthData: HealthData) {
        self.healthData = healthData
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//        requestHealthData()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
//        replyHandler(["watch connectivity: watch sending this" : message])
//
//        print("watch connectivity: watchOS has received a message")
//
//        // Receive health data from iOS
//        let data = message["healthData"]
//        UserDefaults.standard.set(data, forKey: "healthData")
//        guard let unencoded = try? JSONDecoder().decode(HealthDataPostRequestModel.self, from: data as! Data) else { return }
//
//        print("watch connectivity unencoded \(unencoded)")
//        print("watch connectivity deficit today \(unencoded.deficitToday)")
//
//        // Set health data, refresh complication
//        self.healthData?.setValues(from: unencoded)
//        let server = CLKComplicationServer.sharedInstance()
//        server.activeComplications?.forEach { complication in
//            server.reloadTimeline(for: complication)
//        }
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach { complication in
            server.reloadTimeline(for: complication)
        }
        replyHandler(["watch connectivity watch received": "yes"])
    }
    
    func requestHealthData() {
        UserDefaults.standard.set("success", forKey: "test")
        
        print(UserDefaults.standard.value(forKey: "test") as! String)
        
        // Set health data values to 0 until they are refreshed
//        healthData?.eraseValues()
        
        print("watch connectivity: watchOS: has delegate? \(session.delegate != nil)")
        print("watch connectivity: watch requesting health data")
        
        // Request health data from iOS
        session.sendMessage(["request" : "healthData"], replyHandler: { x in
            print("watch connectivity: ios received request for health data, respose: \(x)")
        }) { (error) in
            print("watch connectivity: error \(error.localizedDescription)")
        }
    }
}
