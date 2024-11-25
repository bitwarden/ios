import SwiftUI

// MARK: - PageHeaderView

/// A view that renders a header for page. This support displaying an image, title, and message.
///
struct PageHeaderView: View {
    // MARK: Types

    /// The style to apply to the `PageHeaderView`.
    enum StyleMode {
        /// Normal font style.
        case normal

        /// Large font style.
        case large
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
            image
                .resizable()
                .frame(width: 100, height: 100)

            VStack(spacing: 16) {
                Text(title)
                    .apply { text in
                        switch style {
                        case .normal:
                            text.styleGuide(.title2, weight: .bold)
                        case .large:
                            text.styleGuide(.largeTitle, weight: .bold)
                        }
                    }

                Text(LocalizedStringKey(message))
                    .apply { text in
                        switch style {
                        case .normal:
                            text.styleGuide(.body)
                        case .large:
                            text.styleGuide(.title2)
                        }
                    }
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
    init(image: Image, title: String, message: String, style: StyleMode = .normal) {
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
    init(image: ImageAsset, title: String, message: String, style: StyleMode = .normal) {
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
        image: Asset.Images.Illustrations.biometricsPhone,
        title: Localizations.setUpUnlock,
        message: Localizations.setUpBiometricsOrChooseAPinCodeToQuicklyAccessYourVaultAndAutofillYourLogins,
        style: .large
    )
}

#endif
