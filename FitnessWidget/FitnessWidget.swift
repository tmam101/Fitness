//
//  FitnessWidget.swift
//  FitnessWidget
//
//  Created by Thomas Goss on 1/22/21.
//

import WidgetKit
import SwiftUI
import HealthKit
import Combine

struct Provider: TimelineProvider {
    @ObservedObject var healthData: HealthData = HealthData(environment: AppEnvironmentConfig.debug(nil))
    private var cancellables = Set<AnyCancellable>()
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), healthData: healthData)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
//        healthData.$hasLoaded.sink(receiveCompletion: {_ in }, receiveValue: { hasLoaded in
//            let entry = SimpleEntry(date: Date(), healthData: healthData)
//            completion(entry)
//        }).store(in: &cancellables)
        let _ = HealthData(environment: AppEnvironmentConfig.widgetRelease) { health in
            let entry = SimpleEntry(date: Date(), healthData: health)
            completion(entry)
            //            let  entryDate = Calendar.current.date(byAdding: .minute, value: 15 , to: Date())!
            //            let entry = SimpleEntry(date: entryDate, healthData: health)
            //            let timeline = Timeline(entries: [entry], policy: .atEnd)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let _ = HealthData(environment: AppEnvironmentConfig.widgetRelease) { health in
            let  entryDate = Calendar.current.date(byAdding: .minute, value: 15 , to: Date())!
            let entry = SimpleEntry(date: entryDate, healthData: health)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    @State var healthData: HealthData
}

struct FitnessWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        let correctedDate = Calendar.current.date(byAdding: .minute, value: -15, to: entry.date)
        let d = Calendar.current.dateComponents([.hour, .minute], from: correctedDate!)
        let xHour = d.hour ?? 0
        let hour = xHour > 12 ? xHour - 12 : xHour
        let minute = d.minute ?? 0
        let minuteString = minute < 10 ? "0\(minute)" : "\(minute)"
        
        GeometryReader { geometry in
            ZStack {
                Color.myGray.ignoresSafeArea(.all)
                VStack(alignment: .leading) {
                    switch family {
                    case WidgetFamily.systemLarge:
                        NetEnergyBarChart(health: entry.healthData, timeFrame: .week)
                            .padding()
                    case WidgetFamily.systemMedium:
                        HStack {
                            VStack {
                                NetEnergyBarChart(health: entry.healthData, timeFrame: .week)
                                    .padding([.top, .bottom, .leading], /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                                    .frame(maxWidth: 125)
                                Text("Last updated \(hour):\(minuteString)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 10))
                                    .padding([.bottom])
                            }
                        }
                        
                    default:
                        VStack {
                            if let day = entry.healthData.days[0] {
                                NetEnergyBarChart(health: entry.healthData, timeFrame: .week)
                            }
                        }
                    }
                }
            }
        }.containerBackground(Color.myGray, for: .widget)
    }
}

@main
struct FitnessWidget: Widget {
    let kind: String = "FitnessWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FitnessWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

//struct x: View {
//    @State var health: HealthData?
//    
//    var body: some View {
//        let x = {
//            let _ = HealthData(environment: .debug) { healthData in
//                health = healthData
//            }
//        }()
//        if health?.hasLoaded ?? false {
//            let entry = SimpleEntry(date: Date(), healthData: health!)
//            FitnessWidgetEntryView(entry: entry)
//        } else {
//            Text("Not loaded")
//        }
//    }
//}
//
//struct FitnessWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        
////        let healthData = MyHealthKit(environment: GlobalEnvironment.environment)
////        let entry = SimpleEntry(date: Date(), healthData: healthData)
////        FitnessWidgetEntryView(entry: entry)
//        x()
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
