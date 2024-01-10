import SnapshotTesting
import SwiftUI

extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    /// The default precision for all snapshots in this project. Defaults to `1`.
    private static var defaultPrecision: Float { 1 }

    /// The default perceptual precision for all snapshots in this project. Defaults to `0.95`.
    private static var defaultPerceptualPrecision: Float { 0.95 }

    /// A default snapshot in landscape on iPhone 13, with precision 1 and perceptual precision of 0.95.
    static var defaultLandscape: Snapshotting {
        .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.landscape)),
            traits: UITraitCollection(userInterfaceStyle: .light)
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1 and perceptual precision of 0.95.
    static var defaultPortrait: Snapshotting {
        .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.portrait)),
            traits: UITraitCollection(userInterfaceStyle: .light)
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1 and perceptual precision of 0.95.
    /// This also sets the preferred content size category to AX5.
    static var defaultPortraitAX5: Snapshotting {
        .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.portrait)),
            traits: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge),
            ])
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95
    /// and in dark mode.
    static var defaultPortraitDark: Snapshotting {
        .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.portrait)),
            traits: .init(userInterfaceStyle: .dark)
        )
    }

    /// A tall snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95 and in light mode.
    ///
    /// This snapshot has double the height of a standard iPhone 13 snapshot, and should be used when the height
    /// of a screen exceeds the height of the `defaultPortrait` snapshot.
    static var tallPortrait: Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= 2
        return .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: .init(userInterfaceStyle: .light)
        )
    }

    /// A tall snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95 and in light mode.
    ///
    /// This snapshot has triple the height of a standard iPhone 13 snapshot, and should be used when the height
    /// of a screen exceeds the height of the `defaultPortrait` snapshot.
    static var tallPortrait2: Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= 3
        return .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: .init(userInterfaceStyle: .light)
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95
    /// and in light mode.
    ///
    ///  - Parameter heightMultiple: Sets the height multiple of the snapshot relative to the iPhone 13 height.
    ///
    static func portrait(heightMultiple: CGFloat = 1) -> Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= heightMultiple
        return .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: .init(userInterfaceStyle: .light)
        )
    }

    /// A default snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95
    /// and in dark mode.
    ///
    ///  - Parameter heightMultiple: Sets the height multiple of the snapshot relative to the iPhone 13 height.
    ///
    static func portraitDark(heightMultiple: CGFloat = 1) -> Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= heightMultiple
        return .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: .init(userInterfaceStyle: .dark)
        )
    }

    /// A tall snapshot in portrait on iPhone 13, with precision 1, perceptual precision of 0.95 and in light mode.
    /// Should be used when the height of a screen exceeds the height of the `defaultPortrait` with large font sizes.
    ///
    /// This also sets the preferred content size category to AX5.
    ///
    ///  - Parameter heightMultiple: Sets the height multiple of the snapshot relative to the iPhone 13 height.
    ///
    static func tallPortraitAX5(heightMultiple: CGFloat = 4) -> Snapshotting {
        var viewImageConfig = ViewImageConfig.iPhone13(.portrait)
        viewImageConfig.size?.height *= heightMultiple
        return .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: viewImageConfig),
            traits: UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge),
            ])
        )
    }
}
