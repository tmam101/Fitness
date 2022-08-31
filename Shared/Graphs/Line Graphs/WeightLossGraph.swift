//
//  WeightLossGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 1/25/22.
//

import SwiftUI

struct WeightLossGraph: View {
    @EnvironmentObject var healthData: HealthData
    var color: Color = .green
    
    var body: some View {
        let expectedWeights = healthData.calorieManager.expectedWeights
        let weights = healthData.weightManager.weights
        VStack {
            GeometryReader { geometry in
                if weights.count > 0 && expectedWeights.count > 0 {
                    let points = weightsToGraphCoordinates(weights: weights, expectedWeights: expectedWeights, width: geometry.size.width - 40, height: geometry.size.height)
                    LineGraph(points: points, color: color, width: 2)
                }
            }
        }
    }
    
    func weightsToGraphCoordinates(weights: [Weight], expectedWeights: [DateAndDouble], width: CGFloat, height: CGFloat) -> [CGPoint] {
        var weightValues: [DateAndDouble] = weights.map { DateAndDouble(date: $0.date, double: $0.weight)}
        weightValues = weightValues.reversed()
        let startDate = Date.subtract(days: 350, from: Date())
        let weightsSuffix = weightValues.filter { $0.date >= startDate }
        var expectedWeightsSuffix = expectedWeights.filter { $0.date >= startDate }
        let deficitOnDayOfFirstWeight = expectedWeightsSuffix.first(where: {Date.sameDay(date1: $0.date, date2: weightsSuffix.first?.date ?? Date())})
        let differenceBetweenFirstWeightAndDeficit = (weightsSuffix.first?.double ?? 0) - (deficitOnDayOfFirstWeight?.double ?? 0)
        expectedWeightsSuffix = expectedWeightsSuffix.map { DateAndDouble(date: $0.date, double: $0.double + differenceBetweenFirstWeightAndDeficit)}
        let weightMax = weightsSuffix.map { $0.double }.max() ?? 1
        let weightMin = weightsSuffix.map { $0.double }.min() ?? 0
        let expectedWeightMax = expectedWeightsSuffix.map { $0.double }.max() ?? 1
        let expectedWeightMin = expectedWeightsSuffix.map { $0.double }.min() ?? 0
        let max = max(weightMax, expectedWeightMax)
        let min = min(weightMin, expectedWeightMin)
        guard
            let firstWeightDate = weightsSuffix.map({ $0.date }).min(),
            let firstDeficitDate = expectedWeightsSuffix.map({ $0.date }).min(),
            let firstDate = [firstWeightDate, firstDeficitDate].min() else {
                return LineGraph.numbersToPoints(points: weightsSuffix, max: max, min: min, width: width, height: height)
            }
        return LineGraph.numbersToPoints(points: weightsSuffix, firstDate: firstDate, max: max, min: min, width: width, height: height)
    }
}

struct WeightLossGraph_Previews: PreviewProvider {
    static var previews: some View {
        WeightLossGraph()
    }
}
