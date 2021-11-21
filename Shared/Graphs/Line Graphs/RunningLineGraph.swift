//
//  RunningLineGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 11/21/21.
//

import SwiftUI

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
            
            let numberOfRuns = healthKit.numberOfRuns
            let runs = Array(healthKit.runs.suffix(numberOfRuns))
            let points = averagesToGraphCoordinates(runs: runs, width: geometry.size.width - 40, height: geometry.size.height)
            let max = runViewModel.max
            let min = runViewModel.min
            let x = (Double(max)-Double(min)) / 2
            let middle = Double(min) + x
            
            LineAndLabel(width: geometry.size.width, height: 0.0, text: "\(Time.doubleToString(double: max))")
            LineAndLabel(width: geometry.size.width, height: geometry.size.height * (1/2), text: Time.doubleToString(double: middle))
            LineAndLabel(width: geometry.size.width, height: geometry.size.height, text: "\(Time.doubleToString(double: min))")
            
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
    
    func averagesToGraphCoordinates(runs: [Run], width: CGFloat, height: CGFloat) -> [CGPoint] {
        let averages = runs.map { $0.averageMileTime }
        guard averages.count != 0 else { return [CGPoint(x: 0, y: 0)] }
        
        // Get the highest mile time and round up to a whole number
        var max = averages.max()!
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
        var min = averages.min()!
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
class RunViewModel: ObservableObject {
    @Published var runClicked: Run = Run(date: Date(), totalDistance: 0, totalTime: 0, averageMileTime: 0, caloriesBurned: 0)
    @Published var max: Double = 0
    @Published var min: Double = 0
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
                
                let mileTimeString = Time.doubleToString(double: runViewModel.runClicked.averageMileTime)
                let date = Calendar.current.dateComponents([.day, .month, .year], from: runViewModel.runClicked.date)
                let year = String(date.year ?? 0).trimmingCharacters(in: [","])
                let daysAgo = Date.daysBetween(date1: runViewModel.runClicked.date, date2: Date())
                let dateString = "\(date.month ?? 0)/\(date.day ?? 0)/\(year)"
                let daysAgoString = "\(daysAgo ?? 0) days ago"
                
                RunTextView(text: "Average Mile Time")
                Text(mileTimeString)
                    .font(.system(size: 90))
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
