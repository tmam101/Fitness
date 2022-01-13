//
//  LineGraph.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI

struct LineGraph: View {
    var points: [CGPoint]
    var color: Color
    var width: CGFloat
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: points.first?.x ?? 0.0, y: points.first?.y ?? 0.0))
            if points.count > 0 {
            for i in 1..<points.count {
                path.addLine(to: points[i])
            }
            }
        }
        .stroke(style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        .foregroundColor(color)
    }
    
    static func numbersToPoints(points: [Double], max: Double, min: Double, width: CGFloat, height: CGFloat) -> [CGPoint] {
        let diff = max - min
        let adjusted = points.map { ($0 - min) / diff }
        var points: [CGPoint] = []
        // Handle x axis placement
        let widthIncrement = width / CGFloat(adjusted.count - 1)
        for i in 0..<adjusted.count {
            let s = CGFloat(i) * widthIncrement
            points.append(CGPoint(x: CGFloat(s), y: CGFloat(adjusted[i]) * height))
        }
        let inverted = points.map { CGPoint(x: $0.x, y: height - $0.y) }
        return inverted
    }
}
