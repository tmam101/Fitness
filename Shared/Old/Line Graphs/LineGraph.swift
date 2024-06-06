////
////  LineGraph.swift
////  Fitness (iOS)
////
////  Created by Thomas Goss on 11/21/21.
////
//
//import SwiftUI
//
//struct LineGraph: View {
//    var points: [CGPoint]
//    var color: Color
//    var width: CGFloat
//    var dotted: Bool = false
//    
//    var body: some View {
//        Path { path in
//            path.move(to: CGPoint(x: points.first?.x ?? 0.0, y: points.first?.y ?? 0.0))
//            if points.count > 0 {
//                for i in 1..<points.count {
//                    path.addLine(to: points[i])
//                }
//            }
//        }
//        .stroke(style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: [dotted ? 5.0 : 1.0]))
//        .foregroundColor(color)
//    }
//    
//    static func numbersToPoints(points: [DateAndDouble], max: Double, min: Double, width: CGFloat, height: CGFloat) -> [CGPoint] {
//        let diff = max - min
//        let adjusted = points.map { DateAndDouble(date: $0.date, double: ($0.double - min) / diff) }
//        let startDate = points.map { $0.date }.min()!
//        let adjustedForDays = adjusted.map  {
//            (daysBetween: Date.daysBetween(date1: startDate, date2: $0.date) ?? 0, value: $0.double)
//        }
//        var points: [CGPoint] = []
//        // Handle x axis placement
//        let daysFromBeginningToEnd = adjustedForDays.map { $0.daysBetween }.sorted().last ?? 0
//        let widthIncrement = width / CGFloat(daysFromBeginningToEnd)
//        for i in 0..<adjustedForDays.count {
//            let s = CGFloat(adjustedForDays[i].daysBetween) * widthIncrement
//            points.append(CGPoint(x: s, y: CGFloat(adjustedForDays[i].value) * height))
//        }
//        let inverted = points.map { CGPoint(x: $0.x, y: height - $0.y) }
//        return inverted
//    }
//    
//    static func numbersToPoints(points: [DateAndDouble], endDate: Date = Date(), firstDate: Date, max: Double, min: Double, width: CGFloat, height: CGFloat) -> [CGPoint] {
//        let diff = max - min
//        let adjusted = points.map { DateAndDouble(date: $0.date, double: ($0.double - min) / diff) }
//
//        let adjustedForDays = adjusted.map  {
//            (daysBetween: Date.daysBetween(date1: firstDate, date2: $0.date) ?? 0, value: $0.double)
//        }
//        var points: [CGPoint] = []
//        // Handle x axis placement
//        let daysFromBeginningToEnd = Date.daysBetween(date1: firstDate, date2: endDate) ?? 0
//        let widthIncrement = width / CGFloat(daysFromBeginningToEnd)
//        for i in 0..<adjustedForDays.count {
//            let s = CGFloat(adjustedForDays[i].daysBetween) * widthIncrement
//            points.append(CGPoint(x: s, y: CGFloat(adjustedForDays[i].value) * height))
//        }
//        let inverted = points.map { CGPoint(x: $0.x, y: height - $0.y) }
//        return inverted
//    }
//    
//    struct GraphInformation {
//        var points: [DateAndDouble]
//        var type: LineGraphType
//    }
//}
//
//struct DateAndDouble: Codable {
//    var date: Date
//    var double: Double
//}
