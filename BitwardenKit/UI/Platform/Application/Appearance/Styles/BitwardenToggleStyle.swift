import BitwardenResources
import SwiftUI

// MARK: - BitwardenToggleStyle

/// A tinted toggle style.
///
public struct BitwardenToggleStyle: ToggleStyle {
    /// A value indicating whether the toggle is currently enabled or disabled.
    @Environment(\.isEnabled) var isEnabled

    public func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .bitwardenToggleLabelStyle(isEnabled: isEnabled)
            .tint(SharedAsset.Colors.iconSecondary.swiftUIColor)
    }
}

// MARK: ToggleStyle

public extension ToggleStyle where Self == BitwardenToggleStyle {
    /// The style for toggles used in this application.
    static var bitwarden: BitwardenToggleStyle { BitwardenToggleStyle() }
}

// MARK: - View

extension View {
    /// Applies the label styling used by `BitwardenToggleStyle`, so toggle titles remain visually
    /// consistent whether they're rendered through a `Toggle`'s label or as standalone content.
    ///
    /// - Parameter isEnabled: Whether the toggle is currently enabled.
    /// - Returns: The view styled to match `BitwardenToggleStyle`.
    func bitwardenToggleLabelStyle(isEnabled: Bool) -> some View {
        styleGuide(.body)
            .foregroundColor(
                isEnabled
                    ? SharedAsset.Colors.textPrimary.swiftUIColor
                    : SharedAsset.Colors.buttonFilledDisabledForeground.swiftUIColor,
            )
    }
}
