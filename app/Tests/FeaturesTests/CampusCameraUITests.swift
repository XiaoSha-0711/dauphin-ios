import XCTest

final class CampusCameraUITests: XCTestCase {
    @MainActor func testCameraSelectionTimestampAndEnlargement() {
        let app = openCameras()
        let time = app.staticTexts["campus-camera-time"]
        XCTAssertTrue(time.waitForExistence(timeout: 10))
        XCTAssertTrue(time.label.contains("2026-10-17 21:29:00"))
        app.buttons["campus-camera-picker"].tap()
        app.buttons["紅 27 公車站"].tap()
        let image = app.buttons["campus-camera-image"]
        XCTAssertTrue(image.waitForExistence(timeout: 10))
        XCTAssertTrue(image.label.contains("R27"))
        capture(app, name: "campus-camera-light")
        image.tap()
        XCTAssertTrue(app.buttons["還原大小"].waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(app.buttons["還原大小"].frame.height, 44)
        XCTAssertTrue(
            app.staticTexts["campus-camera-time"].firstMatch.label.contains("2026-10-17 21:29:00"))
        capture(app, name: "campus-camera-enlarged")
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons["campus-camera-refresh"].waitForExistence(timeout: 5))
    }

    @MainActor func testFailedRefreshKeepsTheImageAndItsOriginalTime() {
        let app = openCameras(arguments: ["-campus-camera-refresh-failure-test"])
        let time = app.staticTexts["campus-camera-time"]
        XCTAssertTrue(time.waitForExistence(timeout: 10))
        let original = time.label
        app.buttons["campus-camera-refresh"].tap()
        XCTAssertTrue(app.staticTexts["重新整理失敗，目前顯示上一張影像。"].waitForExistence(timeout: 5))
        XCTAssertEqual(time.label, original)
        XCTAssertTrue(app.buttons["campus-camera-image"].exists)
        capture(app, name: "campus-camera-refresh-failure")
    }

    @MainActor func testMissingOverlayShowsTheLabelledServerTime() {
        let app = openCameras(arguments: ["-campus-camera-server-time-test"])
        let time = app.staticTexts["campus-camera-time"]
        XCTAssertTrue(time.waitForExistence(timeout: 10))
        XCTAssertTrue(time.label.contains("2026-10-17 21:29:21"))
        XCTAssertTrue(app.staticTexts["伺服器檔案更新時間・臺北時間；圖上時間未能辨識。"].exists)
        capture(app, name: "campus-camera-server-time")
    }

    @MainActor func testEnglishLabels() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-campus-camera-test", "-isFirstTime", "NO", "-AppleLanguages", "(en)", "-AppleLocale",
            "en_US",
        ]
        app.launch()
        let other = app.buttons["Other"]
        XCTAssertTrue(other.waitForExistence(timeout: 5), app.debugDescription)
        other.tap()
        let entry = app.descendants(matching: .any).matching(identifier: "campus-camera-entry")
            .firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        XCTAssertTrue(entry.label.contains("Campus Cameras"))
        entry.tap()
        XCTAssertTrue(app.buttons["campus-camera-image"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Refresh Image"].exists)
        XCTAssertTrue(app.staticTexts["campus-camera-time"].label.contains("Image updated:"))
        capture(app, name: "campus-camera-english")
    }

    @MainActor func testDarkMode() {
        let app = openCameras(arguments: ["-userInterfaceStyle", "2"])
        XCTAssertTrue(app.buttons["campus-camera-image"].waitForExistence(timeout: 10))
        capture(app, name: "campus-camera-dark")
    }

    @MainActor private func openCameras(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments =
            [
                "-campus-camera-test", "-isFirstTime", "NO", "-AppleLanguages", "(zh-Hant)",
                "-AppleLocale", "zh_TW",
            ] + arguments
        app.launch()
        let other = app.buttons["其他"]
        XCTAssertTrue(other.waitForExistence(timeout: 5), app.debugDescription)
        other.tap()
        let shortcut = app.descendants(matching: .any).matching(identifier: "campus-camera-entry")
            .firstMatch
        XCTAssertTrue(shortcut.waitForExistence(timeout: 5))
        capture(app, name: "other-campus-camera-entry")
        shortcut.tap()
        XCTAssertTrue(app.buttons["campus-camera-picker"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor private func capture(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
