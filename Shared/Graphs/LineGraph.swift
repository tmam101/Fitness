//
//  LineGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 4/15/21.
//

import SwiftUI

struct LineGraph: View {
    // todo need fitness info to get access to weights
    @EnvironmentObject var fitness: FitnessCalculations
    var oneRepMaxes: [OneRepMax] = [OneRepMax(exerciseName: "Test", date: Date(), weight: 150)]
    var color: Color = .black
    
//    var points: [CGPoint] = [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 50.0, y: 50.0)]
    
    var body: some View {
        GeometryReader { geometry in
            let points = floatsToGraphCoordinates(oneRepMaxes: oneRepMaxes, width: geometry.size.width, height: geometry.size.height)

            Path { path in
                path.move(to: CGPoint(x: points.first?.x ?? 0.0, y: points.first?.y ?? 0.0))
                
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .foregroundColor(color)
//            let heightOffset = geometry.size.height - (geometry.size.height / CGFloat(horizontalRatio))
//            Rectangle()
//                .size(width: geometry.size.width, height: 2.0)
//                .offset(x: 0.0, y: heightOffset)
//                .foregroundColor(.gray)
        }
    }
    
    func floatsToGraphCoordinates(oneRepMaxes: [OneRepMax], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard oneRepMaxes.count != 0 else { return [CGPoint(x: 0, y: 0)] }
        var percentages: [Float] = []
        
        // Compare ORMs to bodyweight and create a ratio
        let adjustedOneRepMaxes = oneRepMaxes // one rep maxes
            .map { (name: $0.exerciseName, weights: Weight.closestTwoWeightsToDate(weights: fitness.weights, date: $0.date), date: $0.date, orm: $0.weight) } // get the body weights that each is between and the date
            .map { (name: $0.name, bodyweight: Weight.weightBetweenTwoWeights(date: $0.date, weight1: $0.weights?.first, weight2: $0.weights?.last), orm: $0.orm) } // get the average body weight
            .map { (name: $0.name, bodyweight: $0.bodyweight, orm: $0.orm, percentage: $0.orm / $0.bodyweight) }
        guard let first = oneRepMaxes.first else { return [CGPoint(x: 0, y: 0)] }
        
        // Normalize ORMS according to desired bodyweight ratio
        if first.exerciseName.contains("Squat") {
            percentages = adjustedOneRepMaxes.map{$0.percentage / 1.75}
        } else if first.exerciseName.contains("Bench") {
            percentages = adjustedOneRepMaxes.map{ $0.percentage / 1.5}
        }
        
        print("adjustedORMS: \(adjustedOneRepMaxes)")
        print("percentages: \(percentages)")
        
        // Create line graph
        // Handle y axis placement
        let max = percentages.max()!
        let min = percentages.min()!
        let diff = max - min
        let adjusted = percentages.map { ($0 - min) / diff }
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

struct LineGraph_Previews: PreviewProvider {
    static var previews: some View {
        LineGraph()
            .frame(width: 200, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}
