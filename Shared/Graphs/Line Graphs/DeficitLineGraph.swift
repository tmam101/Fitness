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
        VStack {
            GeometryReader { geometry in
                if expectedWeights.count > 0 {
                    let startDate = Date.subtract(days: 6, from: Date())
                    let expectedWeightsSuffix = expectedWeights.filter { $0.date >= startDate }
                    let maxWeight = expectedWeightsSuffix.map { $0.double }.max() ?? 1
                    let minWeight = expectedWeightsSuffix.map { $0.double }.min() ?? 0
                    let firstWeightMinusTwoPounds = (expectedWeightsSuffix.first?.double ?? 1) - 2
                    let minValue = min(firstWeightMinusTwoPounds, minWeight)
                    LineAndLabel(width: geometry.size.width, height: 0.0, text: "\(Int(maxWeight))")
                    LineAndLabel(width: geometry.size.width, height: geometry.size.height * (1/2), text: "middle")
                    LineAndLabel(width: geometry.size.width, height: geometry.size.height, text: "\(Int(minValue))")
                    let points = weightsToGraphCoordinates(expectedWeights: expectedWeightsSuffix, width: geometry.size.width - 40, height: geometry.size.height)
                    LineGraph(points: points, color: color, width: 2)
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
    }
}
