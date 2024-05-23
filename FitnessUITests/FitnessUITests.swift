//
//  FitnessUITests.swift
//  FitnessUITests
//
//  Created by Thomas on 11/10/23.
//

import XCTest

final class FitnessUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST"]
        app.launch()
        self.app = app
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTimeFramePicker() throws {
        lookForText("Net Energy This Week")
        app.buttons["Month"].tap()
        lookForText("Net Energy This Month")
        XCTAssertEqual(app.otherElements["bar 0 days ago"].value as? Int, -115)
    }
    
    func lookForText(_ text: String) {
        XCTAssert(app.staticTexts[text].waitForExistence(timeout: 100))
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
