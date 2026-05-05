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
                openURL(url) { success in
                    if !success {
                        store.send(.urlOpenFailed)
                    }
                }
                store.send(.clearURL)
            }
    }

    // MARK: Private Views

    /// The main content of the view.
    private var content: some View {
        VStack(spacing: 0) {
            if store.state.showSelfHostedBanner {
                selfHostedBanner
                    .padding(.bottom, 16)
            }

            if store.state.showPricingErrorBanner {
                pricingErrorBanner
                    .padding(.bottom, 16)
            }

            premiumCard
                .padding(.bottom, 24)

            if !store.state.isSelfHosted, !store.state.showPricingErrorBanner {
                upgradeButton
                    .padding(.bottom, 12)

                stripeFooter
            }
        }
        .scrollView()
        .task {
            await store.perform(.appeared)
        }
    }

    /// The premium upgrade card containing price, description, and features.
    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.state.isSelfHosted {
                Text(Localizations.unlockMoreAdvancedFeaturesWithPremiumPlan)
                    .styleGuide(.headline, weight: .semibold)
                    .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
                    .padding(.bottom, 16)
            } else {
                if store.state.premiumPrice != nil {
                    priceSection
                        .padding(.bottom, 4)
                }

                Text(Localizations.unlockMoreAdvancedFeaturesWithPremiumPlan)
                    .styleGuide(.body)
                    .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
                    .padding(.bottom, 16)
            }

            PremiumFeaturesList()
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .background(Color(asset: SharedAsset.Colors.backgroundSecondary))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// The price display section.
    private var priceSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(store.state.premiumPrice ?? "")
                .styleGuide(.largeTitle, weight: .semibold)
                .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))

            Text(Localizations.perMonth)
                .styleGuide(.body)
                .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
        }
    }

    /// The pricing error banner shown when the premium price cannot be fetched.
    private var pricingErrorBanner: some View {
        ActionCard(
            title: Localizations.pricingUnavailable,
            message: Localizations.checkYourConnectionAndTryAgain,
            actionButtonState: ActionCard.ButtonState(title: Localizations.tryAgain) {
                await store.perform(.retryFetchPriceTapped)
            },
            dismissButtonState: ActionCard.ButtonState(title: Localizations.close) {
                store.send(.dismissPricingErrorBannerTapped)
            },
        ) {
            SharedAsset.Icons.informationCircle24.swiftUIImage
                .foregroundStyle(SharedAsset.Colors.iconSecondary.swiftUIColor)
        }
    }

    /// The self-hosted info banner displayed above the premium card.
    private var selfHostedBanner: some View {
        ActionCard(
            message: Localizations.toManageYourPremiumSubscriptionDescriptionLong,
            dismissButtonState: ActionCard.ButtonState(title: Localizations.close) {
                store.send(.dismissBannerTapped)
            },
        ) {
            SharedAsset.Icons.informationCircle24.swiftUIImage
                .foregroundStyle(SharedAsset.Colors.iconSecondary.swiftUIColor)
        }
    }

    /// The footer text about Stripe checkout.
    private var stripeFooter: some View {
        Text(Localizations.youllGoToStripeSecureCheckoutToCompleteYourPurchase)
            .styleGuide(.subheadline)
            .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// The upgrade button.
    private var upgradeButton: some View {
        AsyncButton {
            await store.perform(.upgradeNowTapped)
        } label: {
            HStack(spacing: 8) {
                SharedAsset.Icons.externalLink16.swiftUIImage
                    .accessibilityHidden(true)

                Text(Localizations.upgradeNow)
            }
        }
        .buttonStyle(.primary())
        .disabled(store.state.isLoading)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Cloud") {
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

#Preview("Self-Hosted") {
    NavigationView {
        PremiumUpgradeView(
            store: Store(
                processor: StateProcessor(
                    state: PremiumUpgradeState(
                        isSelfHosted: true,
                    ),
                ),
            ),
        )
    }
}
#endif
