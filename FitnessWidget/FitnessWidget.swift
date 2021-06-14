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
    var healthKit: MyHealthKit = MyHealthKit(environment: GlobalEnvironment.environment)
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), healthKit: healthKit)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), healthKit: healthKit)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let  entryDate = Calendar.current.date(byAdding: .second, value: 1 , to: Date())!
        let _ = MyHealthKit(environment: GlobalEnvironment.environment) { health in
            let entry = SimpleEntry(date: entryDate, healthKit: healthKit)
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    @State var healthKit: MyHealthKit
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
                            .environmentObject(entry.healthKit)
                            .padding()
                    case WidgetFamily.systemMedium:
                        HStack {
                            DeficitRings()
                                .environmentObject(entry.healthKit)
                                .padding([.top, .bottom, .leading], /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                            BarChart()
                                .environmentObject(entry.healthKit)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .background(Color.myGray)
                                .cornerRadius(5)
                                .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                        }
                        
                    default:
                        DeficitRings()
                            .environmentObject(entry.healthKit)
                            .padding()
                    }
                }
            }
        }
        //        GeometryReader { geometry in
//            ZStack {
//                Color.myGray.ignoresSafeArea(.all)
//                VStack(alignment: .leading) {
////                    FitnessView(shouldShowText: false, lineWidth: 6, widget: true)
////                        .environmentObject(entry.fitness)
////                        .environmentObject(entry.healthKit)
////                        .frame(maxWidth: 80, maxHeight: 80, alignment: .leading)
////                    DeficitText(percentages: true)
////                        .environmentObject(entry.fitness)
////                        .environmentObject(entry.healthKit)
////                        .frame(maxWidth: .infinity, alignment: .leading)
////                        .padding([.leading], 10)
////                        .padding([.bottom], 10)
//                    DeficitRings()
//                        .environmentObject(entry.fitness)
//                        .environmentObject(entry.healthKit)
//                        .padding()
//                }
//            }
//        }
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
//        let healthKit = MyHealthKit(environment: GlobalEnvironment.environment)
//        let entry = SimpleEntry(date: Date(), healthKit: healthKit)
//        FitnessWidgetEntryView(entry: entry)
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
