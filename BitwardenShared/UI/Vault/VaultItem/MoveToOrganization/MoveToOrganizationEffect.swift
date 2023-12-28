// MARK: - MoveToOrganizationEffect

/// Effects that can be processed by an `MoveToOrganizationProcessor`.
///
enum MoveToOrganizationEffect {
    /// Any options that need to be loaded for a cipher (e.g. organizations and collections) should
    /// be fetched.
    case fetchCipherOptions
}
