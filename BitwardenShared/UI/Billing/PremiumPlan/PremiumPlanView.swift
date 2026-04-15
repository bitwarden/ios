import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - PremiumPlanView

/// A view that displays the user's premium plan details and billing information.
///
struct PremiumPlanView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<PremiumPlanState, PremiumPlanAction, PremiumPlanEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            planContentBlock

            managePlanButton

            if store.state.showCancelButton {
                cancelPremiumButton
            }
        }
        .scrollView()
        .navigationBar(title: Localizations.plan, titleDisplayMode: .inline)
        .task {
            await store.perform(.appeared)
        }
        .onChange(of: store.state.urlToOpen) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearUrl)
        }
    }

    // MARK: Private Views

    /// The billing details section with rows for billing amount, storage cost, and discount.
    private var billingSection: some View {
        VStack(spacing: 0) {
            billingRow(
                label: Localizations.billingAmount,
                value: store.state.billingAmount,
                valueColor: Color(asset: SharedAsset.Colors.textPrimary),
            )
            Divider()
            billingRow(
                label: Localizations.storageCost,
                value: store.state.storageCost,
                valueColor: Color(asset: SharedAsset.Colors.textPrimary),
            )
            Divider()
            billingRow(
                label: Localizations.discount,
                value: store.state.discount,
                valueColor: SharedAsset.Colors.statusStrong.swiftUIColor,
            )
        }
    }

    /// The cancel premium button.
    private var cancelPremiumButton: some View {
        Button {
            store.send(.cancelPremiumTapped)
        } label: {
            HStack(spacing: 8) {
                Image(asset: SharedAsset.Icons.externalLink24)
                Text(Localizations.cancelPremium)
            }
        }
        .buttonStyle(.secondary())
        .accessibilityIdentifier("CancelPremiumButton")
    }

    /// The description text with inline bold formatting via markdown.
    private var descriptionText: some View {
        Text(LocalizedStringKey(store.state.descriptionText))
            .styleGuide(.callout)
            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
    }

    /// The header section with title, badge, and description.
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(Localizations.premium)
                    .styleGuide(
                        .title,
                        weight: .bold,
                    )

                PillBadgeView(
                    text: store.state.planStatus.label,
                    style: store.state.planStatus.badgeStyle,
                )
            }

            descriptionText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The manage plan button.
    private var managePlanButton: some View {
        Button {
            store.send(.managePlanTapped)
        } label: {
            HStack(spacing: 8) {
                Image(asset: SharedAsset.Icons.externalLink24)
                Text(Localizations.managePlan)
            }
        }
        .buttonStyle(.primary())
        .accessibilityIdentifier("ManagePlanButton")
    }

    /// The content block containing the header and billing details.
    private var planContentBlock: some View {
        ContentBlock {
            headerSection
                .padding(16)

            if store.state.showBillingDetails {
                billingSection
                    .padding(.horizontal, 16)
            }

            if store.state.planStatus == .canceled {
                PremiumFeaturesList()
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: Private Methods

    /// A single billing row with a label on the left and a value on the right.
    ///
    /// - Parameters:
    ///   - label: The label text displayed on the left.
    ///   - value: The value text displayed on the right.
    ///   - valueColor: The color to use for the value text.
    ///
    private func billingRow(
        label: String,
        value: String,
        valueColor: Color,
    ) -> some View {
        HStack {
            Text(label)
                .styleGuide(.body)
                .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))

            Spacer()

            Text(value)
                .styleGuide(.body)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Active") {
    NavigationView {
        PremiumPlanView(
            store: Store(
                processor: StateProcessor(
                    state: PremiumPlanState(
                        billingAmount: "$1.65 / month",
                        discount: "-$0.10",
                        planStatus: .active,
                        storageCost: "$0.35",
                    ),
                ),
            ),
        )
    }
}

#Preview("Update Payment") {
    NavigationView {
        PremiumPlanView(
            store: Store(
                processor: StateProcessor(
                    state: PremiumPlanState(
                        billingAmount: "$1.65 / month",
                        discount: "-$0.10",
                        planStatus: .updatePayment,
                        storageCost: "$0.35",
                    ),
                ),
            ),
        )
    }
}

#Preview("Past Due") {
    NavigationView {
        PremiumPlanView(
            store: Store(
                processor: StateProcessor(
                    state: PremiumPlanState(
                        billingAmount: "$1.65 / month",
                        discount: "-$0.10",
                        planStatus: .pastDue,
                        storageCost: "$0.35",
                    ),
                ),
            ),
        )
    }
}

#Preview("Canceled") {
    NavigationView {
        PremiumPlanView(
            store: Store(
                processor: StateProcessor(
                    state: PremiumPlanState(
                        planStatus: .canceled,
                    ),
                ),
            ),
        )
    }
}
#endif
