//
//  LineGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 4/15/21.
//

import SwiftUI

struct LineGraph: View {
    var points: [CGPoint]
    var color: Color
    var width: CGFloat
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: points.first?.x ?? 0.0, y: points.first?.y ?? 0.0))
            
            for i in 1..<points.count {
                path.addLine(to: points[i])
            }
        }
        .stroke(style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        .foregroundColor(color)
    }
    
    static func numbersToPoints(points: [Double], max: Double, min: Double, width: CGFloat, height: CGFloat) -> [CGPoint] {
        let diff = max - min
        let adjusted = points.map { ($0 - min) / diff }
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

struct LiftingLineGraph: View {
    @EnvironmentObject var fitness: FitnessCalculations
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
        var percentages: [Double] = []
        
        // Compare ORMs to bodyweight and create a ratio
        let adjustedOneRepMaxes = oneRepMaxes // one rep maxes
            .map { (name: $0.exerciseName, weights: Weight.closestTwoWeightsToDate(weights: fitness.weights, date: $0.date), date: $0.date, orm: $0.weight) } // get the body weights that each is between and the date
            .map { (name: $0.name, bodyweight: Weight.weightBetweenTwoWeights(date: $0.date, weight1: $0.weights?.first, weight2: $0.weights?.last), orm: $0.orm) } // get the average body weight
            .map { (name: $0.name, bodyweight: $0.bodyweight, orm: $0.orm, percentage: $0.orm / $0.bodyweight) }
        guard let first = oneRepMaxes.first else { return [CGPoint(x: 0, y: 0)] }
        
        // Normalize ORMS according to desired bodyweight ratio
        if first.exerciseName.contains("Squat") {
            percentages = adjustedOneRepMaxes.map{$0.percentage / WorkoutInformation.squatBodyweightRatio}
        } else if first.exerciseName.contains("Bench") {
            percentages = adjustedOneRepMaxes.map{ $0.percentage / WorkoutInformation.benchBodyweightRatio}
        }
        
        // Create line graph
        // Handle y axis placement
        var max = percentages.max()!
        max = max > 1 ? max : 1
        let min = percentages.min()!
        return LineGraph.numbersToPoints(points: percentages, max: max, min: min, width: width, height: height)
    }
}

struct LineGraph_Previews: PreviewProvider {
    static var previews: some View {
        LiftingLineGraph()
            .frame(width: 200, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
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

struct RunningLineGraph: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var healthKit: MyHealthKit
    @State var presentingTest = false
    
    @State var runViewModel = RunViewModel()
    
    var color: Color = .blue
    
    var body: some View {
        GeometryReader { geometry in
            
            let numberOfRuns = runViewModel.numberOfRuns
            let runs = Array(healthKit.runs.suffix(numberOfRuns))
            let points = averagesToGraphCoordinates(runs: runs, width: geometry.size.width - 40, height: geometry.size.height)
            let max = runViewModel.max
            let min = runViewModel.min
            let x = (Double(max)-Double(min)) / 2
            let middle = Double(min) + x
            let isMiddleInt = floor(middle) == middle
            let middleText = isMiddleInt ? "\(Int(middle))" : String(format: "%.2f", middle)
            
            LineAndLabel(width: geometry.size.width, height: 0.0, text: "\(max)")
            LineAndLabel(width: geometry.size.width, height: geometry.size.height * (1/2), text: middleText)
            LineAndLabel(width: geometry.size.width, height: geometry.size.height, text: "\(runViewModel.min)")
            
            LineGraph(points: points, color: color, width: 2)
            
            if healthKit.runs.count > 0 {
                ForEach(0..<points.count, id: \.self) { index in
                    let width = (geometry.size.width / CGFloat(points.count)) - 2
                    Text("")
                        .frame(maxWidth: width, maxHeight: geometry.size.height)
                        .background(.white)
                        .opacity(0.00001)
                        .position(x: points[index].x, y: geometry.size.height / 2)
                        .onTapGesture {
                            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                            impactHeavy.impactOccurred()
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
    }
    
    class RunViewModel: ObservableObject {
        @Published var runClicked: Run = Run(date: Date(), totalDistance: 0, totalTime: 0, averageMileTime: 0, caloriesBurned: 0)
        @Published var max: Int = 0
        @Published var min: Int = 0
        @Published var numberOfRuns: Int = UserDefaults.standard.value(forKey: "numberOfRuns") as? Int ?? 5
    }
    
    struct RunView: View {
        @EnvironmentObject var runViewModel: RunViewModel
        
        var body: some View {
            ZStack {
                Color.myGray.edgesIgnoringSafeArea(.all)
                VStack(alignment:.leading) {
                    Text("Run\n")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    let floor = floor(runViewModel.runClicked.averageMileTime)
                    let x = floor - runViewModel.runClicked.averageMileTime
                    let y = x * -1
                    let z = Int(y * 60)
                    let s = z < 10 ? "0\(z)" : "\(z)"
                    let mileTimeString = "\(Int(floor)):\(s)"
                    let date = Calendar.current.dateComponents([.day, .month, .year], from: runViewModel.runClicked.date)
                    let year = String(date.year ?? 0).trimmingCharacters(in: [","])
                    let daysAgo = Date.daysBetween(date1: runViewModel.runClicked.date, date2: Date())
                    let dateString = "\(date.month ?? 0)/\(date.day ?? 0)/\(year)"
                    let daysAgoString = "\(daysAgo ?? 0) days ago"
                    
                    RunTextView(text: "Average Mile Time")
                    Text(mileTimeString)
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .padding([.bottom])
                    RunTextView(text: "Date")
                    RunTextView(text: dateString, isLarge: true)
                    RunTextView(text: daysAgoString)
                    RunTextView(text: "Distance")
                    RunTextView(number: runViewModel.runClicked.totalDistance, isLarge: true)
                    RunTextView(text: "Time")
                    RunTextView(number: runViewModel.runClicked.totalTime, isLarge: true)
                }
            }
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
    
    func averagesToGraphCoordinates(runs: [Run], width: CGFloat, height: CGFloat) -> [CGPoint] {
        let averages = runs.map { $0.averageMileTime }
        guard averages.count != 0 else { return [CGPoint(x: 0, y: 0)] }
        
        // Get the highest mile time and round up to a whole number
        var max = averages.max()!
        max.round(.up)
        max = max > 1 ? max : 1
        runViewModel.max = Int(max)
        
        // Get the lowest mile time and round up to a whole number
        var min = averages.min()!
        min.round(.down)
        runViewModel.min = Int(min)
        
        return LineGraph.numbersToPoints(points: averages, max: max, min: min, width: width, height: height)
    }
}
