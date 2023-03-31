//
//  TodayRingView.swift
//  Fitness
//
//  Created by Thomas on 3/31/23.
//

import Foundation
import SwiftUI

struct TodayRingView: View {
    var vm: TodayRingViewModel
    @State var animate: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if vm.includeTitle {
                Text(vm.titleText)
                    .bold()
                    .foregroundColor(.white)
            }
            ZStack {
                VStack {
                    Text(vm.bodyText)
                        .font(.system(size: vm.fontSize))
                        .foregroundColor(vm.bodyTextColor.color)
                    if vm.includeSubBody {
                        Text(vm.subBodyText)
                            .foregroundColor(vm.subBodyTextColor.color)
                    }
                }
                if let g = vm.gradient {
                    let gradient = LinearGradient(
                        gradient: .init(colors: g.map(\.color)),
                        startPoint: animate ? .topLeading : .topTrailing,
                        endPoint: animate ? .bottomTrailing : .bottomLeading
                    )
                    Circle()
                        .stroke(style: .init(lineWidth: 1))
                        .foregroundColor(.gray)
                    Circle()
                        .trim(from: 0, to: vm.percentage)
                        .stroke(style: StrokeStyle(lineWidth: vm.lineWidth, lineCap: .round, lineJoin: .round))
                        .fill(gradient)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.easeOut(duration: 1), value: vm.percentage)
                    
                } else {
                    Circle()
                        .stroke(style: .init(lineWidth: 1))
                        .foregroundColor(.gray)
                    GenericCircle(color: vm.color.color, starting: 0, ending: vm.percentage, opacity: 1)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
        .modifier(OptionalPadding(shouldPad: vm.shouldPad))
    }
}

struct OptionalPadding: ViewModifier {
    var shouldPad: Bool
    func body(content: Content) -> some View {
        if shouldPad {
            content
                .padding()
        } else {
            content
        }
    }
}

enum TodayRingColor {
    case red
    case green
    case purple
    case orange
    case white
    case yellow
    
    var color: Color {
        switch self {
        case .red:
            return .red
        case .green:
               return .green
        case .purple:
            return .purple
        case .orange:
            return .orange
        case .white:
            return .white
        case .yellow:
            return .yellow

        }
    }
}
