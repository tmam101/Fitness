import XCTest
@testable import Fitness

// Mock HealthData class
class MockHealthData: HealthData {
    override init(environment: AppEnvironmentConfig = .debug(nil)) {
        super.init(environment: environment)
    }

    func populateMockData(days: [Day]) {
        self.days = days.reduce(into: [Int: Day]()) { result, day in
            result[day.daysAgo] = day
        }
    }
}

class NetEnergyBarChartViewModelTests: XCTestCase {
    
    var viewModel: NetEnergyBarChartViewModel!
    var mockHealthData: MockHealthData!

    override func setUp() {
        super.setUp()
        mockHealthData = MockHealthData()
    }

    override func tearDown() {
        viewModel = nil
        mockHealthData = nil
        super.tearDown()
    }

    func testSetupDays() {
        let days = createMockDays()
        mockHealthData.populateMockData(days: days)
        
        viewModel = NetEnergyBarChartViewModel(health: mockHealthData, timeFrame: .week)
        // Test for a week
        XCTAssertEqual(viewModel.days.count, 8, "Days count should be 8 for a week timeframe")
        XCTAssertEqual(viewModel.days.first?.date, days.first?.date, "The first day should be the most recent day")
        XCTAssertEqual(viewModel.days.first?.daysAgo, 0)
        
        // Test for month
        viewModel = NetEnergyBarChartViewModel(health: mockHealthData, timeFrame: .month)
        XCTAssertEqual(viewModel.days.count, 31, "Days count should be 31 for a month timeframe")

        // Test for all time
        viewModel = NetEnergyBarChartViewModel(health: mockHealthData, timeFrame: .allTime)
        XCTAssertEqual(viewModel.days.count, 45, "Days count should be unlimited for all time timeframe")
        
        // Test sorting
        XCTAssertEqual(viewModel.days.last?.daysAgo, 44)
    }

    func testUpdateMinMaxValues() {
        let days = createMockDays()
        mockHealthData.populateMockData(days: days)
        
        // TODO refactor to not take health, but days
        viewModel = NetEnergyBarChartViewModel(health: mockHealthData, timeFrame: .week)
                
        let expectedMaxValue = mockHealthData.days.filteredBy(.week).mappedToProperty(property: .netEnergy).max() ?? 0
        let expectedMinValue = mockHealthData.days.filteredBy(.week).mappedToProperty(property: .netEnergy).min() ?? 0
        
        XCTAssertEqual(viewModel.maxValue, expectedMaxValue.rounded(toNextSignificant: viewModel.lineInterval), "Max value should be the maximum net energy value")
        XCTAssertEqual(viewModel.minValue, expectedMinValue.rounded(toNextSignificant: viewModel.lineInterval), "Min value should be the minimum net energy value")
        
        // TODO more examples
    }

    func testSetupYValues() {
        let days = createMockDays()
        mockHealthData.populateMockData(days: days)
        
        viewModel = NetEnergyBarChartViewModel(health: mockHealthData, timeFrame: .week)
        
        let diff = viewModel.maxValue - viewModel.minValue
        let number = Int(diff / viewModel.lineInterval)
        let expectedYValues = (0...number).map { viewModel.minValue + (viewModel.lineInterval * Double($0)) }
        
        XCTAssertEqual(viewModel.yValues, expectedYValues, "Y values should be correctly calculated based on min and max values")
    }

    func testGradient() {
        let day = Day(activeCalories: 500, restingCalories: 1500, consumedCalories: 2000, expectedWeight: 70, weight: 70)
        viewModel = NetEnergyBarChartViewModel(health: mockHealthData, timeFrame: .week)
        
        let gradient = viewModel.gradient(for: day)
        
        XCTAssertNotNil(gradient, "Gradient should not be nil")
    }
    
    private func createMockDays() -> [Day] {
        var days: [Day] = []
        for i in 0..<45 {
            let day = Day(daysAgo: i, activeCalories: Double.random(in: 100...500), restingCalories: Double.random(in: 1500...2000), consumedCalories: Double.random(in: 1800...2500), expectedWeight: 70, weight: 70)
            days.append(day)
        }
        return days
    }
}

