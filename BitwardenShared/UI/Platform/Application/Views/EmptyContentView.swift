import SwiftUI

/// A view that renders an empty state for a view when there's no content to display. This support
/// displaying an image, message, and button.
///
struct EmptyContentView<TextContent: View, ButtonContent: View>: View {
    // MARK: Types

    /// A type representing the size of the image in the view.
    ///
    enum ImageSize {
        /// A small image size, 100x100pt.
        case small

        /// A large image size, 124x124pt.
        case large

        /// The height and width size dimension of the square image.
        var dimension: CGFloat {
            switch self {
            case .small: 100
            case .large: 124
            }
        }
    }

    // MARK: Properties

    /// The button content.
    let button: ButtonContent

    /// The image to display.
    let image: Image

    /// The size of the image.
    let imageSize: ImageSize

    /// A text message to display describing the empty state.
    let text: TextContent

    // MARK: View

    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 24) {
                image
                    .resizable()
                    .frame(width: imageSize.dimension, height: imageSize.dimension)
                    .accessibilityHidden(true)

                text
                    .styleGuide(.body)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .multilineTextAlignment(.center)

                button
                    .buttonStyle(.primary(shouldFillWidth: false))
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: reader.size.height)
            .scrollView(addVerticalPadding: false)
        }
    }

    // MARK: Initialization

    /// Initialize an `EmptyContentView`.
    ///
    /// - Parameters:
    ///   - image: The image to display.
    ///   - imageSize: The size of the image.
    ///   - text: A view builder closure that returns the text content to display in the middle of
    ///     the view.
    ///   - button: A view builder closure that returns a button to display at the bottom of the view.
    ///
    init(
        image: Image,
        imageSize: ImageSize = .small,
        @ViewBuilder text: () -> TextContent,
        @ViewBuilder button: () -> ButtonContent
    ) {
        self.image = image
        self.imageSize = imageSize
        self.text = text()
        self.button = button()
    }

    /// Initialize an `EmptyContentView`.
    ///
    /// - Parameters:
    ///   - image: The image to display.
    ///   - imageSize: The size of the image.
    ///   - text: The text content to display in the middle of the view.
    ///   - buttonContent: A view builder closure that returns a button to display at the bottom of the view.
    ///
    init(
        image: Image,
        imageSize: ImageSize = .small,
        text: String,
        @ViewBuilder buttonContent: () -> ButtonContent
    ) where TextContent == Text {
        self.image = image
        self.imageSize = imageSize
        self.text = Text(text)
        button = buttonContent()
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    EmptyContentView(
        image: Asset.Images.Illustrations.items.swiftUIImage,
        text: Localizations.thereAreNoItemsInYourVaultThatMatchX("Bitwarden")
    ) {
        Button {} label: {
            Label { Text(Localizations.addItem) } icon: {
                Asset.Images.plus16.swiftUIImage
                    .imageStyle(.accessoryIcon16(
                        color: Asset.Colors.buttonFilledForeground.swiftUIColor,
                        scaleWithFont: true
                    ))
            }
        }
    }
}
#endif
