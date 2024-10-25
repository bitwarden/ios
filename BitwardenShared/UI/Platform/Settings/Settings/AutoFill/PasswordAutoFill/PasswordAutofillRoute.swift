// MARK: - PasswordAutofillRoute

/// A set of routes that can be navigated to from `PasswordAutoFillProcessor`.
///
enum PasswordAutofillRoute: Equatable {
    /// A route that dismisses the current view.
    case dismiss

    /// A route to the password auto-fill screen.
    case passwordAutofill(mode: PasswordAutoFillState.Mode)
}
