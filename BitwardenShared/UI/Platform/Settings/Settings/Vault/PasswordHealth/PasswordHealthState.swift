import BitwardenSdk

// MARK: - ReusedPasswordGroup

/// A group of login ciphers that share the same password.
///
struct ReusedPasswordGroup: Equatable, Identifiable {
    /// A stable identifier for the group, derived from the password hash.
    let id: String

    /// The cipher list views that share this password.
    let ciphers: [CipherListView]
}

// MARK: - PasswordHealthState

/// The state used to present the `PasswordHealthView`.
///
struct PasswordHealthState: Equatable {
    /// The loading state of the password health screen.
    var loadingState: LoadingState<[ReusedPasswordGroup]> = .loading(nil)
}
