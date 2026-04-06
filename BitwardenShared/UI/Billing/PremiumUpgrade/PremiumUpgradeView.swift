import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - PremiumUpgradeView

/// A view that displays the premium upgrade information and allows users to upgrade.
///
struct PremiumUpgradeView: View {
    // MARK: Properties

    /// An object used to open URLs from this view.
    @Environment(\.openURL) private var openURL

    /// The store that renders the view.
    @ObservedObject var store: Store<PremiumUpgradeState, PremiumUpgradeAction, PremiumUpgradeEffect>

    // MARK: View

    var body: some View {
        content
            .navigationBar(title: Localizations.upgradeToPremium, titleDisplayMode: .inline)
            .toolbar {
                cancelToolbarItem {
                    store.send(.cancelTapped)
                }
            }
            .onChange(of: store.state.checkoutURL) { url in
                guard let url else { return }
                openURL(url)
                store.send(.clearURL)
            }
    }

    // MARK: Private Views

    /// The main content of the view.
    private var content: some View {
        VStack(spacing: 0) {
            premiumCard
                .padding(.bottom, 24)

            upgradeButton
                .padding(.bottom, 12)

            stripeFooter
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(asset: SharedAsset.Colors.backgroundPrimary))
    }

    /// The premium upgrade card containing price, description, and features.
    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            priceSection
                .padding(.bottom, 4)

            Text(Localizations.unlockMoreAdvancedFeaturesWithPremiumPlan)
                .styleGuide(.body)
                .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
                .padding(.bottom, 16)

            featuresList
        }
        .padding(16)
        .background(Color(asset: SharedAsset.Colors.backgroundSecondary))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// The price display section.
    private var priceSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(store.state.premiumPrice)
                .styleGuide(.largeTitle, weight: .semibold)
                .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))

            Text(Localizations.perMonth)
                .styleGuide(.body)
                .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
        }
    }

    /// The list of premium features.
    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().padding(.bottom, 4)
            featureRow(Localizations.builtInAuthenticator, showDivider: true)
            featureRow(Localizations.emergencyAccess, showDivider: true)
            featureRow(Localizations.secureFileStorage, showDivider: true)
            featureRow(Localizations.breachMonitoring, showDivider: false)
        }
    }

    /// A single feature row with a check icon.
    ///
    /// - Parameters:
    ///   - text: The feature text to display.
    ///   - showDivider: Whether to show a divider below this row.
    /// - Returns: A view displaying the feature with a check icon.
    ///
    private func featureRow(_ text: String, showDivider: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                SharedAsset.Icons.checkCircle24.swiftUIImage
                    .foregroundColor(Color(asset: SharedAsset.Colors.textInteraction))

                Text(text)
                    .styleGuide(.headline, weight: .semibold)
                    .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
            }
            .padding(.top, 16)

            if showDivider {
                Divider()
                    .padding(.top, 16)
            }
        }
    }

    /// The upgrade button.
    private var upgradeButton: some View {
        AsyncButton {
            await store.perform(.upgradeNowTapped)
        } label: {
            HStack(spacing: 8) {
                SharedAsset.Icons.externalLink16.swiftUIImage

                Text(Localizations.upgradeNow)
            }
        }
        .buttonStyle(.primary())
        .disabled(store.state.isLoading)
    }

    /// The footer text about Stripe checkout.
    private var stripeFooter: some View {
        Text(Localizations.youWillGoToStripeSecureCheckoutToCompleteYourPurchase)
            .styleGuide(.subheadline)
            .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        PremiumUpgradeView(
            store: Store(
                processor: StateProcessor(
                    state: PremiumUpgradeState(),
                ),
            ),
        )
    }
}
#endif
