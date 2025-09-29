import BitwardenResources
import SwiftUI

// MARK: - ItemListCardView

/// An item list card view,
///
struct ItemListCardView<ImageContent: View>: View {
    // MARK: Properties

    /// The body text to display in the card.
    var bodyText: String

    /// The button text to display in the card.
    var buttonText: String

    /// The image to display in the card.
    @ViewBuilder let leftImage: ImageContent

    /// The button text for the secondary button in the card.
    var secondaryButtonText: String?

    /// The title text to display in the card.
    var titleText: String

    // MARK: Closures

    /// The callback action to perform.
    var actionTapped: () -> Void

    /// The close callback to perform.
    var closeTapped: () -> Void

    /// The action to perform when the secondary button is tapped.
    var secondaryActionTapped: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                leftImage

                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        Text(titleText)
                            .styleGuide(.headline)
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                        Text(bodyText)
                            .styleGuide(.subheadline)
                            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    closeTapped()
                } label: {
                    Image(decorative: Asset.Images.cancel)
                        .padding(16) // Add padding to increase tappable area...
                }
                .padding(-16) // ...but remove it to not affect layout.
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(Localizations.close)
            }

            VStack(spacing: 0) {
                Button {
                    actionTapped()
                } label: {
                    Text(buttonText)
                }
                .buttonStyle(.primary())

                if let secondaryButtonText, let secondaryActionTapped {
                    Button {
                        secondaryActionTapped()
                    } label: {
                        Text(secondaryButtonText)
                    }
                    .buttonStyle(.bitwardenBorderless)
                    .padding(.bottom, -8) // Remove extra padding below the borderless button.
                }
            }
        }
        .padding(16)
        .background {
            Asset.Colors.backgroundPrimary.swiftUIColor
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: Previews

#if DEBUG
struct ItemListCardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                ItemListCardView(
                    bodyText: Localizations
                        .allowAuthenticatorAppSyncingInSettingsToViewAllYourVerificationCodesHere,
                    buttonText: Localizations.takeMeToTheAppSettings,
                    leftImage: {
                        Image(decorative: Asset.Images.syncArrow)
                            .foregroundColor(Asset.Colors.primaryBitwardenLight.swiftUIColor)
                            .frame(width: 24, height: 24)
                    },
                    titleText: Localizations.syncWithTheBitwardenApp,
                    actionTapped: {},
                    closeTapped: {}
                )

                ItemListCardView(
                    bodyText: Localizations
                        .allowAuthenticatorAppSyncingInSettingsToViewAllYourVerificationCodesHere,
                    buttonText: Localizations.takeMeToTheAppSettings,
                    leftImage: {
                        Image(decorative: Asset.Images.syncArrow)
                            .foregroundColor(Asset.Colors.primaryBitwardenLight.swiftUIColor)
                            .frame(width: 24, height: 24)
                    },
                    secondaryButtonText: Localizations.learnMore,
                    titleText: Localizations.syncWithTheBitwardenApp,
                    actionTapped: {},
                    closeTapped: {},
                    secondaryActionTapped: {}
                )
            }
            .padding(16)
        }
    }
}
#endif
