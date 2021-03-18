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
    var fitness: FitnessCalculations = FitnessCalculations()
    var healthKit: MyHealthKit = MyHealthKit()
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), fitness: fitness, healthKit: healthKit)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), fitness: fitness, healthKit: healthKit)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let  entryDate = Calendar.current.date(byAdding: .second, value: 1 , to: Date())!
        let _ = MyHealthKit { health in
            let entry = SimpleEntry(date: entryDate, fitness: fitness, healthKit: health)
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    @State var fitness: FitnessCalculations
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
                    FitnessView(shouldShowText: false, lineWidth: 6, widget: true)
                        .environmentObject(entry.fitness)
                        .environmentObject(entry.healthKit)
                        .frame(maxWidth: 80, maxHeight: 80, alignment: .leading)
                    HealthText(percentages: true)
                        .environmentObject(entry.fitness)
                        .environmentObject(entry.healthKit)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.leading], 10)
                        .padding([.bottom], 10)
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

struct FitnessWidget_Previews: PreviewProvider {
    static var previews: some View {
        FitnessWidgetEntryView(entry: SimpleEntry(date: Date(), fitness: FitnessCalculations(), healthKit: MyHealthKit()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
