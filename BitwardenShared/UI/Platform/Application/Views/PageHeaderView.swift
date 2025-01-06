import SwiftUI

// MARK: - PageHeaderView

/// A view that renders a header for page. This support displaying a square image, title, and message.
///
struct PageHeaderView: View {
    // MARK: Properties

    /// The image to display in the page header.
    let image: Image

    /// The message to display in the page header.
    let message: String

    /// The style for rendering the page header.
    let style: PageHeaderStyle

    /// The title to display in the page header.
    let title: String

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    // MARK: View

    var body: some View {
        dynamicStackView {
            image
                .resizable()
                .frame(
                    width: style.imageSize(verticalSizeClass ?? .regular),
                    height: style.imageSize(verticalSizeClass ?? .regular)
                )
                .if(style.imageColor != nil) { view in
                    return view.foregroundStyle(style.imageColor!)
                }

            VStack(spacing: style.spaceBetweenTitleAndMessage) {
                Text(title)
                    .styleGuide(style.titleTextStyle, weight: .bold)
                    .accessibilityIdentifier("HeaderTitle")

                Text(LocalizedStringKey(message))
                    .styleGuide(style.messageTextStyle)
                    .accessibilityIdentifier("HeaderMessage")
            }
        }
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
    }

    // MARK: Initialization

    /// Initialize a `PageHeaderView`.
    ///
    /// - Parameters:
    ///   - image: The image to display.
    ///   - style: The style of the page header.
    ///   - title: The title to display.
    ///   - message: The message to display.
    ///   - style: The style to use for this view.
    ///
    init(
        image: Image,
        style: PageHeaderStyle = .smallImage,
        title: String,
        message: String
    ) {
        self.image = image
        self.message = message
        self.style = style
        self.title = title
    }

    /// Initialize a `PageHeaderView`.
    ///
    /// - Parameters:
    ///   - image: The image asset to display.
    ///   - style: The style of the page header.
    ///   - title: The title to display.
    ///   - message: The message to display.
    ///   - style: The style to use for this view.
    ///
    init(
        image: ImageAsset,
        style: PageHeaderStyle = .smallImage,
        title: String,
        message: String
    ) {
        self.image = image.swiftUIImage
        self.message = message
        self.style = style
        self.title = title
    }

    // MARK: Private

    /// A dynamic stack view that lays out content vertically when in a regular vertical size class
    /// and horizontally for the compact vertical size class.
    @ViewBuilder
    private func dynamicStackView(@ViewBuilder content: () -> some View) -> some View {
        if verticalSizeClass == .regular {
            VStack(spacing: style.spaceBetweenImageAndText.value(.regular), content: content)
        } else {
            HStack(spacing: style.spaceBetweenImageAndText.value(verticalSizeClass ?? .compact), content: content)
                .padding(.horizontal, 80)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("SmallImage") {
    PageHeaderView(
        image: Asset.Images.Illustrations.biometricsPhone,
        style: .smallImage,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
    )
}

#Preview("MediumImage") {
    PageHeaderView(
        image: Asset.Images.Illustrations.biometricsPhone,
        style: .mediumImage,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
    )
}

#Preview("LargeTextTintedIcon") {
    PageHeaderView(
        image: Asset.Images.plus24,
        style: .largeTextTintedIcon,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
    )
}

#endif

// MARK: OrientationBasedDimension

/// An `OrientationBasedValue` encapsulates values that might be different
/// for rendering based on orientation, such as image size or space between text.
struct OrientationBasedValue<T: Equatable & Sendable>: Equatable, Sendable {
    // MARK: Properties

    /// The dimension size in portrait mode.
    let portrait: T

    /// The dimension size in landscape mode.
    let landscape: T

    // MARK: Functions

    /// Convenience function for getting the correct value based on the orientation.
    ///
    func value(_ verticalSizeClass: UserInterfaceSizeClass) -> T {
        verticalSizeClass == .regular ? portrait : landscape
    }
}

// MARK: PageHeaderStyle

/// A `PageHeaderStyle` contains the metrics for rendering a `PageHeaderView`.
///
struct PageHeaderStyle: Sendable {
    // MARK: Properties

    /// A foreground tint to apply to the image. Only applied if this has a value.
    let imageColor: Color?

    /// The size of the image. Because the image is square, this value can be used for both
    /// the height and the width.
    let imageSize: OrientationBasedValue<CGFloat>

    /// The text style applied to the message.
    let messageTextStyle: StyleGuideFont

    /// The space between the image and the text block. In a portrait orientation, this is
    /// vertical space; in a landscape orientation, this is horizontal space.
    let spaceBetweenImageAndText: OrientationBasedValue<CGFloat>

    /// The space between the title and message in the text block. It is the same regardless of
    /// orientation.
    let spaceBetweenTitleAndMessage: CGFloat

    /// The text style applied to the title.
    let titleTextStyle: StyleGuideFont

    // MARK: Functions

    /// Convenience function for getting the image size based on the orientation.
    /// Because the image is square, this value can be used for both the height and the width.
    func imageSize(_ verticalSizeClass: UserInterfaceSizeClass) -> CGFloat {
        imageSize.value(verticalSizeClass)
    }

    /// Convenience function for getting the space between the image and text based on the orientation.
    /// In a portrait orientation, this is vertical space; in a landscape orientation, this is horizontal space.
    func spaceBetweenImageAndText(_ verticalSizeClass: UserInterfaceSizeClass) -> CGFloat {
        spaceBetweenImageAndText.value(verticalSizeClass)
    }
}

// MARK: - PageHeaderStyle Internal Constants

private extension PageHeaderStyle {
    /// The height and width of a square icon image
    static let iconSquareImageDimension: CGFloat = 70

    /// The height and width of a square medium image
    static let mediumSquareImageDimension: CGFloat = 124

    /// The height and width of a square small image
    static let smallSquareImageDimension: CGFloat = 100

}

// MARK: - PageHeaderStyle Constants

extension PageHeaderStyle {
    static let largeTextTintedIcon = PageHeaderStyle(
        imageColor: Asset.Colors.iconSecondary.swiftUIColor,
        imageSize: OrientationBasedValue(
            portrait: iconSquareImageDimension,
            landscape: iconSquareImageDimension
        ),
        messageTextStyle: .title2,
        spaceBetweenImageAndText: OrientationBasedValue(
            portrait: 32,
            landscape: 32
        ),
        spaceBetweenTitleAndMessage: 16,
        titleTextStyle: .hugeTitle
    )

    static let mediumImage = PageHeaderStyle(
        imageColor: nil,
        imageSize: OrientationBasedValue(
            portrait: mediumSquareImageDimension,
            landscape: smallSquareImageDimension
        ),
        messageTextStyle: .body,
        spaceBetweenImageAndText: OrientationBasedValue(
            portrait: 24,
            landscape: 32
        ),
        spaceBetweenTitleAndMessage: 12,
        titleTextStyle: .title2
    )

    static let smallImage = PageHeaderStyle(
        imageColor: nil,
        imageSize: OrientationBasedValue(
            portrait: smallSquareImageDimension,
            landscape: smallSquareImageDimension
        ),
        messageTextStyle: .body,
        spaceBetweenImageAndText: OrientationBasedValue(
            portrait: 32,
            landscape: 32
        ),
        spaceBetweenTitleAndMessage: 16,
        titleTextStyle: .title2
    )
}
