import Foundation

/// Actions that can be processed by a `ScenarioPickerProcessor`.
///
enum ScenarioPickerAction: Equatable {
    /// The simple login form test was tapped.
    case simpleLoginFormTapped

    /// The passkey autofill test was tapped.
    case passkeyAutofillTapped

    /// The create passkey test was tapped.
    case createPasskeyTapped
}
