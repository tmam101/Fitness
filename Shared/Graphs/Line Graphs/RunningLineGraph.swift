//
//  RunningLineGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI

struct DeficitLineGraph: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var healthData: HealthData
    var color: Color = .yellow
    
    var body: some View {
        let expectedWeights = healthData.expectedWeights
        let weights = fitness.weights
        VStack {
            GeometryReader { geometry in
                if weights.count > 0 && expectedWeights.count > 0 {
                    let points = weightsToGraphCoordinates(weights: weights, expectedWeights: expectedWeights, width: geometry.size.width - 40, height: geometry.size.height)
                    LineGraph(points: points, color: color, width: 2)
                }
            }
        }
    }
    
    func weightsToGraphCoordinates(weights: [Weight], expectedWeights: [LineGraph.DateAndDouble], width: CGFloat, height: CGFloat) -> [CGPoint] {
        var weightValues: [LineGraph.DateAndDouble] = weights.map { LineGraph.DateAndDouble(date: $0.date, double: $0.weight)}
        weightValues = weightValues.reversed()
        let weightMax = weightValues.map { $0.double }.max() ?? 1
        let weightMin = weightValues.map { $0.double }.min() ?? 0
        let expectedWeightMax = expectedWeights.map { $0.double }.max() ?? 1
        let expectedWeightMin = expectedWeights.map { $0.double }.min() ?? 0
        let max = max(weightMax, expectedWeightMax)
        let min = min(weightMin, expectedWeightMin)
        return LineGraph.numbersToPoints(points: expectedWeights, max: max, min: min, width: width, height: height)
    }
}

struct WeightLossGraph: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var healthData: HealthData
    var color: Color = .green
    
    var body: some View {
        let expectedWeights = healthData.expectedWeights
        let weights = fitness.weights
        VStack {
            GeometryReader { geometry in
                if weights.count > 0 && expectedWeights.count > 0 {
                    let points = weightsToGraphCoordinates(weights: weights, expectedWeights: expectedWeights, width: geometry.size.width - 40, height: geometry.size.height)
                    LineGraph(points: points, color: color, width: 2)
                }
            }
        }
    }
    
    func weightsToGraphCoordinates(weights: [Weight], expectedWeights: [LineGraph.DateAndDouble], width: CGFloat, height: CGFloat) -> [CGPoint] {
        var weightValues: [LineGraph.DateAndDouble] = weights.map { LineGraph.DateAndDouble(date: $0.date, double: $0.weight)}
        weightValues = weightValues.reversed()
        let weightMax = weightValues.map { $0.double }.max() ?? 1
        let weightMin = weightValues.map { $0.double }.min() ?? 0
        let expectedWeightMax = expectedWeights.map { $0.double }.max() ?? 1
        let expectedWeightMin = expectedWeights.map { $0.double }.min() ?? 0
        let max = max(weightMax, expectedWeightMax)
        let min = min(weightMin, expectedWeightMin)
        return LineGraph.numbersToPoints(points: weightValues, max: max, min: min, width: width, height: height)
    }
}

struct RunningLineGraph: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var healthData: HealthData
    @State var presentingTest = false
    
    @State var runViewModel = RunViewModel()
    
    var color: Color = .blue
    
    var body: some View {
        
        let numberOfRuns = healthData.numberOfRuns
        let runs = Array(healthData.runs.suffix(numberOfRuns))
        let max = runViewModel.max
        let min = runViewModel.min
        let x = (Double(max)-Double(min)) / 2
        let middle = Double(min) + x
        
        VStack {
            GeometryReader { geometry in
                let points = averagesToGraphCoordinates(runs: runs, width: geometry.size.width - 40, height: geometry.size.height)
                
                LineAndLabel(width: geometry.size.width, height: 0.0, text: "\(Time.doubleToString(double: max))")
                LineAndLabel(width: geometry.size.width, height: geometry.size.height * (1/2), text: Time.doubleToString(double: middle))
                LineAndLabel(width: geometry.size.width, height: geometry.size.height, text: "\(Time.doubleToString(double: min))")
                
                LineGraph(points: points, color: color, width: 2)
                
                if healthData.runs.count > 0 {
                    ForEach(0..<points.count, id: \.self) { index in
                        let width = (geometry.size.width / CGFloat(points.count)) - 2
                        Text("")
                            .frame(maxWidth: width, maxHeight: geometry.size.height)
                            .background(.white)
                            .opacity(0.00001)
                            .position(x: points[index].x, y: geometry.size.height / 2)
                            .onTapGesture {
#if !os(watchOS)
                                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                                impactHeavy.impactOccurred()
#endif
                                self.presentingTest = true
                                runViewModel.runClicked = runs[index]
                            }
                            .sheet(isPresented: $presentingTest, onDismiss: {
                                self.presentingTest = false
                            }) {
                                RunView()
                                    .environmentObject(runViewModel)
                                    .background(Color.myGray.edgesIgnoringSafeArea(.all))
                            }
                    }
                }
            }
            HStack {
                Text(Date.stringFromDate(date: runs.first?.date ?? Date()))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.white)
                    .font(.system(size: 8))
                Text(Date.stringFromDate(date: runs.last?.date ?? Date()))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(x: -40)
                    .foregroundColor(.white)
                    .font(.system(size: 8))
            }.frame(maxWidth: .infinity)
        }
    }
    
    func averagesToGraphCoordinates(runs: [Run], width: CGFloat, height: CGFloat) -> [CGPoint] {
        let averages: [LineGraph.DateAndDouble] = runs.map { LineGraph.DateAndDouble(date: $0.date, double: $0.averageMileTime) }
        guard averages.count != 0 else { return [CGPoint(x: 0, y: 0)] }
        
        // Get the highest mile time and round up to a whole number
        var max = averages.map { $0.double }.max()!
        var rounded = max.rounded(.up)
        var roundedDifference = rounded - max
        if roundedDifference > 0.5 {
            max = rounded - 0.5
        } else {
            max = rounded
        }
        max = max > 1 ? max : 1
        runViewModel.max = max
        
        // Get the lowest mile time and round up to a whole number
        var min = averages.map { $0.double }.min()!
        rounded = min.rounded(.down)
        roundedDifference = min - rounded
        if roundedDifference > 0.5 {
            min = rounded + 0.5
        } else {
            min = rounded
        }
        runViewModel.min = min
        return LineGraph.numbersToPoints(points: averages, max: max, min: min, width: width, height: height)
    }
}

