import XCTest

final class MACRAUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-gate"]
        app.launch()

        // Wait for the main tab bar to be fully loaded
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after gate bypass")
    }

    private func tapTabByCoordinate(_ name: String) {
        let tab = app.tabBars.buttons[name]
        guard tab.waitForExistence(timeout: 5) else {
            XCTFail("Tab '\(name)' not found")
            return
        }
        // Use coordinate tap to avoid scrollToVisible issues
        let coord = tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coord.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }

    private func captureScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Screenshot Tests

    func test01_DashboardScreenshot() throws {
        let nav = app.navigationBars.firstMatch
        XCTAssertTrue(nav.waitForExistence(timeout: 5))
        captureScreenshot(named: "01_Dashboard")
    }

    func test02_LogTabScreenshot() throws {
        tapTabByCoordinate("Log")
        captureScreenshot(named: "02_LogMeal")
    }

    func test03_InsightsTabScreenshot() throws {
        tapTabByCoordinate("Insights")
        captureScreenshot(named: "03_Insights")
    }

    func test04_SocialTabScreenshot() throws {
        tapTabByCoordinate("Social")
        captureScreenshot(named: "04_Social")
    }

    func test05_SettingsTabScreenshot() throws {
        tapTabByCoordinate("Settings")
        captureScreenshot(named: "05_Settings")
    }

    func test06_ManualEntryScreenshot() throws {
        tapTabByCoordinate("Log")

        let manualButton = app.buttons["Manual Entry"]
        if manualButton.waitForExistence(timeout: 3) {
            let coord = manualButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coord.tap()
            Thread.sleep(forTimeInterval: 1.5)
        }
        captureScreenshot(named: "06_ManualEntry")
    }
}
