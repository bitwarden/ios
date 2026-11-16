import BitwardenKit
import BitwardenResources

// MARK: - PasswordAutoFillProcessorDelegate

/// A delegate to notify when autofill was successfully enabled from the password autofill screen.
///
protocol PasswordAutoFillProcessorDelegate: AnyObject {
    /// Called when autofill was successfully enabled.
    func didEnableAutofill()
}

extension AutoFillProcessor: PasswordAutoFillProcessorDelegate {
    func didEnableAutofill() {
        // The autofill off action card reflects the live autofill state, so no confirmation is shown.
        guard !state.isAutofillOffActionCardEnabled else { return }
        state.toast = Toast(title: Localizations.autofillEnabled)
    }
}
