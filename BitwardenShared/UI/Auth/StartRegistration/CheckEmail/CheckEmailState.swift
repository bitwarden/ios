import BitwardenResources
import SwiftUI

// MARK: - CheckEmailState

/// An object that defines the current state of a `CheckEmailView`.
///
struct CheckEmailState: Equatable {
    // MARK: Properties

    /// User's email address.
    var email: String = ""

    // MARK: Computed Properties

    /// Text with user email in bold
    var headelineTextBoldEmail: String {
        Localizations.weSentAnEmailTo("**\(email)**")
    }
}
