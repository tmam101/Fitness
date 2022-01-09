////
////  WatchManager.swift
////  Fitness
////
////  Created by Thomas Goss on 1/3/22.
////
//import Foundation
//import WatchConnectivity
//
//final class Connectivity: NSObject, ObservableObject {
//  @Published var value: String = ""
//
//    static let shared = Connectivity()
//
//    override private init() {
//        super.init()
//#if !os(watchOS)
//        guard WCSession.isSupported() else {
//            return
//        }
//#endif
//        WCSession.default.delegate = self
//        WCSession.default.activate()
//    }
//
//    public func send(movieIds: [Int]) {
//      guard WCSession.default.activationState == .activated else {
//        return
//      }
//        #if os(watchOS)
//        guard WCSession.default.isCompanionAppInstalled else {
//          return
//        }
//        #else
//        guard WCSession.default.isWatchAppInstalled else {
//          return
//        }
//        #endif
//        let userInfo: [String: String] = ["test":"value"]
//
//        WCSession.default.transferUserInfo(userInfo)
//
//    }
//
//}
//
//// MARK: - WCSessionDelegate
//extension Connectivity: WCSessionDelegate {
//    func session(
//        _ session: WCSession,
//        activationDidCompleteWith activationState: WCSessionActivationState,
//        error: Error?
//    ) {
//    }
//
//#if os(iOS)
//    func sessionDidBecomeInactive(_ session: WCSession) {
//    }
//
//    func sessionDidDeactivate(_ session: WCSession) {
//    }
//#endif
//    // 1
//    func session(
//      _ session: WCSession,
//      didReceiveUserInfo userInfo: [String: Any] = [:]
//    ) {
//      // 2
//      let key = "test"
//      guard let value = userInfo[key] as? String else {
//        return
//      }
//
//      // 3
//      self.value = value
//    }
//
//}
//
