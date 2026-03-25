import BitwardenKit

// MARK: - PasswordAutoFillAction

/// Actions that can be processed by a `PasswordAutoFillProcessor`.
enum PasswordAutoFillAction: Equatable {
    /// The url has been opened so clear the value in the state.
    case clearURL
}
