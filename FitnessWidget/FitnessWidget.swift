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
        let  entryDate = Calendar.current.date(byAdding: .second, value: 1 , to: Date())!
        let _ = HealthData(environment: GlobalEnvironment.environment) { health in
            let entry = SimpleEntry(date: entryDate, healthData: healthData)
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
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
                            DeficitRings()
                                .environmentObject(entry.healthData)
                                .padding([.top, .bottom, .leading], /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                                .frame(maxWidth: 125)
                            BarChart(cornerRadius: 2.0)
                                .environmentObject(entry.healthData)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .background(Color.myGray)
                                .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                        }
                        
                    default:
                        DeficitRings()
                            .environmentObject(entry.healthData)
                            .padding()
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
