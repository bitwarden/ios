import SwiftUI

public extension Label {
    /// Initialize a label with a title and image.
    ///
    /// - Parameters:
    ///   - title: The title of the label.
    ///   - image: The image to display in the label.
    ///
    init(_ title: String, image: Image) where Title == Text, Icon == Image {
        self.init {
            Text(title)
        } icon: {
            image
        }
    }

    /// Initialize a label with a title and image which scales with dynamic type.
    ///
    /// - Parameters:
    ///   - title: The title of the label.
    ///   - image: The image to display in the label.
    ///   - scaleImageDimension: The height and width of the square image as the default size before
    ///     any scaling.
    ///
    @MainActor
    init(_ title: String, image: Image, scaleImageDimension dimension: CGFloat) where Title == Text, Icon == AnyView {
        self.init {
            Text(title)
        } icon: {
            // AnyView is needed here to get back to a concrete type as opposed to `some View` as a
            // result of applying the frame modifier.
            AnyView(image.scaledFrame(width: dimension, height: dimension))
        }
    }
}
