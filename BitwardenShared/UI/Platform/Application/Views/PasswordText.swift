import SwiftUI

// MARK: - PasswordText

/// A view that can display a password using the correct color coding and styling.
struct PasswordText: View {
    // MARK: Properties

    /// The password to display.
    let password: String

    /// A flag indicating if the password is visible or not.
    let isPasswordVisible: Bool

    var body: Text {
        (
            isPasswordVisible
                ? colorCodedText(for: password)
                : Text(String(repeating: "•", count: password.count))
        )
        .font(.styleGuide(.bodyMonospaced))
    }

    // MARK: Private Properties

    /// A color-coded evaulation of the provided string.
    ///
    /// The following foreground color is applied to each character:
    /// - Letters: `textPrimary`
    /// - Numbers: `primaryBitwarden`
    /// - Symbols: `fingerprint`
    ///
    /// - Parameter value: The value to color code.
    /// - Returns: A color-coded `Text` view containing the provided string.
    ///
    @ViewBuilder private func colorCodedText(for value: String) -> Text {
        password.reduce(Text("")) { text, character in
            let foregroundColor: Color = {
                if character.isNumber {
                    return Asset.Colors.primaryBitwarden.swiftUIColor
                } else if character.isSymbol || character.isPunctuation {
                    return Asset.Colors.fingerprint.swiftUIColor
                } else {
                    return Asset.Colors.textPrimary.swiftUIColor
                }
            }()
            let string = "\(character)"
            return text + Text(string).foregroundColor(foregroundColor)
        }
    }
}

#if DEBUG
struct PasswordText_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            PasswordText(
                password: "1234",
                isPasswordVisible: false
            )

            PasswordText(
                password: "Password1234!",
                isPasswordVisible: false
            )

            PasswordText(
                password: "Password1234!",
                isPasswordVisible: true
            )

            PasswordText(
                password: "!@#$%^&*()_+-=.<>,:;\"'?/\\|`~",
                isPasswordVisible: true
            )

            PasswordText(
                password: "1234567890",
                isPasswordVisible: true
            )
        }
    }
}
#endif
