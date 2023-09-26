//
//  TodayView.swift
//  Fitness
//
//  Created by Thomas on 2/27/23.
//

import SwiftUI
import Charts
import Combine

// MARK: TODAY VIEW
struct TodayView: View {
    @EnvironmentObject var vm: TodayViewModel
    @Environment(\.scenePhase) private var scenePhase
    var environment: AppEnvironmentConfig = .release
    let paddingAmount: CGFloat = 2 * 10
    @State var columnCount: Int = 2
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let today = vm.today
                let overallItem = TodayRingViewModel(titleText: "Overall Score", bodyText: String(Int(vm.averagePercentage * 100)) + "%", subBodyText: "overall", percentage: vm.averagePercentage, bodyTextColor: .white, gradient: [.yellow, .purple, .orange, .yellow, .orange, .purple])
                
                let sign = today.surplus > 0 ? "+" : ""
                let bodyText = "\(sign)\(Int(today.surplus))"
                let color: TodayRingColor = today.surplus > 0 ? .red : .yellow
                let netEnergyItem = TodayRingViewModel(titleText: "Net Energy", bodyText: bodyText, subBodyText: "cals", percentage: vm.deficitPercentage, color: .yellow, bodyTextColor: color, subBodyTextColor: color)
                
                let proteinItem = TodayRingViewModel(titleText: "Protein", bodyText: vm.proteinPercentage.percentageToWholeNumber() + "/30%", subBodyText: "cals", percentage: vm.proteinGoalPercentage, color: .purple, bodyTextColor: .purple, subBodyTextColor: .purple)
                
                let activeCalorieItem = TodayRingViewModel(titleText: "Active Calories", bodyText: String(Int(today.activeCalories)), subBodyText: "cals", percentage: vm.activeCaloriePercentage, color: .orange, bodyTextColor: .orange, subBodyTextColor: .orange)
                
                let weightChangeItem = TodayRingViewModel(titleText: "Weight Change", bodyText: today.expectedWeightChangedBasedOnDeficit.roundedString(), subBodyText: "pounds", percentage: vm.weightChangePercentage, color: .green, bodyTextColor: .green, subBodyTextColor: .green)
                
                let vms = [overallItem, proteinItem, activeCalorieItem, weightChangeItem, netEnergyItem]
                
                let columns: [GridItem] = {
                    var c: [GridItem] = []
                    for _ in 1...self.columnCount {
                        c.append(GridItem(.adaptive(minimum: 400)))
                    }
                    return c
                }()
                Text("Fitness")
                    .foregroundColor(.white)
                    .font(.title)
                    .padding([.leading])
                    .bold()
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(vms, id: \.self) { item in
                        TodayRingView(vm: item)
                            .mainBackground()
                    }
                    TodayBar()
                        .environmentObject(TodayBarViewModel(today: vm.today, maxValue: vm.maxValue, minValue: vm.minValue, yValues: vm.yValues))
                        .padding()
                        .mainBackground()
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            vm.reloadToday()
        }
        .onChange(of: scenePhase) { _ in
            vm.reloadToday()
        }
    }
}

struct TodayViewPreview: View {
    @State var vm = TodayViewModel(today: TestData.today, environment: .debug)

    var body: some View {
        TodayView()
            .environmentObject(vm)
            .background(Color.black)
    }
}
    
// MARK: PREVIEW
struct Previews_TodayView_Previews: PreviewProvider {
    @State var vm = TodayViewModel(today: TestData.today, environment: .debug)
    
    static var previews: some View {
        TodayViewPreview()
//                    .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))

    }
}
