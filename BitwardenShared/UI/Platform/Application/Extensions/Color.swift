import SwiftUI

extension Color {
    // MARK: Initialization

    /// Conveniently initializes a `Color` using a hex value.
    ///
    /// - Parameter hex: The hex value as a string.
    ///
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        if Scanner(string: hexSanitized).scanHexInt64(&rgb) {
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0
            )
        } else {
            self.init(red: 0, green: 0, blue: 0)
        }
    }

    // MARK: Methods

    /// Determines whether a `Color` is considered light based off of its luminance.
    ///
    /// When a light color is used as a background, the overlaid text should be dark.
    ///
    /// - Returns: Whether a `Color` is considered light based off of its luminance.
    ///
    func isLight() -> Bool {
        // algorithm from: http://www.w3.org/WAI/ER/WD-AERT/#color-contrast
        let uiColor = UIColor(self)
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let luminance = ((red * 299) + (green * 587) + (blue * 114)) / 1000
        return luminance >= 0.65
    }
}
