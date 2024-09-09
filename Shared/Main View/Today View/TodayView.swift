//
//  TodayView.swift
//  Fitness
//
//  Created by Thomas on 2/27/23.
//

// MARK: - Imports

import SwiftUI
import Charts
import Combine

// MARK: - TodayView

struct TodayView: View {
    @EnvironmentObject var health: HealthData
    @Environment(\.scenePhase) private var scenePhase
    let paddingAmount: CGFloat = 20 // Instead of `2 * 10`, use a single value for clarity
    @State var columnCount: Int = 2
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                displayFitnessHeader()
                displayGridItems()
            }
        }
        // TODO Make reload like HomeScreen
//        .onAppear {
//            vm.reloadToday()
//        }
//        .onChange(of: scenePhase) { _ in
//            vm.reloadToday()
//        }
    }
    
    // MARK: - Private Helper Functions
    
    private func displayFitnessHeader() -> some View {
        Text("Fitness")
            .foregroundColor(.white)
            .font(.title)
            .padding([.leading])
            .bold()
    }
    
    private func displayGridItems() -> some View {
        LazyVGrid(columns: createColumns(), spacing: 20) {
            ForEach(createRingViewModels(), id: \.self) { item in
                TodayRingView(vm: item)
                    .mainBackground()
            }
//            TodayBar()
//                .environmentObject(TodayBarViewModel(today: vm.today, maxValue: vm.maxValue, minValue: vm.minValue, yValues: vm.yValues))
//                .padding()
//                .mainBackground()
        }
        .padding(.horizontal)
    }
    
    private func createColumns() -> [GridItem] {
        Array(repeating: GridItem(.adaptive(minimum: 400)), count: columnCount)
    }
    
    private func createRingViewModels() -> [TodayRingViewModel] {
        // Construct and return an array of TodayRingViewModel objects
        guard let today = health.days[0] else { return [] }

        let overallItem = TodayRingViewModel(
            titleText: "Overall Score",
            bodyText: "\(Int(Double(today.averagePercentage * 100)))%",
            subBodyText: "overall",
            percentage: today.averagePercentage,
            bodyTextColor: .white,
            gradient: [.yellow, .purple, .orange, .yellow, .orange, .purple]
        )
        
        let sign = today.netEnergy > 0 ? "+" : ""
        let bodyText = "\(sign)\(Int(Double(today.netEnergy)))"
        let color: TodayRingColor = today.netEnergy > 0 ? .red : .yellow
        let netEnergyItem = TodayRingViewModel(
            titleText: "Net Energy",
            bodyText: bodyText,
            subBodyText: "cals",
            percentage: today.deficitPercentage,
            color: .yellow,
            bodyTextColor: color,
            subBodyTextColor: color
        )
        
        let proteinItem = TodayRingViewModel(
            titleText: "Protein",
            bodyText: Double(today.proteinPercentage).percentageToWholeNumber() + "/30%",
            subBodyText: "cals",
            percentage: today.proteinGoalPercentage,
            color: .purple,
            bodyTextColor: .purple,
            subBodyTextColor: .purple
        )
        
        let activeCalorieItem = TodayRingViewModel(
            titleText: "Active Calories",
            bodyText: "\(Int(Double(today.activeCalories)))",
            subBodyText: "cals",
            percentage: today.activeCaloriePercentage,
            color: .orange,
            bodyTextColor: .orange,
            subBodyTextColor: .orange
        )
        
        let weightChangeItem = TodayRingViewModel(
            titleText: "Weight Change",
            bodyText: Double(today.expectedWeightChangeBasedOnDeficit).roundedString(),
            subBodyText: "pounds",
            percentage: today.weightChangePercentage,
            color: .green,
            bodyTextColor: .green,
            subBodyTextColor: .green
        )
        
        return [overallItem, proteinItem, activeCalorieItem, weightChangeItem, netEnergyItem]
    }

}

enum RingType {
    case weightChange
}

struct TestRing: View {
    var ringType: RingType
    var health: HealthData // TODO Shouldn't need to pass the whole thing
    
    var body: some View {
        switch ringType {
        case .weightChange:
            if let today = health.days[0] {
                let vm = TodayRingViewModel(
                    titleText: "Weight Change",
                    bodyText: Double(today.expectedWeightChangeBasedOnDeficit).roundedString(),
                    subBodyText: "pounds",
                    percentage: today.weightChangePercentage,
                    color: .green,
                    bodyTextColor: .green,
                    subBodyTextColor: .green
                )
                TodayRingView(vm: vm)
            }
        }
    }
}

struct TodayViewPreview: View {
    @State var health: HealthData = HealthData(environment: .debug)
    var body: some View {
        TodayView()
            .environmentObject(health)
            .background(Color.black)
    }
}
    
// MARK: PREVIEW
struct Previews_TodayView_Previews: PreviewProvider {
    @State var health = HealthData(environment: .debug)

    static var previews: some View {
        TodayViewPreview()

    }
}
