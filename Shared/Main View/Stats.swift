//
//  Stats.swift
//  Fitness
//
//  Created by Thomas Goss on 3/18/21.
//

import SwiftUI

struct StatsTitle: View {
    var title: String
    var body: some View {
        Text(title)
            .foregroundColor(.white)
            .font(.title)
            .bold()
    }
}

struct StatsRow<Content: View, OtherContent: View>: View {
    @EnvironmentObject var fitness: FitnessCalculations
    @EnvironmentObject var healthKit: MyHealthKit
    var shouldShowText: Bool = true
    let rings: OtherContent
    let text: Content
    
    init(@ViewBuilder text: @escaping () -> Content, @ViewBuilder rings: @escaping () -> OtherContent) {
        self.text = text()
        self.rings = rings()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            text
                .environmentObject(fitness)
                .environmentObject(healthKit)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            rings
                .environmentObject(healthKit)
                .environmentObject(fitness)
                .frame(minWidth: 0, maxWidth: .infinity)
            
        }
        .padding()
        .background(Color.myGray)
        .cornerRadius(20)
    }
}

struct StatsText: View {
    var color: Color
    var title: String
    var stat: String
    
    var body: some View {
        Text(title)
            .foregroundColor(.white)
        Text(stat)
            .foregroundColor(color)
            .font(.title2)
            .padding(.bottom, 2)
    }
}
