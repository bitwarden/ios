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

    /// The title text to display in the card.
    var titleText: String

    // MARK: Closures

    /// The callback action to perform.
    var actionTapped: () -> Void

    /// The close callback to perform.
    var closeTapped: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            leftImage
                .padding(.leading, 16)

            VStack(alignment: .leading, spacing: 0) {
                Group {
                    Text(titleText)
                        .styleGuide(.headline)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                    Text(bodyText)
                        .styleGuide(.subheadline)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                    Button {
                        actionTapped()
                    } label: {
                        Text(buttonText)
                            .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
                            .styleGuide(.subheadline, weight: .semibold)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                closeTapped()
            } label: {
                Image(decorative: Asset.Images.cancel)
                    .padding(.trailing, 16)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(Localizations.close)
        }
        .padding(.vertical, 16)
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
        ItemListCardView(
            bodyText: Localizations
                .inOrderToViewAllOfYourVerificationCodesYoullNeedToAllowForSyncingOnAllOfYourAccounts,
            buttonText: Localizations.takeMeToTheAppSettings,
            leftImage: {
                Image(decorative: Asset.Images.bwLogo)
                    .foregroundColor(Asset.Colors.primaryBitwardenLight.swiftUIColor)
                    .frame(width: 24, height: 24)
            },
            titleText: Localizations.syncWithTheBitwardenApp,
            actionTapped: {},
            closeTapped: {}
        )
        .padding(16)
    }
}
#endif
