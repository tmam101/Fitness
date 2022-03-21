//
//  GenericCircles.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 3/18/21.
//

import Foundation
import SwiftUI

struct GenericCircle: View {
    var color: Color
    var starting: CGFloat
    var ending: CGFloat
    var opacity: Double
    var lineWidth: CGFloat = 10.0
    
    var body: some View {
        Circle()
            .trim(from: starting, to: ending)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .foregroundColor(color.opacity(opacity))
            .rotationEffect(Angle(degrees: 270.0))
            .animation(.easeOut(duration: 1), value: ending)
    }
}

struct BackgroundCircle: View {
    var color: Color
    var lineWidth: CGFloat = 10.0
    
    var body: some View {
        Circle()
            .stroke(lineWidth: lineWidth)
            .foregroundColor(color.opacity(0.1))
    }
}
