import XCTest

/// Hauptabläufe: Start, Dashboard, Sensor-Übersicht, Suche, Detail-Sheet.
/// Alle Tests sind lesend – siehe Hinweis in `HomeDashUITestCase`.
final class HomeDashUITests: HomeDashUITestCase {

    func testLaunchShowsKnownRootScreen() throws {
        let screen = try waitForRootScreen()
        XCTAssertFalse(element("root.loading").exists,
                       "Ladebildschirm steht noch, obwohl \(screen.rawValue) sichtbar ist")
    }

    func testDashboardShowsTitleAndHomeName() throws {
        try requireDashboard()
        XCTAssertTrue(element("dashboard.title").exists)
        let homeName = element("dashboard.homeName")
        XCTAssertTrue(homeName.waitForExistence(timeout: 5))
        XCTAssertFalse(homeName.label.isEmpty, "Home-Name ist leer")
    }

    func testDashboardHasFocusableAccessoryTiles() throws {
        try requireDashboard()
        let tiles = app.descendants(matching: .any).matching(identifier: "tile.accessory")
        guard tiles.count > 0 else { throw XCTSkip("Home ohne Geräte") }
        XCTAssertTrue(focusAnyAccessoryTile(), "Kein Geräte-Tile per Fernbedienung erreichbar")
        XCTAssertFalse(focusedElement.label.isEmpty, "Fokussiertes Tile ohne Namen")
    }

    func testFocusMovesAlongTileRow() throws {
        try requireDashboard()
        guard focusAnyAccessoryTile() else { throw XCTSkip("Kein Geräte-Tile") }
        let before = focusedElement.frame
        remote.press(.right)
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        if focusedElement.frame == before {
            remote.press(.left)
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        guard focusedElement.frame != before else {
            throw XCTSkip("Reihe hat nur ein Tile")
        }
        XCTAssertEqual(focusedIdentifier, "tile.accessory",
                       "Fokus ist aus der Tile-Reihe gesprungen")
    }

    func testSensorOverviewChipsShowValues() throws {
        try requireDashboard()
        let overview = element("sensors.overview")
        guard overview.waitForExistence(timeout: 5) else {
            throw XCTSkip("Keine Sensoren im Home")
        }
        let chips = overview.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'sensor.'"))
        XCTAssertGreaterThan(chips.count, 0, "Übersicht ohne Chips")
        for chip in chips.allElementsBoundByIndex {
            XCTAssertFalse(chip.label.isEmpty, "\(chip.identifier) ohne Titel")
            XCTAssertFalse((chip.value as? String ?? "").isEmpty, "\(chip.identifier) ohne Wert")
            XCTAssertFalse(chip.hasFocus, "Sensor-Chips sollen nicht fokussierbar sein")
        }
    }

    func testSearchOpensAndClosesWithMenu() throws {
        try requireDashboard()
        let button = element("search.button")
        XCTAssertTrue(button.exists)
        XCTAssertTrue(moveFocus(.up, maxPresses: 15) { button.hasFocus },
                      "Lupe nicht per Fernbedienung erreichbar")

        remote.press(.select) // Lupe öffnet nur die Suche
        let search = element("search.view")
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Suche öffnet sich nicht")
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5),
                      "Suchfeld fehlt")

        // Menu schließt erst die Tastatur, dann die Suche.
        for _ in 0..<3 where search.exists {
            remote.press(.menu)
            RunLoop.current.run(until: Date().addingTimeInterval(1))
        }
        XCTAssertFalse(search.exists, "Suche lässt sich nicht mit Menu schließen")
        XCTAssertTrue(element("dashboard").exists)
    }

    func testAccessoryDetailOpensWithPlayPauseAndCloses() throws {
        try requireDashboard()
        guard focusAnyAccessoryTile() else { throw XCTSkip("Kein Geräte-Tile") }
        let name = focusedElement.label

        remote.press(.playPause) // öffnet nur das Detail-Sheet
        let sheet = element("detail.sheet")
        XCTAssertTrue(sheet.waitForExistence(timeout: 5), "Detail-Sheet für \(name) öffnet nicht")
        XCTAssertTrue(element("detail.close").exists, "Schließen-Button fehlt")
        XCTAssertTrue(sheet.staticTexts[name].exists, "Sheet zeigt nicht \(name)")

        remote.press(.menu)
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: sheet)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(element("dashboard").exists)
    }
}
