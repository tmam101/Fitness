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
    @EnvironmentObject var vm: TodayViewModel
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
        .onAppear {
            vm.reloadToday()
        }
        .onChange(of: scenePhase) { _ in
            vm.reloadToday()
        }
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
            TodayBar()
                .environmentObject(TodayBarViewModel(today: vm.today, maxValue: vm.maxValue, minValue: vm.minValue, yValues: vm.yValues))
                .padding()
                .mainBackground()
        }
        .padding(.horizontal)
    }
    
    private func createColumns() -> [GridItem] {
        Array(repeating: GridItem(.adaptive(minimum: 400)), count: columnCount)
    }
    
    private func createRingViewModels() -> [TodayRingViewModel] {
        // Construct and return an array of TodayRingViewModel objects
        let today = vm.today

        let overallItem = TodayRingViewModel(
            titleText: "Overall Score",
            bodyText: "\(Int(vm.averagePercentage * 100))%",
            subBodyText: "overall",
            percentage: vm.averagePercentage,
            bodyTextColor: .white,
            gradient: [.yellow, .purple, .orange, .yellow, .orange, .purple]
        )
        
        let sign = today.surplus > 0 ? "+" : ""
        let bodyText = "\(sign)\(Int(today.surplus))"
        let color: TodayRingColor = today.surplus > 0 ? .red : .yellow
        let netEnergyItem = TodayRingViewModel(
            titleText: "Net Energy",
            bodyText: bodyText,
            subBodyText: "cals",
            percentage: vm.deficitPercentage,
            color: .yellow,
            bodyTextColor: color,
            subBodyTextColor: color
        )
        
        let proteinItem = TodayRingViewModel(
            titleText: "Protein",
            bodyText: vm.proteinPercentage.percentageToWholeNumber() + "/30%",
            subBodyText: "cals",
            percentage: vm.proteinGoalPercentage,
            color: .purple,
            bodyTextColor: .purple,
            subBodyTextColor: .purple
        )
        
        let activeCalorieItem = TodayRingViewModel(
            titleText: "Active Calories",
            bodyText: "\(Int(today.activeCalories))",
            subBodyText: "cals",
            percentage: vm.activeCaloriePercentage,
            color: .orange,
            bodyTextColor: .orange,
            subBodyTextColor: .orange
        )
        
        let weightChangeItem = TodayRingViewModel(
            titleText: "Weight Change",
            bodyText: today.expectedWeightChangedBasedOnDeficit.roundedString(),
            subBodyText: "pounds",
            percentage: vm.weightChangePercentage,
            color: .green,
            bodyTextColor: .green,
            subBodyTextColor: .green
        )
        
        return [overallItem, proteinItem, activeCalorieItem, weightChangeItem, netEnergyItem]
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
