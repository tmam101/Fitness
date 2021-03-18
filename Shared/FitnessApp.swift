//
//  FitnessApp.swift
//  Shared
//
//  Created by Thomas Goss on 1/20/21.
//

import SwiftUI

@main
struct FitnessApp: App {
    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}

struct AppView: View {
    @State var fitness = FitnessCalculations()
    @State var healthKit = MyHealthKit()
    
    var body: some View {
        ZStack {
            Color.myGray.edgesIgnoringSafeArea(.all)
            VStack {
//                VStack {
                FitnessView()
                    .environmentObject(fitness)
                    .environmentObject(healthKit)
                    .frame(height: 400)
//                ScrollView {
//                    Text("Hey")
//                        .frame(height: 400)
//                    Text("Hey")
//                        .frame(height: 400)
//                    Text("Hey")
//                        .frame(height: 400)
//                    Text("Hey")
//                        .frame(height: 400)
//
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding()
//                .background(Color.red)
            }
        }
    }
}

struct FitnessApp_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}

struct Deets: View {
    @EnvironmentObject var fitness: FitnessCalculations
    var body: some View {
        VStack {
            Text("Weight: \(Int(fitness.currentWeight))").foregroundColor(.white)
            Text("Goal Weight: \(Int(fitness.endingWeight))").foregroundColor(.white)
//            Button("Press") {
//                self.fitness.currentWeight = 220
//                self.fitness.getAllStats { _ in
//
//                }
//            }
        }
    }
}
