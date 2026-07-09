import Foundation

/// Effects that can be processed by a `CreateAccountFormProcessor`.
///
enum CreateAccountFormEffect: Equatable {
    /// The user submitted the create account form.
    case createAccount
}
