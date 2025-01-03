import SwiftUI

// MARK: - PageHeaderView

/// A view that renders a header for page. This support displaying an image, title, and message.
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
                    width: verticalSizeClass == .regular ? style.imageSizePortrait : style.imageSizeLandscape,
                    height: verticalSizeClass == .regular ? style.imageSizePortrait : style.imageSizeLandscape
                )

            VStack(spacing: 16) {
                Text(title)
                    .styleGuide(.title2, weight: .bold)

                Text(message)
                    .styleGuide(.body)
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
            VStack(spacing: 32, content: content)
        } else {
            HStack(spacing: 32, content: content)
                .padding(.horizontal, 80)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("PageHeader SmallImage") {
    PageHeaderView(
        image: Asset.Images.Illustrations.biometricsPhone,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
    )
}

#Preview("PageHeader MediumImage") {
    PageHeaderView(
        image: Asset.Images.Illustrations.biometricsPhone,
        style: .mediumImage,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
    )
}
#endif

// MARK: OrientationBasedDimension

/// An `OrientationBasedValue` encapsulates values that might be different
/// for rendering based on orientation, such as image size or space between text.
struct OrientationBasedValue<T> {
    /// The dimension size in portrait mode.
    let portrait: T

    /// The dimension size in landscape mode.
    let landscape: T
}

// MARK: PageHeaderStyle

/// A `PageHeaderStyle` contains the metrics for rendering a `PageHeaderView`.
///
struct PageHeaderStyle: Equatable, Sendable {
    // MARK: Properties

    let imageSizePortrait: CGFloat
    let imageSizeLandscape: CGFloat

    /// The height of the image
//    let imageHeight: OrientationBasedValue<CGFloat>

    /// The width of the image
//    let imageWidth: OrientationBasedValue<CGFloat>
}

// MARK: - PageHeaderStyle Internal Constants

private extension PageHeaderStyle {
    /// The height and width of a square medium image
    static let mediumSquareImageDimension: CGFloat = 124

    /// The height and width of a square small image
    static let smallSquareImageDimension: CGFloat = 100
}

// MARK: - PageHeaderStyle Constants

extension PageHeaderStyle {
    static let mediumImage = PageHeaderStyle(
        imageSizePortrait: mediumSquareImageDimension,
        imageSizeLandscape: smallSquareImageDimension
    )

    static let smallImage = PageHeaderStyle(
        imageSizePortrait: smallSquareImageDimension,
        imageSizeLandscape: smallSquareImageDimension
    )

    /// The style for a medium-sized image in portrait and small in landscape.
    /// This is used in the two-factor authentication notice.
//    static let mediumImage = PageHeaderStyle(
//        imageHeight: OrientationBasedValue(
//            portrait: PageHeaderStyle.mediumSquareImageDimension,
//            landscape: PageHeaderStyle.smallSquareImageDimension
//        ),
//        imageWidth: OrientationBasedValue(
//            portrait: PageHeaderStyle.mediumSquareImageDimension,
//            landscape: PageHeaderStyle.smallSquareImageDimension
//        )
//    )

    /// The style for a small-sized image in both portrait and landscape.
    /// This is the default style.
    /// This is used in `CompleteRegistrationView`, `EmailAccessView`,
    /// `VaultUnlockSetupView`, `ExtensionActivationView`, `SendListView`,
    /// `ImportLoginsView`, `ImportLoginsSuccessView`, and an empty vault list.
//    static let smallImage = PageHeaderStyle(
//        imageHeight: OrientationBasedDimension(
//            portrait: PageHeaderStyle.smallSquareImageDimension,
//            landscape: PageHeaderStyle.smallSquareImageDimension
//        ),
//        imageWidth: OrientationBasedDimension(
//            portrait: PageHeaderStyle.smallSquareImageDimension,
//            landscape: PageHeaderStyle.smallSquareImageDimension
//        )
//    )
}
