// MARK: - PasswordAutofillEvent

/// A set of events that can be emitted from `PasswordAutoFillProcessor`.
///
enum PasswordAutofillEvent: Equatable {
    /// An event to handle when auth has completed.
    case didCompleteAuth
}
