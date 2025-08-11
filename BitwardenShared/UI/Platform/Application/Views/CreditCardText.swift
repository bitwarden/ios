import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - CreditCardText

/// A view that can display a credit card number with proper formatting and styling.
/// When visible, the card number is displayed in groups of 4 digits separated by spaces.
/// When hidden, it displays bullet characters like the standard PasswordText component.
struct CreditCardText: View {
    // MARK: Properties

    /// The credit card number to display.
    let cardNumber: String

    /// A flag indicating if the card number is visible or not.
    let isCardNumberVisible: Bool

    var body: some View {
        (
            isCardNumberVisible
                ? Text(colorCodedText(for: cardNumber.formattedCreditCardNumber()))
                : Text(String(repeating: "•", count: Constants.hiddenPasswordLength))
        )
        .styleGuide(.bodyMonospaced)
    }

    // MARK: Private Properties

    /// Returns an `AttributedString` containing a color-coded evaluation of the provided string.
    ///
    /// The following foreground color is applied to each character:
    /// - Numbers: `textCodeBlue`
    /// - Spaces: `textPrimary`
    /// - Other characters: `textPrimary`
    ///
    /// - Parameter value: The value to color code.
    /// - Returns: A color-coded `AttributedString` of the provided string.
    ///
    private func colorCodedText(for value: String) -> AttributedString {
        value.reduce(into: AttributedString()) { partialResult, character in
            let foregroundColor: Color = if character.isNumber {
                SharedAsset.Colors.textCodeBlue.swiftUIColor
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
        CreditCardText(
            cardNumber: "1234567890123456",
            isCardNumberVisible: false
        )

        CreditCardText(
            cardNumber: "1234567890123456",
            isCardNumberVisible: true
        )

        CreditCardText(
            cardNumber: "4400123456789",
            isCardNumberVisible: true
        )

        CreditCardText(
            cardNumber: "378282246310005",
            isCardNumberVisible: true
        )
    }
    .padding()
}
#endif