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
//        let app = XCUIApplication()
//        let x = Filepath.Days.firstDayNotAdjustingWhenMissing
//        app.launchArguments = ["UITEST"]
//        app.launch()
//        self.app = app
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    func launchWithTestCase(path: TestCase) {
        let app = XCUIApplication()
        app.launchArguments = [path.rawValue]
        app.launch()
        self.app = app
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTimeFramePicker() throws {
        launchWithTestCase(path: .firstDayNotAdjustingWhenMissing)
        lookForText("Net Energy This Week")
//        XCTAssertFalse(barExists(daysAgo: 10))
        app.buttons["Month"].tap()
//        XCTAssertTrue(barExists(daysAgo: 10))
        lookForText("Net Energy This Month")
        XCTAssertEqual(app.otherElements["bar 0 days ago"].value as! String, "-2,250")
    }
    
    func testTwoDays() throws {
        launchWithTestCase(path: .twoDaysIssue)
//        lookForText("Net Energy This butt")
        //Add in a count, so that the loop can escape if it's scrolled too many times
        for i in [0,1,2] {
            app.swipeUp(velocity: .fast)
        }
        app.otherElements["expected weight point 1 days ago"].waitForExistence(timeout: 5)
    }
    
    func barExists(daysAgo: Int) -> Bool {
        app.otherElements["bar \(daysAgo) days ago"].waitForExistence(timeout: 5)
    }
    
    func testSomething() {
        launchWithTestCase(path: .missingDataIssue)
        lookForText("Net Energy This butt")
    }
    
    func lookForText(_ text: String) {
        XCTAssert(app.staticTexts[text].waitForExistence(timeout: 5))
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
