//
//  LineGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 4/15/21.
//

import SwiftUI

struct LiftingLineGraph: View {
    @EnvironmentObject var healthData: HealthData
    
    var oneRepMaxes: [OneRepMax] = [OneRepMax(exerciseName: "Test", date: Date(), weight: 150)]
    var color: Color = .black
    
    var body: some View {
        GeometryReader { geometry in
            let points = oneRepMaxesToGraphCoordinates(oneRepMaxes: oneRepMaxes, width: geometry.size.width, height: geometry.size.height)
            
            LineGraph(points: points, color: color, width: 5)
            Rectangle()
                .size(width: geometry.size.width, height: 2.0)
                .offset(x: 0.0, y: 0.0)
                .foregroundColor(.gray)
        }
    }
    
    func oneRepMaxesToGraphCoordinates(oneRepMaxes: [OneRepMax], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard oneRepMaxes.count != 0 else { return [CGPoint(x: 0, y: 0)] }
        var percentages: [DateAndDouble] = []
        
        // Compare ORMs to bodyweight and create a ratio
        let adjustedOneRepMaxes = oneRepMaxes // one rep maxes
            .map { (name: $0.exerciseName, weights: Weight.closestTwoWeightsToDate(weights: healthData.weightManager.weights, date: $0.date), date: $0.date, orm: $0.weight) } // get the body weights that each is between and the date
            .map { (name: $0.name, bodyweight: Weight.weightBetweenTwoWeights(date: $0.date, weight1: $0.weights?.first, weight2: $0.weights?.last), date: $0.date, orm: $0.orm) } // get the average body weight
            .map { (name: $0.name, bodyweight: $0.bodyweight, date: $0.date, orm: $0.orm, percentage: $0.orm / $0.bodyweight) }
        guard let first = oneRepMaxes.first else { return [CGPoint(x: 0, y: 0)] }
        
        // Normalize ORMS according to desired bodyweight ratio
        if first.exerciseName.contains("Squat") {
            percentages = adjustedOneRepMaxes.map{ DateAndDouble(date: $0.date, double: $0.percentage / WorkoutManager.squatBodyweightRatio) }
        } else if first.exerciseName.contains("Bench") {
            percentages = adjustedOneRepMaxes.map{ DateAndDouble(date: $0.date, double: $0.percentage / WorkoutManager.benchBodyweightRatio) }
        }
        
        // Create line graph
        // Handle y axis placement
        var max = percentages.map { $0.double }.max()!
        max = max > 1 ? max : 1
        let min = percentages.map { $0.double }.min()!
        return LineGraph.numbersToPoints(points: percentages, max: max, min: min, width: width, height: height)
    }
}
