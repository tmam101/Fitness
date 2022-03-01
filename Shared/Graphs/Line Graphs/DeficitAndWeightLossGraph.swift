//
//  DeficitAndWeightLossGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 1/25/22.
//

import SwiftUI

struct DeficitAndWeightLossGraph: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var healthData: HealthData
    @Binding var daysAgoToReach: Double
    
    var body: some View {
        let expectedWeights = healthData.expectedWeights
        let weights = fitness.weights
        VStack {
            GeometryReader { geometry in
                if weights.count > 0 && expectedWeights.count > 0 {
                    let deficitPoints = weightsToGraphCoordinates(daysAgoToReach: daysAgoToReach, graphType: .deficit, weights: weights, expectedWeights: expectedWeights, width: geometry.size.width - 40, height: geometry.size.height)
                    LineGraph(points: deficitPoints, color: .yellow, width: 2)
                    let weightLossPoints = weightsToGraphCoordinates(daysAgoToReach: daysAgoToReach, graphType: .weightLoss, weights: weights, expectedWeights: expectedWeights, width: geometry.size.width - 40, height: geometry.size.height)
                    LineGraph(points: weightLossPoints, color: .green, width: 2)
                }
            }
        }
    }


    func weightsToGraphCoordinates(daysAgoToReach: Double, graphType: LineGraphType, weights: [Weight], expectedWeights: [LineGraph.DateAndDouble], width: CGFloat, height: CGFloat) -> [CGPoint] {
        var weightValues: [LineGraph.DateAndDouble] = weights.map { LineGraph.DateAndDouble(date: $0.date, double: $0.weight)}
        weightValues = weightValues.reversed()
        let startDate = Date.subtract(days: Int(daysAgoToReach), from: Date())
        let weightsSuffix = weightValues.filter { $0.date >= startDate }
        var expectedWeightsSuffix = expectedWeights.filter { $0.date >= startDate }
//        let deficitOnDayOfFirstWeight = expectedWeightsSuffix.first(where: {Date.sameDay(date1: $0.date, date2: weightsSuffix.first?.date ?? Date())})
//        let differenceBetweenFirstWeightAndDeficit = (weightsSuffix.first?.double ?? 0) - (deficitOnDayOfFirstWeight?.double ?? 0)
//        expectedWeightsSuffix = expectedWeightsSuffix.map { LineGraph.DateAndDouble(date: $0.date, double: $0.double + differenceBetweenFirstWeightAndDeficit)}
        let weightMax = weightsSuffix.map { $0.double }.max() ?? 1
        let weightMin = weightsSuffix.map { $0.double }.min() ?? 0
        let expectedWeightMax = expectedWeightsSuffix.map { $0.double }.max() ?? 1
        let expectedWeightMin = expectedWeightsSuffix.map { $0.double }.min() ?? 0
        let max = max(weightMax, expectedWeightMax)
        let min = min(weightMin, expectedWeightMin)
        var pointsToUse: [LineGraph.DateAndDouble] = []
        switch graphType {
        case .deficit:
            pointsToUse = expectedWeightsSuffix
        case .weightLoss:
            pointsToUse = weightsSuffix
        }
        guard
            let firstWeightDate = weightsSuffix.map({ $0.date }).min(),
            let firstDeficitDate = expectedWeightsSuffix.map({ $0.date }).min(),
            let firstDate = [firstWeightDate, firstDeficitDate].min() else {
                return LineGraph.numbersToPoints(points: pointsToUse, max: max, min: min, width: width, height: height)
            }
        return LineGraph.numbersToPoints(points: pointsToUse, endDate: Date.subtract(days: -1, from: Date()), firstDate: firstDate, max: max, min: min, width: width, height: height)
    }
    
    struct Preview: View {
        @State var days: Double = 20
        @State var health = HealthData(environment: .debug)
        var body: some View {
            DeficitAndWeightLossGraph(daysAgoToReach: $days)
                .environmentObject(health)
                .environmentObject(health.fitness)
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 400)
                .padding()
                .background(Color.myGray)
                .cornerRadius(20)

        }
    }
}


struct DeficitAndWeightLossGraph_Previews: PreviewProvider {
    static var previews: some View {
        DeficitAndWeightLossGraph.Preview()
            .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
    }
}