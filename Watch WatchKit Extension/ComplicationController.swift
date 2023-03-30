//
//  ComplicationController.swift
//  Watch WatchKit Extension
//
//  Created by Thomas Goss on 11/21/21.
//

import ClockKit
import SwiftUI
import WatchKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "Fitness Goal", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        // Get the health data that we've saved to user defaults
        // It's saved to user defaults when the watch app opens, requests it from the phone, then saves it
        //        guard
        //            let data = UserDefaults.standard.value(forKey: "healthData") as? Data,
        //            let unencoded = try? JSONDecoder().decode(HealthDataPostRequestModel.self, from: data)
        //        else {
        //            handler(nil)
        //            return
        //        }
        Task {
            let day = await HealthData.getToday()
            guard let cTemplate = self.makeTemplate(for: day, complication: complication) else {
                handler(nil)
                return
            }
            let entry = CLKComplicationTimelineEntry(
                date: Date(),
                complicationTemplate: cTemplate)
            DispatchQueue.main.async {
                handler(entry)
            }
        }
//        let _ = HealthData(environment: AppEnvironmentConfig.release) { health in
//            //        health.setValues(from: unencoded)
//            guard let cTemplate = self.makeTemplate(for: health, complication: complication) else {
//                handler(nil)
//                return
//            }
//            let entry = CLKComplicationTimelineEntry(
//                date: Date(),
//                complicationTemplate: cTemplate)
//            DispatchQueue.main.async {
//                handler(entry)
////                WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date().addingTimeInterval(60 * 15), userInfo: <#T##(NSSecureCoding & NSObjectProtocol)?#>, scheduledCompletion: <#T##(Error?) -> Void#>)
//            }
//        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date
        handler(nil)
    }

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
}

extension ComplicationController {
    func makeTemplate(
      for day: Day,
      complication: CLKComplication
    ) -> CLKComplicationTemplate? {
      switch complication.family {
  //    case .modularLarge:
  //        return CLKComplicationTemplateModularLargeTallBody(
  //            BarChart()
  //        )
      case .graphicCircular:
          return CLKComplicationTemplateGraphicCircularView(
  //            DeficitRings(lineWidth: 5)
  //                .environmentObject(healthData)
  //            TodayRing(lineWidth: 5)
  //                .environmentObject(healthData)
//              TodayRingWithMonthly(lineWidth: 5)
//                  .environmentObject(healthData)
            OverallRing(today: day, lineWidth: 5, fontSize: 20, includeTitle: false, includeSubBody: false, shouldPad: false)
          )
//      case .graphicRectangular, .modularLarge, .modularSmall, .graphicExtraLarge:
//  //    case .modularLarge:
//          return CLKComplicationTemplateGraphicRectangularFullView(
////              BarChart(cornerRadius: 2, showCalories: false, isComplication: true)
////                  .environmentObject(healthData)
//          )
  //        return CLKComplicationTemplateExtraLargeSimpleImage
  //      return CLKComplicationTemplateModularLargeTallBody(headerTextProvider: CLKTextProvider(format: "Deficits"), bodyTextProvider: <#T##CLKTextProvider#>)
  //    case .graphicCorner:
  //      return CLKComplicationTemplateGraphicCornerCircularView(
  //        ComplicationViewCornerCircular(appointment: appointment))
      default:
        return nil
      }
    }
  func makeTemplate(
    for healthData: HealthData,
    complication: CLKComplication
  ) -> CLKComplicationTemplate? {
    switch complication.family {
//    case .modularLarge:
//        return CLKComplicationTemplateModularLargeTallBody(
//            BarChart()
//        )
    case .graphicCircular:
        return CLKComplicationTemplateGraphicCircularView(
//            DeficitRings(lineWidth: 5)
//                .environmentObject(healthData)
//            TodayRing(lineWidth: 5)
//                .environmentObject(healthData)
            TodayRingWithMonthly(lineWidth: 5)
                .environmentObject(healthData)
        )
    case .graphicRectangular, .modularLarge, .modularSmall, .graphicExtraLarge:
//    case .modularLarge:
        return CLKComplicationTemplateGraphicRectangularFullView(
            BarChart(cornerRadius: 2, showCalories: false, isComplication: true)
                .environmentObject(healthData)
        )
//        return CLKComplicationTemplateExtraLargeSimpleImage
//      return CLKComplicationTemplateModularLargeTallBody(headerTextProvider: CLKTextProvider(format: "Deficits"), bodyTextProvider: <#T##CLKTextProvider#>)
//    case .graphicCorner:
//      return CLKComplicationTemplateGraphicCornerCircularView(
//        ComplicationViewCornerCircular(appointment: appointment))
    default:
      return nil
    }
  }
}

