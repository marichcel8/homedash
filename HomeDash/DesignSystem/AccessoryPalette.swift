import SwiftUI

/// Akzentfarben pro Kategorie – an die Apple-Home-Tile-Fills angelehnt.
/// Werte sind die dunklen iOS-Systemfarben (Hex-Referenz),
/// damit sie nah an dem wirken, was Apple in der Home-App nutzt.
enum AccessoryPalette {
    static let warmLight    = Color(red: 1.00, green: 0.84, blue: 0.04) // systemYellow dark
    static let outlet       = Color(red: 0.04, green: 0.52, blue: 1.00) // systemBlue dark
    static let switchAcc    = Color(red: 0.04, green: 0.52, blue: 1.00)
    static let lockSecured  = Color(red: 0.19, green: 0.82, blue: 0.35) // systemGreen dark
    static let lockOpen     = Color(red: 1.00, green: 0.62, blue: 0.04) // systemOrange dark
    static let heating      = Color(red: 1.00, green: 0.62, blue: 0.04)
    static let cooling      = Color(red: 0.04, green: 0.52, blue: 1.00)
    static let fan          = Color(red: 0.39, green: 0.82, blue: 1.00) // systemCyan dark
    static let sensorActive = Color(red: 0.37, green: 0.36, blue: 0.90) // systemIndigo dark
    static let security     = Color(red: 1.00, green: 0.27, blue: 0.23) // systemRed dark
    static let valve        = Color(red: 0.04, green: 0.52, blue: 1.00)
    static let garageOpen   = Color(red: 1.00, green: 0.62, blue: 0.04)
    static let window       = Color(red: 0.68, green: 0.56, blue: 0.41) // systemBrown dark
    static let speaker      = Color(red: 0.75, green: 0.35, blue: 0.95) // systemPurple dark
    static let neutral      = Color(white: 0.55)

    /// Standardfarbe für die App: das Coral/Tomato des HomeDash-Branding.
    static let brand = Color(red: 0.04, green: 0.52, blue: 1.00)
}
