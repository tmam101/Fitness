//
//  WeightView.swift
//  Fitness
//
//  Created by Thomas on 9/21/24.
//
import SwiftUI

struct WeightView: View {
    @ObservedObject var weightManager: WeightManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Weight Tracker")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)

            HStack {
                VStack(alignment: .leading) {
                    Text("Starting Weight:")
                        .font(.headline)
                    Text("\(weightManager.startingWeight) lbs")
                        .font(.title2)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Current Weight:")
                        .font(.headline)
                    Text("\(weightManager.currentWeight) lbs")
                        .font(.title2)
                }
            }
            
            HStack {
                Text("Target Weight:")
                    .font(.headline)
                Spacer()
                Text("\(weightManager.endingWeight)")
                    .font(.title2)
            }
//            let progress: Float = Float(Int(weightManager.getProgressToWeight()))
            ProgressView(value: 0.5)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.top, 20)
            
            Text("Weight Progress: \(weightManager.weightLost) lbs lost")
                .font(.headline)
        }
        .padding()
        .navigationTitle("Weight")
    }
}
