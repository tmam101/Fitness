//
//  DeficitAndWeightLossGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 1/25/22.
//

import SwiftUI

struct DeficitAndWeightLossGraph: View {
    @EnvironmentObject var healthData: HealthData
    @Binding var daysAgoToReach: Double
    
    var body: some View {
        VStack {
            MainView(daysAgoToReach: $daysAgoToReach)
                .environmentObject(healthData)
            HStack {
                let dateToReach = Date.subtract(days: Int(daysAgoToReach), from: Date())
                
                Text(Date.stringFromDate(date: dateToReach))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.white)
                    .font(.system(size: 8))
                Text(Date.stringFromDate(date: Date()))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(x: -40)
                    .foregroundColor(.white)
                    .font(.system(size: 8))
            }.frame(maxWidth: .infinity)
        }
    }
    
    struct MainView: View {
        @EnvironmentObject var healthData: HealthData
        @Binding var daysAgoToReach: Double
        
        var body: some View {
            let expectedWeights = healthData.calorieManager.expectedWeights
            let weights = healthData.weightManager.weights
            let dateToReach = Date.subtract(days: Int(daysAgoToReach), from: Date())
            let weightsFiltered = weights.filter { $0.date >= dateToReach }.map { $0.weight }
            let expectedWeightsFiltered = expectedWeights.filter { $0.date >= dateToReach }.map { $0.double }
            VStack {
                GeometryReader { geometry in
                    if weights.count > 0 && expectedWeights.count > 0 {
                        if Settings.get(key: .showLinesOnWeightGraph) as? Bool ?? true {
                            let maxWeight = weightsFiltered.max()
                            let maxExpecteWeight = expectedWeightsFiltered.max()
                            let minWeight = weightsFiltered.min()
                            let minExpecteWeight = expectedWeightsFiltered.min()
                            let realMax = [maxWeight ?? 0, maxExpecteWeight ?? 0].max() ?? 1
                            let realMin = [minWeight ?? 0, minExpecteWeight ?? 0].min() ?? 0
                            let roundedMax = Int(realMax.rounded(.down))
                            let roundedMin = Int(realMin.rounded(.up))
                            ForEach(roundedMin...roundedMax, id: \.self) { i in
                                //todo this isnt quite right
                                let diff = realMax - realMin
                                let y = 100.0 / diff
                                let thisDiff = realMax - Double(i)
                                let x = thisDiff * y
                                let heightPercentage = x / 100.0
                                //                        LineAndLabel(width: geometry.size.width, height: geometry.size.height - ((Double(i) / realMax) * geometry.size.height), text: "\(i)")
                                LineAndLabel(width: geometry.size.width, height: geometry.size.height * heightPercentage, text: "\(i)")
                                
                            }
                        }
                        let realisticWeightDateAndDouble = healthData.realisticWeights.map { LineGraph.DateAndDouble(date: Date.subtract(days: $0.key - 1, from: Date()), double: $0.value) }.sorted { $0.date < $1.date}
                        let weightElements = LineGraph.GraphInformation(points: weights.map { LineGraph.DateAndDouble(date: $0.date, double: $0.weight)}.reversed(), type: .weightLoss)
                        let deficitElements = LineGraph.GraphInformation(points: expectedWeights, type: .deficit)
                        let realisticWeightElements = LineGraph.GraphInformation(points: realisticWeightDateAndDouble, type: .realisticWeightLoss)
                        let deficitPoints = DeficitAndWeightLossGraph.weightsToGraphCoordinates(daysAgoToReach: daysAgoToReach, graphType: .deficit, elements: [weightElements, deficitElements, realisticWeightElements], width: geometry.size.width - 40, height: geometry.size.height)
                        let weightLossPoints = DeficitAndWeightLossGraph.weightsToGraphCoordinates(daysAgoToReach: daysAgoToReach, graphType: .weightLoss, elements: [weightElements, deficitElements, realisticWeightElements], width: geometry.size.width - 40, height: geometry.size.height)
                        let realisticWeightPoints = DeficitAndWeightLossGraph.weightsToGraphCoordinates(daysAgoToReach: daysAgoToReach, graphType: .realisticWeightLoss, elements: [weightElements, deficitElements, realisticWeightElements], width: geometry.size.width - 40, height: geometry.size.height)
                        LineGraph(points: deficitPoints, color: .yellow, width: 2)
                        LineGraph(points: weightLossPoints, color: .green, width: 2)
                        LineGraph(points: realisticWeightPoints, color: .green.opacity(0.5), width: 2, dotted: true)
                    }
                }
            }
        }
    }

    //todo this reloads everytime we change the day amount, which is expensive. but it can change based on changing health data. maybe call this manually somewhere?
    static func weightsToGraphCoordinates(daysAgoToReach: Double, graphType: LineGraphType, elements: [LineGraph.GraphInformation], width: CGFloat, height: CGFloat) -> [CGPoint] {
        let startDate = Date.subtract(days: Int(daysAgoToReach), from: Date())
        let filteredByDate = elements.map { LineGraph.GraphInformation(points: $0.points.filter { $0.date >= startDate }, type: $0.type)}
        let allWeights = Array(filteredByDate.map { $0.points.map { $0.double }}.joined())
        let max = allWeights.max() ?? 1
        let min = allWeights.min() ?? 0
        let pointsToUse: [LineGraph.DateAndDouble] = filteredByDate.first(where: { $0.type == graphType })!.points
        let firstDate = Array(filteredByDate.map { $0.points.map { $0.date }}.joined()).min()!
        return LineGraph.numbersToPoints(points: pointsToUse, endDate: Date.subtract(days: -1, from: Date()), firstDate: firstDate, max: max, min: min, width: width, height: height)
    }
    
    struct Preview: View {
        @State var days: Double = 20
        @State var health = HealthData(environment: .debug)
        var body: some View {
            DeficitAndWeightLossGraph(daysAgoToReach: $days)
                .environmentObject(health)
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
