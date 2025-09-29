import BitwardenResources
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

    /// Whether the image should scale with font size changes.
    let scaleWithFont: Bool

    /// The width of the image.
    let width: CGFloat

    /// The height of the image.
    let height: CGFloat
}

extension ImageStyle {
    /// An `ImageStyle` for applying common properties to a circular accessory icon.
    ///
    /// - Size: 16x16pt
    /// - Color: `Asset.Colors.iconPrimary`
    ///
    static let accessoryIcon16 = accessoryIcon16()

    /// An `ImageStyle` for applying common properties to a circular accessory icon.
    ///
    /// - Size: 24x24pt
    /// - Color: `Asset.Colors.iconPrimary`
    ///
    static let accessoryIcon24 = accessoryIcon24()

    /// An `ImageStyle` for applying common properties to an image in a floating action button.
    static let floatingActionButton = ImageStyle(
        color: SharedAsset.Colors.buttonFilledForeground.swiftUIColor,
        scaleWithFont: false,
        width: 32,
        height: 32
    )

    /// An `ImageStyle` for applying common properties for icons within a row.
    ///
    /// - Size: 22x22pt
    /// - Color: `Asset.Colors.textSecondary`
    ///
    static let rowIcon = rowIcon()

    /// An `ImageStyle` for applying common properties for icons within a toolbar.
    ///
    /// - Size: 19x19pt
    /// - Color: `Asset.Colors.iconSecondary`
    ///
    static let toolbarIcon = ImageStyle(
        color: SharedAsset.Colors.iconSecondary.swiftUIColor,
        scaleWithFont: false,
        width: 24,
        height: 24
    )

    /// An `ImageStyle` for applying common properties to a circular accessory icon.
    ///
    /// - Size: 16x16pt
    /// - Color: Defaults to `Asset.Colors.iconSecondary`
    ///
    /// - Parameters:
    ///   - color: The foreground color of the image. Defaults to `Asset.Colors.iconPrimary`.
    ///   - scaleWithFont: Whether the image should scale with font size changes.
    ///
    static func accessoryIcon16(
        color: Color = SharedAsset.Colors.iconPrimary.swiftUIColor,
        scaleWithFont: Bool = false
    ) -> ImageStyle {
        ImageStyle(color: color, scaleWithFont: scaleWithFont, width: 16, height: 16)
    }

    /// An `ImageStyle` for applying common properties to a circular accessory icon.
    ///
    /// - Size: 24x24pt
    /// - Color: Defaults to `Asset.Colors.iconSecondary`
    ///
    /// - Parameters:
    ///   - color: The foreground color of the image. Defaults to `Asset.Colors.iconPrimary`.
    ///   - scaleWithFont: Whether the image should scale with font size changes.
    ///
    static func accessoryIcon24(
        color: Color = SharedAsset.Colors.iconPrimary.swiftUIColor,
        scaleWithFont: Bool = false
    ) -> ImageStyle {
        ImageStyle(color: color, scaleWithFont: scaleWithFont, width: 24, height: 24)
    }

    /// An `ImageStyle` for applying common properties for icons within a row.
    ///
    /// - Size: 22x22pt
    /// - Color: Defaults to `Asset.Colors.textSecondary`
    ///
    /// - Parameters:
    ///   - color: The foreground color of the image. Defaults to `Asset.Colors.textSecondary`.
    ///   - scaleWithFont: Whether the image should scale with font size changes.
    ///
    static func rowIcon(
        color: Color = SharedAsset.Colors.iconPrimary.swiftUIColor,
        scaleWithFont: Bool = true
    ) -> ImageStyle {
        ImageStyle(color: color, scaleWithFont: scaleWithFont, width: 24, height: 24)
    }

    /// An `ImageStyle` for applying common properties for icons within a full screen view.
    ///
    /// - Size: 36x36pt
    /// - Color: Defaults to `Asset.Colors.textSecondary`
    ///
    /// - Parameters:
    ///   - color: The foreground color of the image. Defaults to `Asset.Colors.illustrationOutline`.
    ///   - scaleWithFont: Whether the image should scale with font size changes.
    ///   - size: The size of the icon.
    ///
    static func viewIcon(
        color: Color = SharedAsset.Colors.illustrationOutline.swiftUIColor,
        scaleWithFont: Bool = true,
        size: CGFloat = 36
    ) -> ImageStyle {
        ImageStyle(color: color, scaleWithFont: scaleWithFont, width: size, height: size)
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
            .frame(width: style.width, height: style.height, scaleWithFont: style.scaleWithFont)
            .tint(style.color)
    }
}

// MARK: - View

extension View {
    /// A view extension that applies common image properties based on a style.
    ///
    /// Note: Since this is an extension on `View`, this can't mark the image as resizable, so that
    /// needs to be done on the image prior to applying this modifier. But the advantage of this
    /// over the image extension is that it can be applied to an image nested within a view.
    ///
    /// - Parameter style: The configuration used to set common image properties.
    /// - Returns: The wrapped view modified with the common image modifiers applied.
    ///
    func imageStyle(_ style: ImageStyle) -> some View {
        frame(width: style.width, height: style.height, scaleWithFont: style.scaleWithFont)
            .tint(style.color)
    }
}
