//
//  FitnessWidget.swift
//  FitnessWidget
//
//  Created by Thomas Goss on 1/22/21.
//

import WidgetKit
import SwiftUI
import HealthKit

struct Provider: TimelineProvider {
    var healthData: HealthData = HealthData(environment: GlobalEnvironment.environment)
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), healthData: healthData)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), healthData: healthData)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let  entryDate = Calendar.current.date(byAdding: .minute, value: 15 , to: Date())!
        let _ = HealthData(environment: GlobalEnvironment.environment) { health in
            let entry = SimpleEntry(date: entryDate, healthData: healthData)
//            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
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
                        AllRings()
                            .environmentObject(entry.healthData)
                            .padding()
                    case WidgetFamily.systemMedium:
                        HStack {
                            VStack {
                                DeficitRings()
                                    .environmentObject(entry.healthData)
                                    .padding([.top, .bottom, .leading], /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                                    .frame(maxWidth: 125)
                                Text("Last updated \(hour):\(minuteString)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 10))
                                    .padding([.bottom])
                            }
                            BarChart(cornerRadius: 2.0, showCalories: false)
                                .environmentObject(entry.healthData)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .background(Color.myGray)
                                .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                        }
                        
                    default:
                        VStack {
                        DeficitRings()
                            .environmentObject(entry.healthData)
                            .padding([.top, .leading, .trailing])
                            Text("Last updated \(hour):\(minuteString)")
                                .foregroundColor(.white)
                                .font(.system(size: 10))
                                .padding([.bottom])
                        }
                    }
                }
            }
        }
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

//struct FitnessWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        let healthData = MyHealthKit(environment: GlobalEnvironment.environment)
//        let entry = SimpleEntry(date: Date(), healthData: healthData)
//        FitnessWidgetEntryView(entry: entry)
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
