import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - PremiumUpgradeCompleteView

/// A view that informs the user that the premium upgrade was successful.
///
struct PremiumUpgradeCompleteView: View {
    // MARK: Properties

    /// An object used to open URLs from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<Void, PremiumUpgradeCompleteAction, Void>

    // MARK: View

    var body: some View {
        VStack(spacing: 12) {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.premiumSuccess,
                style: .smallImage,
                title: Localizations.upgradedToPremium,
                message: Localizations.youNowHaveAccessToAdvancedSecurityDescriptionLong,
            )

            learnMoreButton
                .padding(.top, 12)

            closeButton
        }
        .padding(.top, 12)
        .scrollView()
        .navigationBar(title: "", titleDisplayMode: .inline)
    }

    // MARK: Private Views

    /// The "Close" button that dismisses the modal.
    private var closeButton: some View {
        Button(Localizations.close) {
            store.send(.closeTapped)
        }
        .buttonStyle(.secondary())
    }

    /// The "Learn more" button that opens the Premium features page in the browser.
    private var learnMoreButton: some View {
        Button {
            openURL(ExternalLinksConstants.learnMoreAboutPremium)
        } label: {
            HStack(spacing: 8) {
                SharedAsset.Icons.externalLink16.swiftUIImage
                    .accessibilityHidden(true)

                Text(Localizations.learnMore)
            }
        }
        .buttonStyle(.primary())
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    PremiumUpgradeCompleteView(store: Store(processor: StateProcessor()))
        .navStackWrapped
}
#endif
