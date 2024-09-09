import Testing
@testable import Fitness
import Foundation

// TODO dont need
// Mock HealthData class
class MockHealthData: HealthData {
    override init(environment: AppEnvironmentConfig = .debug) {
        super.init(environment: environment)
    }

    func populateMockData(days: [Day]) {
        self.days = days.reduce(into: [Int: Day]()) { result, day in
            result[day.daysAgo] = day
        }
    }
}

@Suite 

final class NetEnergyBarChartViewModelTests {
    
    var viewModel: NetEnergyBarChartViewModel!
    var mockHealthData: MockHealthData!

    init() {
        mockHealthData = MockHealthData()
    }

    deinit {
        viewModel = nil
        mockHealthData = nil
    }

    @Test func setupDays() {
        let days = createMockDays()
        mockHealthData.populateMockData(days: days)
        
        viewModel = NetEnergyBarChartViewModel(days: mockHealthData.days, timeFrame: .week)
        // Test for a week
        #expect(viewModel.days.count == 8, "Days count should be 8 for a week timeframe")
        #expect(viewModel.days.first?.date == days.first?.date, "The first day should be the most recent day")
        #expect(viewModel.days.first?.daysAgo == 0)
        
        // Test for month
        viewModel = NetEnergyBarChartViewModel(days: mockHealthData.days, timeFrame: .month)
        #expect(viewModel.days.count == 31, "Days count should be 31 for a month timeframe")

        // Test for all time
        viewModel = NetEnergyBarChartViewModel(days: mockHealthData.days, timeFrame: .allTime)
        #expect(viewModel.days.count == 45, "Days count should be unlimited for all time timeframe")
        
        // Test sorting
        #expect(viewModel.days.last?.daysAgo == 44)
    }

    @Test func updateMinMaxValues() {
        let days = createMockDays()
        mockHealthData.populateMockData(days: days)
        
        // TODO refactor to not take health, but days
        viewModel = NetEnergyBarChartViewModel(days: mockHealthData.days, timeFrame: .week)
                
        let expectedMaxValue = mockHealthData.days.filteredBy(.week).mappedToProperty(property: .netEnergy).max() ?? 0
        let expectedMinValue = mockHealthData.days.filteredBy(.week).mappedToProperty(property: .netEnergy).min() ?? 0
        
        #expect(viewModel.maxValue == Double(expectedMaxValue).rounded(toNextSignificant: viewModel.lineInterval), "Max value should be the maximum net energy value")
        #expect(viewModel.minValue == Double(expectedMinValue).rounded(toNextSignificant: viewModel.lineInterval), "Min value should be the minimum net energy value")
        
        // TODO more examples
    }

    @Test func setupYValues() {
        let days = createMockDays()
        mockHealthData.populateMockData(days: days)
        
        viewModel = NetEnergyBarChartViewModel(days: mockHealthData.days, timeFrame: .week)
        
        let diff = viewModel.maxValue - viewModel.minValue
        let number = Int(diff / viewModel.lineInterval)
        let expectedYValues = (0...number).map { viewModel.minValue + (viewModel.lineInterval * Double($0)) }
        
        #expect(viewModel.yValues == expectedYValues, "Y values should be correctly calculated based on min and max values")
    }

    @Test func gradient() {
        let day = Day(activeCalories: 500, restingCalories: 1500, consumedCalories: 2000, expectedWeight: 70, weight: 70)
        viewModel = NetEnergyBarChartViewModel(days: mockHealthData.days, timeFrame: .week)
        
        let gradient = viewModel.gradient(for: day)
        
        #expect(gradient != nil, "Gradient should not be nil")
    }
    
    private func createMockDays() -> [Day] {
        var days: [Day] = []
        for i in 0..<45 {
            let day = Day(daysAgo: i, activeCalories: Decimal(Double.random(in: 100...500)), restingCalories: Decimal(Double.random(in: 1500...2000)), consumedCalories: Decimal(Double.random(in: 1800...2500)), expectedWeight: 70, weight: 70)
            days.append(day)
        }
        return days
    }
}

