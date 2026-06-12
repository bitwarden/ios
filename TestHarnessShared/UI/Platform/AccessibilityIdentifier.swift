/// Accessibility identifiers for UI automation of the Test Harness app.
enum AccessibilityIdentifier {
    enum CardAutofillForm {
        static let cardholderNameEntry = "CardholderNameEntry"
        static let cardNumberEntry = "CardNumberEntry"
        static let expirationMonthEntry = "ExpirationMonthEntry"
        static let expirationYearEntry = "ExpirationYearEntry"
        static let securityCodeEntry = "SecurityCodeEntry"
    }

    enum FileShare {
        static let shareFileButton = "ShareFileButton"
        static let shareImageButton = "ShareImageButton"
        static let shareTextButton = "ShareTextButton"
        static let textContentEditor = "TextContentEditor"
    }

    enum ScenarioPicker {
        static let loginForm = "ScenarioButton_LoginForm"
        static let cardAutofillForm = "ScenarioButton_CardForm"
        static let fileShare = "ScenarioButton_FileShare"
        static let passkeyAutofill = "ScenarioButton_Passkey"

        static func scenarioButton(_ title: String) -> String {
            switch title {
            case Localizations.simpleLoginForm:
                "ScenarioButton_LoginForm"
            case Localizations.cardAutofillForm:
                "ScenarioButton_CardForm"
            case Localizations.fileShare:
                "ScenarioButton_FileShare"
            case Localizations.passkeyAutofill:
                "ScenarioButton_Passkey"
            default:
                "ScenarioButton_\(title)"
            }
        }
    }

    enum SimpleLoginForm {
        static let passwordEntry = "PasswordEntry"
        static let usernameEntry = "UsernameEntry"
    }
}
