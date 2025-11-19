import SwiftUI

// MARK: - ViewIdentifier

/// String identifiers that allow views to become identifiable by `ViewInspector`.
///
enum ViewIdentifier {
    /// Identifiers used on the `StartRegistrationView`.
    ///
    enum StartRegistration: String, Equatable, Hashable {
        /// An identifier for the terms and privacy toggle.
        case receiveMarketing
    }

    /// Identifiers used on the `CompleteRegistrationView`.
    ///
    enum CompleteRegistration: String, Equatable, Hashable {
        /// An identifier for the check for breaches toggle.
        case checkBreaches
    }
}
