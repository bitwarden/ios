import BitwardenSdk

// MARK: - VaultAutofillListState

/// An object that defines the current state of a `VaultAutofillListView`.
///
struct VaultAutofillListState: Equatable {
    // MARK: Properties

    /// The list of matching ciphers that can be used for autofill.
    var ciphersForAutofill: [CipherListView] = []

    /// A toast message to show in the view.
    var toast: Toast?
}
