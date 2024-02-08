import BitwardenSdk

// MARK: - VaultAutofillListEffect

/// Actions that can be processed by a `VaultAutofillListProcessor`.
///
enum VaultAutofillListEffect: Equatable {
    /// A cipher in the list was tapped
    case cipherTapped(CipherView)

    /// Any initial data for the view should be loaded.
    case loadData

    /// A forwarded profile switcher effect.
    case profileSwitcher(ProfileSwitcherEffect)

    /// Searches based on the keyword.
    case search(String)

    /// Stream the autofill items for the user.
    case streamAutofillItems
}
