import SwiftUI

// MARK: - PageHeaderView

/// A view that renders a header for page. This support displaying an image, title, and message.
///
struct PageHeaderView: View {
    enum ImageSizeMode: Equatable {
        case constant
        case largerInPortrait
    }

    // MARK: Properties

    /// The image to display in the page header.
    let image: Image

    /// How to handle image size between landscape and portrait.
    let imageSizeMode: ImageSizeMode

    /// The message to display in the page header.
    let message: String

    /// The title to display in the page header.
    let title: String

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    // MARK: Computed Properties

    var imageDimension: CGFloat {
        switch imageSizeMode {
        case .constant:
            return 100
        case .largerInPortrait:
            return verticalSizeClass == .regular ? 124 : 100
        }
    }

    // MARK: View

    var body: some View {
        dynamicStackView {
            image
                .resizable()
                .frame(width: imageDimension, height: imageDimension)

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
    ///   - title: The title to display.
    ///   - message: The message to display.
    ///
    init(image: Image, imageSizeMode: ImageSizeMode = .constant, title: String, message: String) {
        self.image = image
        self.imageSizeMode = imageSizeMode
        self.message = message
        self.title = title
    }

    /// Initialize a `PageHeaderView`.
    ///
    /// - Parameters:
    ///   - image: The image asset to display.
    ///   - title: The title to display.
    ///   - message: The message to display.
    ///
    init(image: ImageAsset, imageSizeMode: ImageSizeMode = .constant, title: String, message: String) {
        self.image = image.swiftUIImage
        self.imageSizeMode = imageSizeMode
        self.message = message
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
#Preview("PageHeader Constant") {
    PageHeaderView(
        image: Asset.Images.Illustrations.biometricsPhone,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
    )
}

#Preview("PageHeader LargerInPortrait") {
    PageHeaderView(
        image: Asset.Images.Illustrations.biometricsPhone,
        imageSizeMode: .largerInPortrait,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
    )
}
#endif
