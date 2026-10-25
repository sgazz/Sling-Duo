import XCTest

final class Sling_DuoUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testSoundPreferenceSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launch()
        let toggle = app.buttons["soundToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let initialLabel = toggle.label
        let changedLabel = initialLabel == "Mute sound" ? "Enable sound" : "Mute sound"
        toggle.tap()
        let changed = NSPredicate(format: "label == %@", changedLabel)
        expectation(for: changed, evaluatedWith: toggle)
        waitForExpectations(timeout: 5)
        app.terminate()
        app.launch()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.label, changedLabel)
        toggle.tap()
        let restored = NSPredicate(format: "label == %@", initialLabel)
        expectation(for: restored, evaluatedWith: toggle)
        waitForExpectations(timeout: 5)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Sling Duo sound control"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
