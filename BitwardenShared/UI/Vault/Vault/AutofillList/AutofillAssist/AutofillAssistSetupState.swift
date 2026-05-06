import BitwardenKit
import Foundation

// MARK: - AutofillAssistSetupState

/// State for the Autofill Assist setup screen.
///
struct AutofillAssistSetupState: Equatable {
    // MARK: Properties

    /// The selectable page fields.
    let pageFields: [AutofillAssistFieldOption]

    /// The selected opId for the password field mapping.
    var passwordFieldOpId: String?

    /// A toast message to show in the view.
    var toast: Toast?

    /// The URL entered by the user.
    var url: String

    /// The selected opId for the username field mapping.
    var usernameFieldOpId: String?

    // MARK: Computed Properties

    /// Whether the Save button should be enabled.
    var isSaveEnabled: Bool {
        !url.isEmpty
            && URL(string: url)?.host != nil
            && usernameFieldOpId != nil
            && passwordFieldOpId != nil
    }
}

// MARK: - AutofillAssistSetupAction

/// Actions for the Autofill Assist setup screen.
///
enum AutofillAssistSetupAction: Equatable {
    /// The Cancel button was tapped.
    case cancelTapped

    /// The password field selection changed.
    case passwordFieldChanged(String?)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The URL field changed.
    case urlChanged(String)

    /// The username field selection changed.
    case usernameFieldChanged(String?)
}

// MARK: - AutofillAssistSetupEffect

/// Async effects for the Autofill Assist setup screen.
///
enum AutofillAssistSetupEffect: Equatable {
    /// The Save button was tapped.
    case saveTapped
}
