import SnapshotTesting
import SwiftUI

extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    /// A default snapshot in portrait on iPhone 13, with precision 1 and perceptual precision of 0.99.
    static var defaultPortrait: Snapshotting {
        .image(
            precision: 1,
            perceptualPrecision: 0.99,
            layout: .device(config: .iPhone13),
            traits: .init(userInterfaceStyle: .light)
        )
    }
}
