//
//  UITestPlaygroundUITests.swift
//  UITestPlaygroundUITests
//
//  Created by Carsten Knoblich on 10.03.21.
//

import XCTest

class UITestPlaygroundUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        let cell1 = app.cells["2-4"]
        XCTAssertTrue(cell1.waitForExistence(timeout: 10))
        cell1.tap()


        let cell2 = app.cells["0-0"]
        XCTAssertTrue(cell2.waitForExistence(timeout: 10))
        cell2.tap()
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
