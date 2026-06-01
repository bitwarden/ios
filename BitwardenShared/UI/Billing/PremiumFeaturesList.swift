import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - PremiumFeaturesList

/// A reusable view that displays a list of premium features with check icons.
///
struct PremiumFeaturesList: View {
    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()

            ContentBlock {
                featureRow(Localizations.builtInAuthenticator)
                featureRow(Localizations.emergencyAccess)
                featureRow(Localizations.secureFileStorage)
                featureRow(Localizations.breachMonitoring)
            }
        }
    }

    // MARK: Private Methods

    /// A single feature row with a check icon.
    ///
    /// - Parameter text: The feature text to display.
    /// - Returns: A view displaying the feature with a check icon.
    ///
    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            SharedAsset.Icons.checkCircle24.swiftUIImage
                .foregroundColor(Color(asset: SharedAsset.Colors.textInteraction))
                .accessibilityHidden(true)

            Text(text)
                .styleGuide(.headline, weight: .semibold)
                .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    PremiumFeaturesList()
}
#endif
