import SwiftUI

// MARK: - PasswordText

/// A view that can display a password using the correct color coding and styling.
struct PasswordText: View {
    // MARK: Properties

    /// The password to display.
    let password: String

    /// A flag indicating if the password is visible or not.
    let isPasswordVisible: Bool

    var body: some View {
        (
            isPasswordVisible
                ? colorCodedText(for: password)
                : Text(String(repeating: "•", count: Constants.hiddenPasswordLength))
        )
        .styleGuide(.bodyMonospaced)
    }

    // MARK: Private Properties

    /// A color-coded evaluation of the provided string.
    ///
    /// The following foreground color is applied to each character:
    /// - Letters: `textPrimary`
    /// - Numbers: `textCodeBlue`
    /// - Symbols: `textCodePink`
    ///
    /// - Parameter value: The value to color code.
    /// - Returns: A color-coded `Text` view containing the provided string.
    ///
    @ViewBuilder
    private func colorCodedText(for value: String) -> Text {
        password.reduce(Text("")) { text, character in
            let foregroundColor: Color = {
                if character.isNumber {
                    return Asset.Colors.textCodeBlue.swiftUIColor
                } else if character.isSymbol || character.isPunctuation {
                    return Asset.Colors.textCodePink.swiftUIColor
                } else {
                    return Asset.Colors.textPrimary.swiftUIColor
                }
            }()
            // Add a zero-width space (U+200B) after each character to ensure text will wrap on any
            // character boundary.
            let string = "\(character)\(String.zeroWidthSpace)"
            return text + Text(string).foregroundColor(foregroundColor)
        }
    }
}

#if DEBUG
#Preview {
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
#endif
