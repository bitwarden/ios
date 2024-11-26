import SwiftUI

// MARK: - PageHeaderView

/// A view that renders a header for page. This support displaying an image, title, and message.
///
struct PageHeaderView: View {
    // MARK: Types

    /// The style to apply to the `PageHeaderView`.
    enum StyleMode {
        /// Normal font style with illustration as image.
        case normalWithIllustration

        /// Large font style with tinted icon as image.
        case largeWithTintedIcon
    }

    // MARK: Properties

    /// The image to display in the page header.
    let image: Image

    /// The message to display in the page header.
    let message: String

    /// The title to display in the page header.
    let title: String

    /// The style to apply to this view.
    let style: StyleMode

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    // MARK: View

    var body: some View {
        dynamicStackView {
            switch style {
            case .normalWithIllustration:
                image
                    .resizable()
                    .frame(width: 100, height: 100)
            case .largeWithTintedIcon:
                image
                    .resizable()
                    .frame(width: 70, height: 70)
                    .foregroundStyle(Asset.Colors.iconSecondary.swiftUIColor)
            }

            VStack(spacing: 16) {
                Text(title)
                    .apply { text in
                        switch style {
                        case .normalWithIllustration:
                            text.styleGuide(.title2, weight: .bold)
                        case .largeWithTintedIcon:
                            text.styleGuide(.hugeTitle, weight: .bold)
                        }
                    }
                    .accessibilityLabel("HeaderTitle")

                Text(LocalizedStringKey(message))
                    .apply { text in
                        switch style {
                        case .normalWithIllustration:
                            text.styleGuide(.body)
                        case .largeWithTintedIcon:
                            text.styleGuide(.title2)
                        }
                    }
                    .accessibilityLabel("HeaderMessage")
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
    ///   - style: The style to use for this view.
    ///
    init(image: Image, title: String, message: String, style: StyleMode = .normalWithIllustration) {
        self.image = image
        self.message = message
        self.title = title
        self.style = style
    }

    /// Initialize a `PageHeaderView`.
    ///
    /// - Parameters:
    ///   - image: The image asset to display.
    ///   - title: The title to display.
    ///   - message: The message to display.
    ///   - style: The style to use for this view.
    ///
    init(image: ImageAsset, title: String, message: String, style: StyleMode = .normalWithIllustration) {
        self.image = image.swiftUIImage
        self.message = message
        self.title = title
        self.style = style
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
#Preview("PageHeader Normal") {
    PageHeaderView(
        image: Asset.Images.Illustrations.biometricsPhone,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins
    )
}

#Preview("PageHeader Large") {
    PageHeaderView(
        image: Asset.Images.plus24,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins,
        style: .largeWithTintedIcon
    )
}

#endif
