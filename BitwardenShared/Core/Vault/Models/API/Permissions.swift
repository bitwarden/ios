/// API model for organization permissions.
///
struct Permissions: Codable, Equatable, Hashable {
    // MARK: Properties

    /// Whether the user can manage policies.
    let managePolicies: Bool

    /// Whether the user can manage reset password.
    let manageResetPassword: Bool
}

extension Permissions {
    /// Initialize `Permissions` with default values.
    ///
    init() {
        self.init(
            managePolicies: false,
            manageResetPassword: false
        )
    }
}
