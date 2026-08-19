import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - PasswordText

/// A view that can display a password using the correct color coding and styling.
struct PasswordText: View {
    // MARK: Properties

    /// The password to display.
    let password: String

    /// A flag indicating if the password is visible or not.
    let isPasswordVisible: Bool

    /// A flag indicating whether VoiceOver should announce the password's characters
    /// individually (e.g. "1 2 3 4" instead of "one thousand two hundred thirty-four") rather
    /// than using its default heuristics for the rendered text.
    var spellOutAccessibilityValue = false

    var body: some View {
        (
            isPasswordVisible
                ? Text(colorCodedText(for: password))
                : Text(String(repeating: "•", count: Constants.hiddenPasswordLength)),
        )
        .styleGuide(.bodyMonospaced)
        .if(spellOutAccessibilityValue && isPasswordVisible) { view in
            view.accessibilityValue(password.spellingOutCharacters())
        }
    }

    // MARK: Private Properties

    /// Returns an `AttributedString` containing a color-coded evaluation of the provided string.
    ///
    /// The following foreground color is applied to each character:
    /// - Letters: `textPrimary`
    /// - Numbers: `textCodeBlue`
    /// - Symbols: `textCodePink`
    ///
    /// - Parameter value: The value to color code.
    /// - Returns: A color-coded `AttributedString` of the provided string.
    ///
    private func colorCodedText(for value: String) -> AttributedString {
        value.reduce(into: AttributedString()) { partialResult, character in
            let foregroundColor: Color = if character.isNumber {
                SharedAsset.Colors.textCodeBlue.swiftUIColor
            } else if character.isSymbol || character.isPunctuation {
                SharedAsset.Colors.textCodePink.swiftUIColor
            } else {
                SharedAsset.Colors.textPrimary.swiftUIColor
            }

            // Add a zero-width space (U+200B) after each character to ensure text will wrap on any
            // character boundary.
            var characterString = AttributedString("\(character)\(String.zeroWidthSpace)")
            characterString.foregroundColor = foregroundColor
            partialResult += characterString
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        PasswordText(
            password: "1234",
            isPasswordVisible: false,
        )

        PasswordText(
            password: "Password1234!",
            isPasswordVisible: false,
        )

        PasswordText(
            password: "Password1234!",
            isPasswordVisible: true,
        )

        PasswordText(
            password: "!@#$%^&*()_+-=.<>,:;\"'?/\\|`~",
            isPasswordVisible: true,
        )

        PasswordText(
            password: "1234567890",
            isPasswordVisible: true,
        )
    }
}
#endif
