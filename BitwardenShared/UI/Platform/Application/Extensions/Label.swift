import SwiftUI

extension Label {
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
}
