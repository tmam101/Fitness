//
//  ComplicationViews.swift
//  Watch WatchKit Extension
//
//  Created by Thomas Goss on 1/4/22.
//

import SwiftUI
import ClockKit

struct ComplicationViews: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ComplicationViewCircular: View {
    @EnvironmentObject var healthData: HealthData

  var body: some View {
      let percent: Double = Double(healthData.calorieManager.percentWeeklyDeficit) / 100
    ZStack {
      ProgressView(
        "\(percent)",
        value: (1.0 - percent),
        total: 1.0)
        .progressViewStyle(
            CircularProgressViewStyle(tint: .yellow))
    }
  }
}

struct ComplicationViewCornerCircular: View {
    @EnvironmentObject var healthData: HealthData
    @Environment(\.complicationRenderingMode) var renderingMode
    
    var body: some View {
        // 3
        ZStack {
            switch renderingMode {
            case .fullColor:
              Circle()
                .fill(Color.white)
            case .tinted:
              Circle()
                .fill(
                  RadialGradient(
                    gradient: Gradient(colors: [.clear, .white]),
                    center: .center,
                    startRadius: 10,
                    endRadius: 15))
            @unknown default:
              Circle()
                .fill(Color.white)
            }
            Text("\(healthData.calorieManager.percentWeeklyDeficit)")
                .foregroundColor(Color.black)
                .complicationForeground()
            Circle()
                .stroke(.yellow, lineWidth: 5)
                .complicationForeground()
        }
    }
}

struct ComplicationViewModular: View {
    @EnvironmentObject var healthData: HealthData
    var body: some View {
        NetEnergyBarChart(health: healthData, timeFrame: .init(name: "Week", days: 7))
    }
}


struct ComplicationViews_Previews: PreviewProvider {
    static var previews: some View {
        ComplicationViews()
    }
}
