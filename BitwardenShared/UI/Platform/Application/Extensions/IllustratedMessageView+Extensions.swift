import BitwardenKit
import SwiftUI

extension IllustratedMessageView {
    /// Initialize a `IllustratedMessageView`.
    ///
    /// - Parameters:
    ///   - image: The image asset to display.
    ///   - style: The style of the message view.
    ///   - title: The title to display.
    ///   - message: The message to display.
    ///   - accessory: An optional accessory view to display.
    ///
    init(
        image: ImageAsset,
        style: IllustratedMessageStyle = .smallImage,
        title: String? = nil,
        message: String,
        @ViewBuilder accessory: () -> Accessory,
    ) {
        self.init(
            image: image.swiftUIImage,
            style: style,
            title: title,
            message: message,
            accessory: accessory,
        )
    }
}

extension IllustratedMessageView where Accessory == EmptyView {
    /// Initialize a `IllustratedMessageView`.
    ///
    /// - Parameters:
    ///   - image: The image asset to display.
    ///   - style: The style of the message view.
    ///   - title: The title to display.
    ///   - message: The message to display.
    ///
    init(
        image: ImageAsset,
        style: IllustratedMessageStyle = .smallImage,
        title: String? = nil,
        message: String,
    ) {
        self.init(
            image: image.swiftUIImage,
            style: style,
            title: title,
            message: message,
        )
    }
}
