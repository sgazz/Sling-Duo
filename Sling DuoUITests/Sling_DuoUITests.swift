import XCTest

final class Sling_DuoUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testPauseResumeAndBackgroundRequireContinue() {
        let app = XCUIApplication()
        app.launch()
        let pause = app.buttons["pauseGame"]
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        pause.tap()
        let resume = app.buttons["continueGame"]
        XCTAssertTrue(resume.waitForExistence(timeout: 3))
        resume.tap()
        XCTAssertTrue(app.staticTexts["resumeCountdown"].waitForExistence(timeout: 2))
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: app.staticTexts["resumeCountdown"])
        waitForExpectations(timeout: 5)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSteeringChoicePersistsAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["pauseGame"].tap()
        let choice = app.buttons["steeringMode"]
        XCTAssertTrue(choice.waitForExistence(timeout: 3))
        let original = choice.label
        choice.tap()
        let changed = original == "Controls: Tilt" ? "Controls: Slide" : "Controls: Tilt"
        XCTAssertEqual(choice.label, changed)
        app.terminate()
        app.launch()
        app.buttons["pauseGame"].tap()
        XCTAssertTrue(choice.waitForExistence(timeout: 3))
        XCTAssertEqual(choice.label, changed)
        choice.tap()
        XCTAssertEqual(choice.label, original)
    }

    @MainActor
    func testDeviceRotationKeepsGameInPortrait() {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        XCTAssertTrue(app.buttons["pauseGame"].waitForExistence(timeout: 10))
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight, .portraitUpsideDown] {
            XCUIDevice.shared.orientation = orientation
            let portrait = NSPredicate { _, _ in app.frame.height > app.frame.width }
            expectation(for: portrait, evaluatedWith: app)
            waitForExpectations(timeout: 3)
            XCTAssertTrue(app.buttons["pauseGame"].exists)
        }
    }

    @MainActor
    func testTurboTogglePersistsAndCanBeDisabled() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["pauseGame"].waitForExistence(timeout: 10))
        app.buttons["pauseGame"].tap()
        let turbo = app.buttons["turboToggle"]
        XCTAssertTrue(turbo.waitForExistence(timeout: 3))
        let initial = turbo.label
        turbo.tap()
        let changed = initial == "Turbo experiment: Off" ? "Turbo experiment: On" : "Turbo experiment: Off"
        XCTAssertEqual(turbo.label, changed)
        app.terminate()
        app.launch()
        app.buttons["pauseGame"].tap()
        XCTAssertTrue(turbo.waitForExistence(timeout: 3))
        XCTAssertEqual(turbo.label, changed)
        turbo.tap()
        XCTAssertEqual(turbo.label, initial)
    }

    @MainActor
    func testEscapeOffersEndlessContinuationAndFreshRestart() {
        let app = XCUIApplication()
        app.launchEnvironment["SLINGDUO_ESCAPE_UI_TEST"] = "1"
        app.launch()
        let keep = app.buttons["keepClimbing"]
        XCTAssertTrue(keep.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["YOU ESCAPED!"].exists)
        let victory = XCTAttachment(screenshot: app.screenshot())
        victory.name = "Escape victory"
        victory.lifetime = .keepAlways
        add(victory)
        keep.tap()
        XCTAssertTrue(app.staticTexts["resumeCountdown"].waitForExistence(timeout: 2))
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: app.staticTexts["resumeCountdown"])
        waitForExpectations(timeout: 5)
        XCTAssertFalse(keep.exists)
        app.buttons["pauseGame"].tap()
        XCTAssertTrue(app.buttons["continueGame"].waitForExistence(timeout: 3))
        app.terminate()
        app.launch()
        let again = app.buttons["playAgain"]
        XCTAssertTrue(again.waitForExistence(timeout: 10))
        again.tap()
        XCTAssertTrue(app.staticTexts["resumeCountdown"].waitForExistence(timeout: 2))
        expectation(for: gone, evaluatedWith: app.staticTexts["resumeCountdown"])
        waitForExpectations(timeout: 5)
        XCTAssertFalse(again.exists)
        XCTAssertTrue(app.buttons["pauseGame"].exists)
    }

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
