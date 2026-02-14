//
//  todolistUITests.swift
//  todolistUITests
//
//  Created by 梁庆卫 on 2026/2/13.
//

import XCTest

final class todolistUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testLoginGateAppearsOnFirstLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET_AUTH"]
        app.launch()

        XCTAssertTrue(app.navigationBars["登录"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["loginPhoneField"].exists)
    }

    @MainActor
    func testPhoneLoginFlowAndTaskCreation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET_AUTH"]
        app.launch()

        performMockLogin(app: app)

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
    func testSessionPersistsAcrossRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET_AUTH"]
        app.launch()
        performMockLogin(app: app)

        app.terminate()

        let relaunched = XCUIApplication()
        relaunched.launch()

        XCTAssertTrue(relaunched.tabBars.buttons["任务"].waitForExistence(timeout: 2))
        XCTAssertFalse(relaunched.navigationBars["登录"].exists)
    }

    @MainActor
    func testLogoutReturnsToLogin() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET_AUTH"]
        app.launch()
        performMockLogin(app: app)

        app.tabBars.buttons["我"].tap()
        let logoutButton = app.buttons["logoutButton"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 2))
        logoutButton.tap()

        XCTAssertTrue(app.navigationBars["登录"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["UITEST_RESET_AUTH"]
            app.launch()
        }
    }

    private func performMockLogin(app: XCUIApplication) {
        let phoneField = app.textFields["loginPhoneField"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 2))
        phoneField.tap()
        phoneField.typeText("13800138000")

        let sendCodeButton = app.buttons["sendOtpButton"]
        XCTAssertTrue(sendCodeButton.isEnabled)
        sendCodeButton.tap()

        let codeField = app.textFields["otpCodeField"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 2))
        codeField.tap()
        codeField.typeText("123456")

        let loginButton = app.buttons["otpLoginButton"]
        XCTAssertTrue(loginButton.isEnabled)
        loginButton.tap()

        XCTAssertTrue(app.tabBars.buttons["任务"].waitForExistence(timeout: 2))
    }
}
