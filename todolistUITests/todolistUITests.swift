//
//  todolistUITests.swift
//  todolistUITests
//
//  Created by 梁庆卫 on 2026/2/13.
//

import XCTest

final class todolistUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAddTaskFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let input = app.textFields["taskInputField"]
        XCTAssertTrue(input.waitForExistence(timeout: 2))
        input.tap()
        input.typeText("买牛奶")

        let addButton = app.buttons["taskAddButton"]
        XCTAssertTrue(addButton.isEnabled)
        addButton.tap()

        XCTAssertTrue(app.staticTexts["买牛奶"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testFilterSegmentExists() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["全部"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["未完成"].exists)
        XCTAssertTrue(app.buttons["已完成"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
