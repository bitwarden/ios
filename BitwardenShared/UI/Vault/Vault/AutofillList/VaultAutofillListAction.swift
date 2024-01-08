import BitwardenSdk

// MARK: - VaultAutofillListAction

/// Actions that can be processed by a `VaultAutofillListProcessor`.
///
enum VaultAutofillListAction: Equatable {
    /// The cancel button was tapped.
    case cancelTapped

    /// A cipher in the list was tapped
    case cipherTapped(CipherListView)
}
