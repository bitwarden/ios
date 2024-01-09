import BitwardenSdk

// MARK: - VaultAutofillListEffect

/// Actions that can be processed by a `VaultAutofillListProcessor`.
///
enum VaultAutofillListEffect: Equatable {
    /// A cipher in the list was tapped
    case cipherTapped(CipherListView)

    /// Stream the autofill items for the user.
    case streamAutofillItems
}
