import BitwardenResources
import BitwardenSdk

extension Fido2CredentialAutofillView {
    /// Returns the username to be used in UI having fallbacks for nil/empty values.
    var safeUsernameForUi: String {
        userNameForUi.fallbackOnWhitespaceOrNil(fallback: Localizations.unknownAccount)
    }
}
