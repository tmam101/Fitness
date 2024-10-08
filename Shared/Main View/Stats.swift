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
            .font(GlobalEnvironment.isWatch ? .caption : .title)
            .bold()
    }
}

struct StatsRow<Content: View, OtherContent: View>: View {
    @EnvironmentObject var healthData: HealthData
    var shouldShowText: Bool = true
    let rings: OtherContent
    let text: Content
    
    init(@ViewBuilder text: @escaping () -> Content, @ViewBuilder rings: @escaping () -> OtherContent) {
        self.text = text()
        self.rings = rings()
    }
    
    var body: some View {
#if os(iOS)
        HStack(spacing: 0) {
            text
                .environmentObject(healthData)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            rings
                .environmentObject(healthData)
                .frame(minWidth: 0, maxWidth: .infinity)
            
        }
        .padding()
        .mainBackground()
#endif
#if os(watchOS)
        VStack(spacing: 0) {
            text
                .environmentObject(healthData)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            rings
                .environmentObject(healthData)
                .frame(minWidth: 0, maxWidth: .infinity)
            
        }
        .padding()
        .mainBackground()
#endif
    }
}

struct StatsText: View {
    var color: Color
    var title: String
    var title2: String?
    var stat: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            if title2 != nil {
                Text(title2 ?? "")
                    .foregroundColor(color)
            }
        }
        Text(stat)
            .foregroundColor(color)
            .font(.title2)
            .padding(.bottom, 2)
    }
}
