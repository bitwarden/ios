import Foundation

/// Actions that can be processed by a `CreateAccountFormProcessor`.
///
enum CreateAccountFormAction: Equatable {
    /// The confirm password field was updated.
    case confirmPasswordChanged(String)

    /// The email field was updated.
    case emailChanged(String)

    /// The password field was updated.
    case passwordChanged(String)
}
