//
//  FitnessUITests.swift
//  FitnessUITests
//
//  Created by Thomas on 11/10/23.
//

import XCTest

final class FitnessUITests: XCTestCase {
    var app: XCUIApplication!
    
    enum TestCase: String {
        case missingDataIssue
        case realisticWeightsIssue
        case firstDayNotAdjustingWhenMissing
        case twoDaysIssue
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    func launchWithTestCase(path: TestCase) {
        let app = XCUIApplication()
        app.launchArguments = [path.rawValue]
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        self.app = app
        continueAfterFailure = false
        approveHealthkitAccessIfNecessary()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func approveHealthkitAccessIfNecessary() {
        let healthKitAccessButton = app.staticTexts["Turn On All"]
        let allowButton = app.buttons["Allow"]
        let notNowButton = app.buttons["Not Now"]
        
        if healthKitAccessButton.waitForExistence(timeout: 5) {
            healthKitAccessButton.tap()
            allowButton.tap()
            if notNowButton.waitForExistence(timeout: 5) {
                notNowButton.tap()
            }
        }
    }

    func testTimeFramePicker() throws {
        launchWithTestCase(path: .firstDayNotAdjustingWhenMissing)
        lookForText("Net Energy This Week")
        
        lookForText("+307")
        lookForText("-113")
        lookForText("+0.61")
        lookForText("+0.67")
        
        app.buttons["Month"].tap()
        
        lookForText("Net Energy This Month")
        
        lookForText("+130")
        lookForText("+17")
        lookForText("+0.74")
        lookForText("+1.80")
        
        XCTAssertEqual(app.otherElements["bar 0 days ago"].value as! String, "-2,250")
    }
    
    func barValue(daysAgo: Int) -> String? {
        guard let value = app.otherElements["bar \(daysAgo) days ago"].value as? String else {
            return nil
        }
        return value
    }
    
    func testBarExists(daysAgo: Int) -> Bool {
        app.otherElements["bar \(daysAgo) days ago"].waitForExistence(timeout: 5)
    }
    
    func lookForText(_ text: String) {
        XCTAssert(app.staticTexts[text].waitForExistence(timeout: 10))
    }

//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
    
//    func testGraphs() {
//        launchWithTestCase(path: .firstDayNotAdjustingWhenMissing)
//        
//        var monthAgoGraphPoint = app.otherElements["May 3, 2024 at 12 AM to May 5, 2024 at 12 AM"]
//        XCTAssert(monthAgoGraphPoint.waitForNonExistence(timeout: 5))
//        
//        app.buttons["Month"].tap()
        
//         TODO I suspect this is failing on CI due to time zone changes.
//        monthAgoGraphPoint = app.otherElements["May 3, 2024 at 12 AM to May 5, 2024 at 12 AM"]
//        XCTAssert(monthAgoGraphPoint.waitForExistence(timeout: 5))
//        XCTAssertEqual(monthAgoGraphPoint.firstMatch.value as? String, "700 to 700, 2 values")
        
//        XCTAssertEqual(app.otherElements["bar 0 days ago"].value as! String, "-2,250")
        
        // TODO check line graph. This query returns part of both the chart and the line graph so we aren't specific enough
//        let x = app.otherElements["May 3, 2024 at 12 AM to May 5, 2024 at 12 AM"]
//    }
}
