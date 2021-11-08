//
//  LineGraph.swift
//  Fitness
//
//  Created by Thomas Goss on 4/15/21.
//

import SwiftUI

struct LineGraph: View {
    @EnvironmentObject var fitness: FitnessCalculations
    var oneRepMaxes: [OneRepMax] = [OneRepMax(exerciseName: "Test", date: Date(), weight: 150)]
    var color: Color = .black
        
    var body: some View {
        GeometryReader { geometry in
            let points = floatsToGraphCoordinates(oneRepMaxes: oneRepMaxes, width: geometry.size.width, height: geometry.size.height)

            Path { path in
                path.move(to: CGPoint(x: points.first?.x ?? 0.0, y: points.first?.y ?? 0.0))
                
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .foregroundColor(color)
            Rectangle()
                .size(width: geometry.size.width, height: 2.0)
                .offset(x: 0.0, y: 0.0)
                .foregroundColor(.gray)
        }
    }
    
    func floatsToGraphCoordinates(oneRepMaxes: [OneRepMax], width: CGFloat, height: CGFloat) -> [CGPoint] {
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
        
        print("adjustedORMS: \(adjustedOneRepMaxes)")
        print("percentages: \(percentages)")
        
        // Create line graph
        // Handle y axis placement
        var max = percentages.max()!
        max = max > 1 ? max : 1
        let min = percentages.min()!
        let diff = max - min
        let adjusted = percentages.map { ($0 - min) / diff }
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

struct LineGraph_Previews: PreviewProvider {
    static var previews: some View {
        LineGraph()
            .frame(width: 200, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}

struct RunningLineGraph: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var healthKit: MyHealthKit
    @State var presentingTest = false
    
    @State var runViewModel = RunViewModel()
    
//    var runningAverages: [Double] = []
    var color: Color = .blue
    
    var body: some View {
        GeometryReader { geometry in
            let averages = healthKit.runs.map { $0.averageMileTime }
            let points = averagesToGraphCoordinates(averages: averages, width: geometry.size.width, height: geometry.size.height)
            
            Path { path in
                path.move(to: CGPoint(x: points.first?.x ?? 0.0, y: points.first?.y ?? 0.0))
                
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .foregroundColor(color)
            
            if healthKit.runs.count > 0 {
                ForEach(0..<points.count, id: \.self) { index in
                    let width = (geometry.size.width / CGFloat(points.count)) - 2
                    let run = healthKit.runs[index]
                    Text("")
                        .frame(maxWidth: width, maxHeight: geometry.size.height)
                        .background(.white)
                        .opacity(0.00001)
                        .position(x: points[index].x, y: geometry.size.height / 2)
                        .onTapGesture {
                            print(averages[index])
                            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                            impactHeavy.impactOccurred()
                            self.presentingTest = true
                            runViewModel.runClicked = healthKit.runs[index]
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
        @Published var runClicked: Run = Run(date: Date(), totalDistance: 0, totalTime: 0, averageMileTime: 0)
    }
    
    struct RunView: View {
        //        @EnvironmentObject var healthKit: MyHealthKit
        @EnvironmentObject var runViewModel: RunViewModel
        //        var run: Run = Run(date: Date(), totalDistance: 0, totalTime: 0, averageMileTime: 0)
        var body: some View {
            ZStack {
                Color.myGray.edgesIgnoringSafeArea(.all)
                VStack(alignment:.leading) {
                    Text("Run\n")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    let date = Calendar.current.dateComponents([.day, .month, .year], from: runViewModel.runClicked.date)
                    let year = String(date.year ?? 0).trimmingCharacters(in: [","])
                    Text("Date")
                        .foregroundColor(.white)
                    Text("\(date.month ?? 0)/\(date.day ?? 0)/\(year)\n")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Distance")
                        .foregroundColor(.white)
                    Text(String(format: "%.2f", runViewModel.runClicked.totalDistance) + "\n")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Time")
                        .foregroundColor(.white)
                    Text(String(format: "%.2f", runViewModel.runClicked.totalTime) + "\n")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Average")
                        .foregroundColor(.white)
                    Text(String(format: "%.2f", runViewModel.runClicked.averageMileTime))
                        .font(.title)
                        .foregroundColor(.white)
                    
                }
            }
        }
    }
    
    func averagesToGraphCoordinates(averages: [Double], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard averages.count != 0 else { return [CGPoint(x: 0, y: 0)] }
        
        // Create line graph
        // Handle y axis placement
        var max = averages.max()!
        max = max > 1 ? max : 1
        let min = averages.min()!
        let diff = max - min
        let adjusted = averages.map { ($0 - min) / diff }
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
