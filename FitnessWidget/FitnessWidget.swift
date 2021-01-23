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
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), successPercentage: 0, progressToWeight: 0, progressToDate: 0)
//    return SimpleEntry(date: Date(), fitness: fitness)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), successPercentage: 0, progressToWeight: 0, progressToDate: 0)
//        let entry = SimpleEntry(date: Date(), fitness: FitnessCalculations())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
//        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate)
//            entries.append(entry)
//        }
        let _ = FitnessCalculations { fitness in
//            let entry = SimpleEntry(date: Date(), fitness: fitness)
            let entry = SimpleEntry(date: Date(), successPercentage: fitness.successPercentage, progressToWeight: fitness.progressToWeight, progressToDate: fitness.progressToDate)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }

        
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    @State var successPercentage: Float
    @State var progressToWeight: Float
    @State var progressToDate: Float
//    @State var fitness: FitnessCalculations
}

//struct FitnessWidgetEntryView : View {
//    var entry: Provider.Entry
//
//    var body: some View {
//        Text(entry.date, style: .time)
//    }
//}

struct FitnessWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    func progressString(from float: Float) -> String {
        return String(format: "%.2f", float * 100)
    }

    
    var body: some View {
        ZStack {
            ProgressCircle(progress: entry.$progressToWeight, progressTowardDate: entry.$progressToDate, successPercentage: entry.$successPercentage)
                .padding()
                .background(Color.init(red: 28/255, green: 29/255, blue: 31/255))
            VStack {
//                Text(fitness.progressString(from: fitness.progressToWeight) + "% to weight")
//                Text(fitness.progressString(from: fitness.progressToDate) + "% to date")
                let success = entry.successPercentage
                let successString = success > 0 ?
                    "+" + progressString(from: success) + "%" :
                    "-" + progressString(from: 0 - success) + "%"
                Text(successString)
                    .foregroundColor(.white)
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
        FitnessWidgetEntryView(entry: SimpleEntry(date: Date(), successPercentage: 0, progressToWeight: 0, progressToDate: 0))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
