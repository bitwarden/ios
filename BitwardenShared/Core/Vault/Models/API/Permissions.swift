/// API model for organization permissions.
///
struct Permissions: Codable, Equatable, Hashable {
    // MARK: Properties

    /// Whether the user can access event logs.
    let accessEventLogs: Bool

    /// Whether the user can access import and export.
    let accessImportExport: Bool

    /// Whether the user can access reports.
    let accessReports: Bool

    /// Whether the user can create new collections.
    let createNewCollections: Bool

    /// Whether the user can delete any collection.
    let deleteAnyCollection: Bool

    /// Whether the user can delete assigned collections.
    let deleteAssignedCollections: Bool

    /// Whether the user can edit any collection.
    let editAnyCollection: Bool

    /// Whether the user can edit assigned collections.
    let editAssignedCollections: Bool

    /// Whether the user can manage groups.
    let manageGroups: Bool

    /// Whether the user can manage policies.
    let managePolicies: Bool

    /// Whether the user can manage reset password.
    let manageResetPassword: Bool

    /// Whether the user can manage SCIM.
    let manageScim: Bool

    /// Whether the user can manage SSO.
    let manageSso: Bool

    /// Whether the user can manager users.
    let manageUsers: Bool
}

extension Permissions {
    /// Initialize `Permissions` with default values.
    ///
    init() {
        self.init(
            accessEventLogs: false,
            accessImportExport: false,
            accessReports: false,
            createNewCollections: false,
            deleteAnyCollection: false,
            deleteAssignedCollections: false,
            editAnyCollection: false,
            editAssignedCollections: false,
            manageGroups: false,
            managePolicies: false,
            manageResetPassword: false,
            manageScim: false,
            manageSso: false,
            manageUsers: false
        )
    }
}
