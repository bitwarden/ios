import SwiftUI

// MARK: - PasswordVisibilityButton

/// A standard password visibility button. This button changes the icon it displays based on the
/// current password visibility.
///
struct PasswordVisibilityButton: View {
    /// The accessibility label for this button.
    var accessibilityLabel: String

    /// The action that is triggered when the user interacts with this button.
    var action: () -> Void

    /// A flag indicating if the password is currently visible.
    var isPasswordVisible: Bool

    /// The size of the icon displayed in this button.
    var size: CGFloat = 16

    var body: some View {
        Button(action: action) {
            (
                isPasswordVisible
                    ? Asset.Images.hidden.swiftUIImage
                    : Asset.Images.visible.swiftUIImage
            )
            .resizable()
            .frame(width: size, height: size)
        }
    }

    /// Creates a new `PasswordVisibilityButton`.
    ///
    /// - Parameters:
    ///   - accessibilityLabel: The accessibility label for this button. Defaults to
    ///     `Localizations.toggleVisibility`.
    ///   - isPasswordVisible: A flag indicating if the password is visible.
    ///   - size: The size of the icon displayed in this button. Defaults to `16`.
    ///   - action: The action that is triggered when the user interacts with this button.
    ///
    init(
        accessibilityLabel: String = Localizations.toggleVisibility,
        isPasswordVisible: Bool,
        size: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.isPasswordVisible = isPasswordVisible
        self.size = size
    }
}
