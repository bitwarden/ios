import BitwardenResources
import SwiftUI

// MARK: - PasswordVisibilityButton

/// A standard password visibility button. This button changes the icon it displays based on the
/// current password visibility.
///
struct PasswordVisibilityButton: View {
    /// The button's accessibility ID.
    var accessibilityIdentifier: String

    /// The accessibility label for this button.
    var accessibilityLabel: String

    /// The action that is triggered when the user interacts with this button.
    var action: () -> Void

    /// A flag indicating if the password is currently visible.
    var isPasswordVisible: Bool

    /// The size of the icon displayed in this button.
    var size: CGFloat = 24

    var body: some View {
        Button(action: action) {
            (
                isPasswordVisible
                    ? Asset.Images.eyeSlash24.swiftUIImage
                    : Asset.Images.eye24.swiftUIImage
            )
            .resizable()
            .frame(width: size, height: size)
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    /// Creates a new `PasswordVisibilityButton`.
    ///
    /// - Parameters:
    ///   - accessibilityIdentifier: The button's accessibility ID.
    ///   - accessibilityLabel: The accessibility label for this button. Defaults to
    ///     `Localizations.toggleVisibility`.
    ///   - isPasswordVisible: A flag indicating if the password is visible.
    ///   - size: The size of the icon displayed in this button. Defaults to `16`.
    ///   - action: The action that is triggered when the user interacts with this button.
    ///
    init(
        accessibilityIdentifier: String = "",
        accessibilityLabel: String = Localizations.toggleVisibility,
        isPasswordVisible: Bool,
        size: CGFloat = 24,
        action: @escaping () -> Void
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.isPasswordVisible = isPasswordVisible
        self.size = size
    }
}
