import XCTest

/// Kamera-Kacheln und Vollbild-Livebild. Select auf einer Kamera-Kachel ist
/// erlaubt: es öffnet nur das Livebild und schaltet nichts.
/// Zum Testen ohne echte Kamera: Testbild-Kamera der Homebridge-Test-Bridge
/// (siehe docs/homekit-testgeraete.md).
final class HomeDashCameraUITests: HomeDashUITestCase {

    private func requireCameraTile() throws -> XCUIElement {
        try requireDashboard()
        let tile = element("tile.camera")
        guard tile.waitForExistence(timeout: 5) else {
            throw XCTSkip("Keine Kamera im Home")
        }
        return tile
    }

    func testCameraTileLoadsSnapshot() throws {
        let tile = try requireCameraTile()
        XCTAssertFalse(tile.label.isEmpty, "Kamera-Kachel ohne Namen")
        // Mit Snapshot zeigt die Kachel die Aufnahmezeit (enthält immer „:“).
        let hasTime = NSPredicate(format: "value CONTAINS ':'")
        expectation(for: hasTime, evaluatedWith: tile)
        waitForExpectations(timeout: 30)
    }

    func testCameraFullscreenStreamsAndClosesWithMenu() throws {
        let tile = try requireCameraTile()
        let focused = moveFocus(.down, maxPresses: 6) { tile.hasFocus }
            || moveFocus(.up, maxPresses: 12) { tile.hasFocus }
        XCTAssertTrue(focused, "Kamera-Kachel nicht per Fernbedienung erreichbar")

        remote.press(.select) // öffnet nur das Livebild
        let fullscreen = element("camera.fullscreen")
        XCTAssertTrue(fullscreen.waitForExistence(timeout: 5), "Livebild öffnet sich nicht")

        let live = NSPredicate(format: "value == 'LIVE'")
        expectation(for: live, evaluatedWith: fullscreen)
        waitForExpectations(timeout: 30)

        remote.press(.menu)
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: fullscreen)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(element("dashboard").exists)
    }
}
