import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - PremiumUpgradeBenefitsList

/// A reusable view that displays the list of Premium benefits shown on the Premium upgrade screen.
///
struct PremiumUpgradeBenefitsList: View {
    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefitRow(Localizations.breezeThrough2faWithBuiltInCodes)
            benefitRow(Localizations.runReportsToFindRiskyPasswords)
            benefitRow(Localizations.keepDocumentsSafeAndEncrypted)
            benefitRow(Localizations.addATrustedEmergencyContact)
            benefitRow(Localizations.identifyUnsecureWebsites)
            benefitRow(Localizations.flagAccountsWithInactive2fa)
            benefitRow(Localizations.shareFilesSecurelyWithAnyoneUsingSend)
            benefitRow(Localizations.receive247PrioritySupport)
        }
    }

    // MARK: Private Methods

    /// A single benefit row with a check icon.
    ///
    /// - Parameter text: The benefit text to display.
    /// - Returns: A view displaying the benefit with a check icon.
    ///
    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            SharedAsset.Icons.check16.swiftUIImage
                .foregroundColor(Color(asset: SharedAsset.Colors.textInteraction))
                .accessibilityHidden(true)

            Text(text)
                .styleGuide(.body)
                .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    PremiumUpgradeBenefitsList()
}
#endif
