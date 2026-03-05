import XCTest

final class MACRAUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-gate"]
        app.launch()
    }

    // MARK: - Screenshot Tests

    func test01_DashboardScreenshot() throws {
        // Dashboard should be visible after gate bypass
        let dashboard = app.navigationBars["Today"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "01_Dashboard"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func test02_LogTabScreenshot() throws {
        // Tap Log tab
        app.tabBars.buttons["Log"].tap()
        sleep(1)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "02_LogMeal"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func test03_InsightsTabScreenshot() throws {
        // Tap Insights tab
        app.tabBars.buttons["Insights"].tap()
        sleep(1)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "03_Insights"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func test04_SocialTabScreenshot() throws {
        // Tap Social tab
        app.tabBars.buttons["Social"].tap()
        sleep(1)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "04_Social"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func test05_SettingsTabScreenshot() throws {
        // Tap Settings tab
        app.tabBars.buttons["Settings"].tap()
        sleep(1)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "05_Settings"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func test06_ManualEntryScreenshot() throws {
        // Navigate to Log tab and tap Manual Entry
        app.tabBars.buttons["Log"].tap()
        sleep(1)

        let manualButton = app.buttons["Manual Entry"]
        if manualButton.waitForExistence(timeout: 3) {
            manualButton.tap()
            sleep(1)

            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "06_ManualEntry"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
