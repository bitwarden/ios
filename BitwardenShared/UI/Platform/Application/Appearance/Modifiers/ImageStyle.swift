import Foundation
import SwiftUI

// MARK: - ImageStyle

/// A struct containing configuration properties for applying common properties to images across
/// the app.
///
struct ImageStyle {
    // MARK: Properties

    /// The foreground color of the image.
    let color: Color

    /// The width of the image.
    let width: CGFloat

    /// The height of the image.
    let height: CGFloat
}

extension ImageStyle {
    /// An `ImageStyle` for applying common properties to a circular accessory icon.
    ///
    /// - Size: 16x16pt
    /// - Color: `Asset.Colors.primaryBitwarden`
    ///
    static let accessoryIcon = accessoryIcon()

    /// An `ImageStyle` for applying common properties for icons within a row.
    ///
    /// - Size: 22x22pt
    /// - Color: `Asset.Colors.textSecondary`
    ///
    static let rowIcon = rowIcon()

    /// An `ImageStyle` for applying common properties for icons within a toolbar.
    ///
    /// - Size: 19x19pt
    /// - Color: `Asset.Colors.primaryBitwarden`
    ///
    static let toolbarIcon = ImageStyle(
        color: Asset.Colors.primaryBitwarden.swiftUIColor,
        width: 19,
        height: 19
    )

    /// An `ImageStyle` for applying common properties to a circular accessory icon.
    ///
    /// - Size: 16x16pt
    /// - Color: Defaults to `Asset.Colors.primaryBitwarden`
    ///
    /// - Parameter color: The foreground color of the image. Defaults to `Asset.Colors.primaryBitwarden`.
    ///
    static func accessoryIcon(color: Color = Asset.Colors.primaryBitwarden.swiftUIColor) -> ImageStyle {
        ImageStyle(color: color, width: 16, height: 16)
    }

    /// An `ImageStyle` for applying common properties for icons within a row.
    ///
    /// - Size: 22x22pt
    /// - Color: Defaults to `Asset.Colors.textSecondary`
    ///
    /// - Parameter color: The foreground color of the image. Defaults to `Asset.Colors.textSecondary`.
    ///
    static func rowIcon(color: Color = Asset.Colors.textSecondary.swiftUIColor) -> ImageStyle {
        ImageStyle(color: color, width: 22, height: 22)
    }
}

// MARK: - Image

extension Image {
    /// A view extension that applies common image properties based on a style.
    ///
    /// - Parameter style: The configuration used to set common image properties.
    /// - Returns: The wrapped view modified with the common image modifiers applied.
    ///
    func imageStyle(_ style: ImageStyle) -> some View {
        resizable()
            .frame(width: style.width, height: style.height)
            .foregroundStyle(style.color)
    }
}
