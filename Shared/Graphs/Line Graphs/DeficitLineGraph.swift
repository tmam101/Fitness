import SwiftUI

enum LineGraphType {
    case deficit
    case weightLoss
}

struct DeficitLineGraph: View {
    @EnvironmentObject var healthData: HealthData
    var color: Color = .yellow
    
    var body: some View {
        let expectedWeights = healthData.expectedWeights
        let startDate = Date.subtract(days: 6, from: Date())
        let expectedWeightsSuffix = expectedWeights.filter { $0.date >= startDate }
//                    let maxWeight = expectedWeightsSuffix.map { $0.double }.max() ?? 1
        let firstWeight: Double = expectedWeightsSuffix.first?.double ?? 1
        let minWeight: Double = expectedWeightsSuffix.map { $0.double }.min() ?? 0
        let firstWeightMinusTwoPounds: Double = firstWeight - 2
        let minValue: Double = min(firstWeightMinusTwoPounds, minWeight)
        let middleValue: Double = firstWeight - ((firstWeight - minValue) / 2)
        
        VStack {
            GeometryReader { geometry in
                if expectedWeights.count > 0 {
                    
                    let points = weightsToGraphCoordinates(expectedWeights: expectedWeightsSuffix, width: geometry.size.width - 75, height: geometry.size.height)
                    let topLineHeight = points.first?.y ?? 0.0
                    let middleLineHeight = topLineHeight + (geometry.size.height - topLineHeight) / 2
                    LineAndLabel(width: geometry.size.width, height: topLineHeight, text: String(format: "%.2f", Double(firstWeight)))
                    LineAndLabel(width: geometry.size.width, height: middleLineHeight, text: String(format: "%.2f", Double(middleValue)))
                    LineAndLabel(width: geometry.size.width, height: geometry.size.height, text: String(format: "%.2f", Double(minValue)))
                    LineGraph(points: points, color: color, width: 2)
                        .padding([.leading], 25)
                }
            }
        }.padding()
    }
    
    func weightsToGraphCoordinates(expectedWeights: [LineGraph.DateAndDouble], width: CGFloat, height: CGFloat) -> [CGPoint] {
//        let startDate = Date.subtract(days: 6, from: Date())
//        let expectedWeightsSuffix = expectedWeights.filter { $0.date >= startDate }
        let expectedWeightMax = expectedWeights.map { $0.double }.max() ?? 1
        var expectedWeightMin = expectedWeights.map { $0.double }.min() ?? 0
        let firstWeightMinusTwoPounds = (expectedWeights.first?.double ?? 1) - 2
        expectedWeightMin = min(firstWeightMinusTwoPounds, expectedWeightMin)
        guard
            let firstDate = expectedWeights.map({ $0.date }).min(),
            let endDate = expectedWeights.map({ $0.date }).max() else {
                return LineGraph.numbersToPoints(points: expectedWeights, max: expectedWeightMax, min: expectedWeightMin, width: width, height: height)
            }
        return LineGraph.numbersToPoints(points: expectedWeights, endDate: endDate, firstDate: firstDate, max: expectedWeightMax, min: expectedWeightMin, width: width, height: height)
    }
}

struct DeficitLineGraph_Previews: PreviewProvider {
    static var previews: some View {
        DeficitLineGraph()
            .environmentObject(HealthData(environment: .debug))
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 200)
            .padding()
            .background(Color.myGray)
            .cornerRadius(20)
            .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
//        AppView()
//            .environmentObject(HealthData(environment: .debug))
//            .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
    }
}
