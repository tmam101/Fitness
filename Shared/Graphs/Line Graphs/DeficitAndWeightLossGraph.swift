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
            VStack {
                GeometryReader { geometry in
                    
                    let vm = DeficitAndWeightLossGraph_ViewModel(healthData: healthData, daysAgoToReach: daysAgoToReach - 1, geometry: geometry)

                    if vm.weights.count > 0 && vm.expectedWeights.count > 0 {
                        if Settings.get(key: .showLinesOnWeightGraph) as? Bool ?? true {
                            ForEach(vm.roundedMin...vm.roundedMax, id: \.self) { i in
                                LineAndLabel(width: geometry.size.width, height: geometry.size.height * vm.heightPercentage(i: i), text: "\(i)")
                            }
                        }
                        
                        LineGraph(points: vm.deficitPoints, color: .yellow, width: 2)
                        LineGraph(points: vm.weightLossPoints, color: .green, width: 2)
                        LineGraph(points: vm.realisticWeightPoints, color: .green.opacity(0.5), width: 2, dotted: true)
                    }
                }
            }
        }
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

/// View Model for the DeficitAndWeightLossGraph.
struct DeficitAndWeightLossGraph_ViewModel {
    // TODO: Don't pass in healthData, pass in just what's needed.
    var healthData: HealthData
    var daysAgoToReach: Double
    var geometry: GeometryProxy
    var dateToReach: Date
    
    var expectedWeights: [DateAndDouble] = []
    var weights: [Weight] = []
    var weightsFiltered: [Double] = []
    var expectedWeightsFiltered: [Double] = []
    var deficitPoints: [CGPoint] = []
    var weightLossPoints: [CGPoint] = []
    var realisticWeightPoints: [CGPoint] = []
    var roundedMin = 0
    var roundedMax = 1
    var realMax: Double = 1
    var realMin: Double = 0
    
    init(healthData: HealthData, daysAgoToReach: Double, geometry: GeometryProxy) {
        self.healthData = healthData
        self.daysAgoToReach = daysAgoToReach
        self.geometry = geometry
        self.dateToReach = Date.subtract(days: Int(daysAgoToReach), from: Date())

        setup()
    }
    
    mutating func setup() {
        self.expectedWeights = healthData.calorieManager.expectedWeights
        self.weights = healthData.weightManager.weights
        self.weightsFiltered = self.weights.filter { $0.date >= dateToReach }.map { $0.weight }
        self.expectedWeightsFiltered = expectedWeights.filter { $0.date >= dateToReach }.map { $0.double }
        
        let realisticWeightDateAndDouble = healthData.realisticWeights.map { DateAndDouble(date: Date.subtract(days: $0.key - 1, from: Date()), double: $0.value) }.sorted { $0.date < $1.date}
        let weightElements = LineGraph.GraphInformation(points: self.weights.map { DateAndDouble(date: $0.date, double: $0.weight)}.sorted { $0.date < $1.date }, type: .weightLoss)
        let deficitElements = LineGraph.GraphInformation(points: self.expectedWeights, type: .deficit)
        let realisticWeightElements = LineGraph.GraphInformation(points: realisticWeightDateAndDouble, type: .realisticWeightLoss)
        let elements = [weightElements, deficitElements, realisticWeightElements]
        let width = geometry.size.width - 40
        let height = geometry.size.height
        self.deficitPoints = self.weightsToGraphCoordinates(daysAgoToReach: daysAgoToReach, graphType: .deficit, elements: elements, width: width, height: height)
        self.weightLossPoints = self.weightsToGraphCoordinates(daysAgoToReach: daysAgoToReach, graphType: .weightLoss, elements: elements, width: width, height: height)
        self.realisticWeightPoints = self.weightsToGraphCoordinates(daysAgoToReach: daysAgoToReach, graphType: .realisticWeightLoss, elements: elements, width: width, height: height)
        
        self.realMax = max(weightsFiltered.max() ?? 1, expectedWeightsFiltered.max() ?? 1)
        self.realMin = min(weightsFiltered.min() ?? 0, expectedWeightsFiltered.min() ?? 0)
        self.roundedMax = Int(realMax.rounded(.down))
        self.roundedMin = Int(realMin.rounded(.up))
    }
    
    typealias TypeAndPoints = (type: LineGraphType, points: [CGPoint])
    
    func points(elements: [LineGraph.GraphInformation], height: CGFloat, width: CGFloat, types: [LineGraphType]) -> [TypeAndPoints] {
        let points = types.map {
            (type: $0, points: self.weightsToGraphCoordinates(daysAgoToReach: daysAgoToReach, graphType: $0, elements: elements, width: width, height: height))
        }
        return points
    }
    
    func heightPercentage(i: Int) -> Double {
        let diff = realMax - realMin
        let y = 100.0 / diff
        let thisDiff = realMax - Double(i)
        let x = thisDiff * y
        let heightPercentage = x / 100.0
        return heightPercentage
    }
    
    //TODO: What if this accepted an array of days, and we could take the points from each day, like expected weight, real weight, realistic weight?
    //TODO: this reloads everytime we change the day amount, which is expensive. but it can change based on changing health data. maybe call this manually somewhere?
    func weightsToGraphCoordinates(daysAgoToReach: Double, graphType: LineGraphType, elements: [LineGraph.GraphInformation], width: CGFloat, height: CGFloat) -> [CGPoint] {
        let noPoints = elements
                .map { $0.points.count }
                .filter { $0 != 0}
                .isEmpty
        guard !noPoints else { return []}
        
        let startDate = Date.subtract(days: Int(daysAgoToReach), from: Date())
        let filteredByDate = elements.map { LineGraph.GraphInformation(points: $0.points.filter { $0.date >= startDate }, type: $0.type)}
        let allWeights = Array(filteredByDate.map { $0.points.map { $0.double }}.joined())
        let max = allWeights.max() ?? 1
        let min = allWeights.min() ?? 0
        let pointsToUse: [DateAndDouble] = filteredByDate.first(where: { $0.type == graphType })!.points
        let firstDate = Array(filteredByDate.map { $0.points.map { $0.date }}.joined()).min()!
        return LineGraph.numbersToPoints(points: pointsToUse, endDate: Date.subtract(days: -1, from: Date()), firstDate: firstDate, max: max, min: min, width: width, height: height)
    }
}
