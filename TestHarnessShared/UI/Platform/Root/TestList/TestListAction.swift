import Foundation

/// Actions that can be processed by a `TestListProcessor`.
///
enum TestListAction: Equatable {
    /// The password autofill test was tapped.
    case passwordAutofillTapped

    /// The passkey autofill test was tapped.
    case passkeyAutofillTapped

    /// The create passkey test was tapped.
    case createPasskeyTapped
}