struct LineAndLabel: View {
    var width: CGFloat
    var height: CGFloat
    var text: String
    
    let lineWidthOffset: CGFloat = 40
    let lineHeight: CGFloat = 0.5
    let lineOpacity: CGFloat = 0.5
    let labelWidth: CGFloat = 50
    let labelFontSize: CGFloat = 8
    let labelPosition: CGFloat = 20
    
    var body: some View {
        Rectangle()
            .size(width: width - lineWidthOffset, height: lineHeight)
            .foregroundColor(.white)
            .opacity(lineOpacity)
            .offset(y: height)
        Text(text)
            .font(.system(size: labelFontSize))
            .frame(maxWidth: labelWidth)
            .position(x: width - labelPosition)
            .offset(y: height)
            .foregroundColor(.white)
    }
}

class RunViewModel: ObservableObject {
    @Published var runClicked: Run = Run(date: Date(), totalDistance: 0, totalTime: 0, averageMileTime: 0, caloriesBurned: 0, weightAtTime: 0)
    @Published var max: Double = 0
    @Published var min: Double = 0
}

struct RunTexts: View {
    @EnvironmentObject var runViewModel: RunViewModel
    
    var body: some View {
        //        RunTextView(text: "Weight")
        Text("Weight")
        Text("\(runViewModel.runClicked.weightAtTime)")
        //        RunTextView(number: runViewModel.runClicked.weightAtTime, isLarge: true)
    }
}

struct RunView: View {
    @EnvironmentObject var runViewModel: RunViewModel
    
    var body: some View {
        ZStack {
            Color.myGray.edgesIgnoringSafeArea(.all)
            VStack(alignment:.leading) {
                //                let mileTimeString = Time.doubleToString(double: runViewModel.runClicked.averageMileTime)
                //                let date = Calendar.current.dateComponents([.day, .month, .year], from: runViewModel.runClicked.date)
                //                let year = String(date.year ?? 0).trimmingCharacters(in: [","])
                //                let daysAgo = Date.daysBetween(date1: runViewModel.runClicked.date, date2: Date())
                //                let dateString = "\(date.month ?? 0)/\(date.day ?? 0)/\(year)"
                //                let daysAgoString = "\(daysAgo ?? 0) days ago"
                //                Group{
                Text("Run")
                //                }
                let values = getValues()
                
                Text("Average Mile Time")
                Text(values.mileTimeString)
                    .font(.system(size: 90))
                    .foregroundColor(.blue)
                    .padding([.bottom])
                //                RunTextView(text: "Date")
                //                RunTextView(text: dateString, isLarge: true)
                //                RunTextView(text: daysAgoString)
                //                RunTextView(text: "Distance")
                //                RunTextView(number: runViewModel.runClicked.totalDistance, isLarge: true)
                //                RunTextView(text: "Time")
                //                RunTextView(number: runViewModel.runClicked.totalTime, isLarge: true)
                Text("Date")
                Text(values.dateString)
                Text(values.daysAgoString)
                Text("Distance")
                Text("\(runViewModel.runClicked.totalDistance)")
                Text("Time")
                Text("\(runViewModel.runClicked.totalTime)")
                //                Text("Weight")
                //                Text("\(runViewModel.runClicked.weightAtTime)")
            }
        }
    }
    func getValues() -> (mileTimeString: String, dateString: String, daysAgoString: String) {
        let mileTimeString = Time.doubleToString(double: runViewModel.runClicked.averageMileTime)
        let date = Calendar.current.dateComponents([.day, .month, .year], from: runViewModel.runClicked.date)
        let year = String(date.year ?? 0).trimmingCharacters(in: [","])
        let daysAgo = Date.daysBetween(date1: runViewModel.runClicked.date, date2: Date())
        let dateString = "\(date.month ?? 0)/\(date.day ?? 0)/\(year)"
        let daysAgoString = "\(daysAgo ?? 0) days ago"
        return (mileTimeString: mileTimeString, dateString: dateString, daysAgoString: daysAgoString)
    }
}

struct RunTextView: View {
    var text: String? = nil
    var number: Double? = nil
    var isLarge = false
    var color: Color = .white
    
    var body: some View {
        let textExists = !(text == nil)
        let numberExists = !(number == nil)
        let t: String = textExists ? text! : (numberExists ? String(format: "%.2f", number!) : "")
        Text(t)
            .font(isLarge ? .title : .body)
            .foregroundColor(color)
    }
}
