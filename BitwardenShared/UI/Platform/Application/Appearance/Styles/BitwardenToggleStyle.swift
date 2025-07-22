import BitwardenResources
import SwiftUI

// MARK: - BitwardenToggleStyle

/// A tinted toggle style.
///
struct BitwardenToggleStyle: ToggleStyle {
    /// A value indicating whether the toggle is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .styleGuide(.body)
            .foregroundColor(
                isEnabled
                    ? SharedAsset.Colors.textPrimary.swiftUIColor
                    : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor
            )
            .tint(SharedAsset.Colors.iconSecondary.swiftUIColor)
    }
}

// MARK: ToggleStyle

extension ToggleStyle where Self == BitwardenToggleStyle {
    /// The style for toggles used in this application.
    static var bitwarden: BitwardenToggleStyle { BitwardenToggleStyle() }
}
