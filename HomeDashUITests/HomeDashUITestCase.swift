import XCTest

/// Basis für alle HomeDash-UI-Tests.
///
/// Die Tests laufen gegen das echte Apple Home des Geräts. Deshalb gilt:
/// **niemals `.select` auf Geräte- oder Szenen-Tiles drücken** – das würde
/// echte Lampen schalten oder Szenen auslösen. Erlaubt sind Fokus-Bewegung,
/// Play/Pause (öffnet nur das Detail-Sheet) und Menu (schließt).
class HomeDashUITestCase: XCTestCase {
    enum RootScreen: String, CaseIterable {
        case dashboard = "dashboard"
        case permission = "root.permission"
        case noHomes = "root.noHomes"
    }

    let app = XCUIApplication()
    let remote = XCUIRemote.shared

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    /// Wartet, bis der Ladebildschirm durch einen der Endzustände ersetzt ist.
    @discardableResult
    func waitForRootScreen(timeout: TimeInterval = 20) throws -> RootScreen {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for screen in RootScreen.allCases where element(screen.rawValue).exists {
                return screen
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTFail("Kein bekannter Startbildschirm nach \(Int(timeout)) s")
        throw XCTSkip("Startbildschirm fehlt")
    }

    /// Überspringt den Test, wenn kein Home mit Zugriff vorhanden ist
    /// (z. B. Simulator ohne Apple Home).
    func requireDashboard() throws {
        let screen = try waitForRootScreen()
        guard screen == .dashboard else {
            throw XCTSkip("Kein Dashboard (\(screen.rawValue)) – Gerät ohne Apple Home?")
        }
    }

    var focusedElement: XCUIElement {
        app.descendants(matching: .any)
            .element(matching: NSPredicate(format: "hasFocus == true"))
    }

    var focusedIdentifier: String {
        let el = focusedElement
        return el.exists ? el.identifier : ""
    }

    /// Bewegt den Fokus in eine Richtung, bis `matches` zutrifft.
    @discardableResult
    func moveFocus(_ direction: XCUIRemote.Button, maxPresses: Int = 12,
                   until matches: () -> Bool) -> Bool {
        if matches() { return true }
        for _ in 0..<maxPresses {
            remote.press(direction)
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            if matches() { return true }
        }
        return false
    }

    /// Fokussiert ein beliebiges Geräte-Tile (nur Fokus, kein Auslösen).
    func focusAnyAccessoryTile() -> Bool {
        moveFocus(.down, maxPresses: 12) { focusedIdentifier == "tile.accessory" }
    }
}
