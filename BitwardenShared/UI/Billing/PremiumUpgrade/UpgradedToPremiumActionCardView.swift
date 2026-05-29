import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - UpgradedToPremiumActionCardView

/// An action card shown after a user completes the premium upgrade flow.
///
struct UpgradedToPremiumActionCardView: View {
    // MARK: Properties

    /// The action to perform when the user taps "Dismiss".
    let onDismiss: () async -> Void

    /// The action to perform when the user taps "Learn more".
    let onLearnMore: () -> Void

    // MARK: View

    var body: some View {
        ActionCard(
            title: Localizations.upgradedToPremium,
            message: Localizations.youNowHaveAccessToAllAdvancedSecurityFeatures,
            actionButtonState: ActionCard.ButtonState(title: Localizations.learnMore) {
                onLearnMore()
            },
            dismissButtonState: ActionCard.ButtonState(title: Localizations.dismiss) {
                await onDismiss()
            },
        ) {
            SharedAsset.Icons.star24.swiftUIImage
                .foregroundStyle(SharedAsset.Colors.iconSecondary.swiftUIColor)
        }
    }
}
