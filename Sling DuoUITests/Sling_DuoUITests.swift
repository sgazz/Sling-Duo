import XCTest

final class Sling_DuoUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testPauseResumeAndBackgroundRequireContinue() {
        let app = XCUIApplication()
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
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
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
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
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
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
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
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
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
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
    func testHUDPauseAndReusableHelp() {
        let app = XCUIApplication()
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
        app.launch()
        XCTAssertTrue(app.staticTexts["heightValue"].waitForExistence(timeout: 10))
        capture(app, name: "UI - gameplay HUD")
        app.buttons["pauseGame"].tap()
        XCTAssertTrue(app.buttons["continueGame"].waitForExistence(timeout: 3))
        capture(app, name: "UI - pause")
        app.buttons["howToPlay"].tap()
        let close = app.buttons["finishTutorial"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        if !close.isHittable { app.swipeUp() }
        capture(app, name: "UI - how to play")
        close.tap()
        XCTAssertTrue(app.buttons["continueGame"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testFirstLaunchLetsPlayerChooseSlideAndStart() {
        let app = XCUIApplication()
        app.launchEnvironment["SLINGDUO_SHOW_ONBOARDING"] = "1"
        app.launch()
        let start = app.buttons["finishTutorial"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        let slide = app.buttons["tutorialSlide"]
        if !slide.isHittable { app.swipeUp() }
        slide.tap()
        if !start.isHittable { app.swipeUp() }
        start.tap()
        XCTAssertTrue(app.buttons["pauseGame"].waitForExistence(timeout: 3))
        XCTAssertFalse(start.exists)
        app.buttons["pauseGame"].tap()
        XCTAssertEqual(app.buttons["steeringMode"].label, "Controls: Slide")
    }

    @MainActor
    func testRescueClockAndDefeatResult() {
        let app = XCUIApplication()
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["SLINGDUO_UI_SCREEN"] = "rescue"
        app.launch()
        XCTAssertTrue(app.staticTexts["rescueTime"].waitForExistence(timeout: 10))
        capture(app, name: "UI - release countdown")
        app.terminate()
        app.launchEnvironment["SLINGDUO_UI_SCREEN"] = "defeat"
        app.launch()
        let retry = app.buttons["tryAgain"]
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
        capture(app, name: "UI - defeat")
        retry.tap()
        XCTAssertTrue(app.staticTexts["resumeCountdown"].waitForExistence(timeout: 2))
        XCTAssertFalse(retry.exists)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testHUDDoesNotBlockSlingGesture() {
        let app = XCUIApplication()
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["pauseGame"].waitForExistence(timeout: 10))
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.75))
        start.press(forDuration: 0.1, thenDragTo: end)
        // A successful catch may already have cleared the rescue clock.
        let launched = NSPredicate { _, _ in
            app.staticTexts["rescueTime"].exists || app.staticTexts["heightValue"].label != "0"
        }
        expectation(for: launched, evaluatedWith: app)
        waitForExpectations(timeout: 3)
    }

    @MainActor
    func testDeadlineAlwaysPresentsGameOverWhileAimingAndFlying() {
        let app = XCUIApplication()
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
        for preview in ["expiryAiming", "expiryFlying"] {
            for turbo in ["NO", "YES"] {
                app.launchArguments = ["-SlingDuo.turboEnabled", turbo]
                app.launchEnvironment["SLINGDUO_UI_SCREEN"] = preview
                app.launch()
                XCTAssertTrue(app.buttons["tryAgain"].waitForExistence(timeout: 10), "\(preview), Turbo \(turbo)")
                XCTAssertFalse(app.staticTexts["rescueTime"].exists)
                app.terminate()
            }
        }
    }

    @MainActor
    func testHUDCanBeHiddenAndRestoredFromPause() {
        let app = XCUIApplication()
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["SLINGDUO_HUD_COMPACT_TEST"] = "1"
        app.launch()
        XCTAssertTrue(app.staticTexts["heightValue"].waitForExistence(timeout: 10))
        capture(app, name: "UI - compact HUD")
        app.buttons["pauseGame"].tap()
        let selector = app.buttons["hudMode"]
        if !selector.isHittable { app.swipeUp() }
        XCTAssertTrue(selector.waitForExistence(timeout: 3))
        XCTAssertEqual(selector.label, "HUD: Compact")
        selector.tap()
        XCTAssertEqual(selector.label, "HUD: Hidden")
        app.buttons["continueGame"].tap()
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: app.staticTexts["resumeCountdown"])
        waitForExpectations(timeout: 5)
        XCTAssertFalse(app.staticTexts["heightValue"].exists)
        XCTAssertTrue(app.buttons["pauseGame"].exists)
        capture(app, name: "UI - hidden HUD")
        app.buttons["pauseGame"].tap()
        if !selector.isHittable { app.swipeUp() }
        selector.tap()
        XCTAssertEqual(selector.label, "HUD: Full")
        selector.tap()
        XCTAssertEqual(selector.label, "HUD: Compact")
    }

    @MainActor
    func testSoundPreferenceSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchEnvironment["SLINGDUO_SKIP_ONBOARDING"] = "1"
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
