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
        state.toast = Toast(title: Localizations.autofillEnabled)
    }
}
