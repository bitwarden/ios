import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - PremiumUpgradeView

/// A view that displays the Premium upgrade information and allows users to upgrade.
///
struct PremiumUpgradeView: View {
    // MARK: Private Properties

    /// The maximum width of the hero illustration.
    private static let heroImageMaxWidth: CGFloat = 319

    // MARK: Properties

    /// The store that renders the view.
    @ObservedObject var store: Store<PremiumUpgradeState, PremiumUpgradeAction, PremiumUpgradeEffect>

    // MARK: View

    var body: some View {
        content
            .navigationBar(title: Localizations.premium, titleDisplayMode: .inline)
            .toolbar {
                cancelToolbarItem(hidden: !store.state.showCancelButton) {
                    store.send(.cancelTapped)
                }
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

                if store.state.priceCancelAnytimeText != nil {
                    priceSection
                        .padding(.bottom, 12)
                }

                stripeFooter
            }
        }
        .scrollView()
        .task {
            await store.perform(.appeared)
        }
    }

    /// The Premium upgrade card containing the hero illustration, headline, and benefits.
    private var premiumCard: some View {
        VStack(spacing: 16) {
            Asset.Images.Illustrations.premiumUpgradeHero.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: Self.heroImageMaxWidth)
                .accessibilityHidden(true)

            Text(Localizations.unlockAdvancedProtection)
                .styleGuide(.title2, weight: .bold)
                .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            PremiumUpgradeBenefitsList()
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .background(
            Asset.Images.Illustrations.premiumUpgradeCardBackground.swiftUIImage
                .resizable()
                .accessibilityHidden(true),
        )
    }

    /// The price display section.
    private var priceSection: some View {
        Text(LocalizedStringKey(store.state.priceCancelAnytimeText ?? ""))
            .styleGuide(.subheadline)
            .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
            .frame(maxWidth: .infinity)
            .accessibilityLabel(store.state.priceCancelAnytimeAccessibilityLabel ?? "")
    }

    /// The pricing error banner shown when the Premium price cannot be fetched.
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

    /// The self-hosted info banner displayed above the Premium card.
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
        Text(Localizations.youllCompleteThePurchaseWithStripeSecureCheckout)
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

                Text(Localizations.upgradeToPremium)
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
