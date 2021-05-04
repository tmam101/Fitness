//
//  LineGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 4/15/21.
//

import SwiftUI

struct LineGraph: View {
    let weights: [Float] = [150.0, 160.0, 120.0, 200.0]
    var color: Color = .black
    
//    var points: [CGPoint] = [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 50.0, y: 50.0)]
    
    var body: some View {
        GeometryReader { geometry in
            let points = floatsToGraphCoordinates(weights: weights, width: geometry.size.width, height: geometry.size.height)

            Path { path in
                path.move(to: CGPoint(x: points.first?.x ?? 0.0, y: points.first?.y ?? 0.0))
                
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .foregroundColor(color)
        }
    }
    
    func floatsToGraphCoordinates(weights: [Float], width: CGFloat, height: CGFloat) -> [CGPoint] {
        let max = weights.max()!
        let min = weights.min()!
        let diff = max - min
        let adjusted = weights.map { ($0 - min) / diff }
        var points: [CGPoint] = []
        let widthIncrement = width / CGFloat(adjusted.count - 1)
        for i in 0..<adjusted.count {
            let s = CGFloat(i) * widthIncrement
            points.append(CGPoint(x: CGFloat(s), y: CGFloat(adjusted[i]) * height))
        }
        let inverted = points.map { CGPoint(x: $0.x, y: height - $0.y) }
        return inverted
    }
}

struct LineGraph_Previews: PreviewProvider {
    static var previews: some View {
        LineGraph()
            .frame(width: 200, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}
