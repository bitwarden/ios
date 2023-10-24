import SnapshotTesting
import SwiftUI

extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    /// The default precision for all snapshots in this project. Defaults to `1`.
    private static var defaultPrecision: Float { 1 }

    /// The default perceptual precision for all snapshots in this project. Defaults to `0.95`.
    private static var defaultPerceptualPrecision: Float { 0.95 }

    /// A default snapshot in portrait on iPhone 13, with precision 1 and perceptual precision of 0.95.
    static var defaultPortrait: Snapshotting {
        .image(
            precision: defaultPrecision,
            perceptualPrecision: defaultPerceptualPrecision,
            layout: .device(config: .iPhone13(.portrait)),
            traits: .init(userInterfaceStyle: .light)
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
}
