// MARK: - PasswordHealthEffect

/// Effects that can be processed by a `PasswordHealthProcessor`.
///
enum PasswordHealthEffect: Equatable {
    /// Load the password health data from the vault.
    case loadData
}
