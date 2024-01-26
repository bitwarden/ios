@testable import BitwardenShared

extension Permissions {
    static func fixture(
        accessEventLogs: Bool = false,
        accessImportExport: Bool = false,
        accessReports: Bool = false,
        createNewCollections: Bool = false,
        deleteAnyCollection: Bool = false,
        deleteAssignedCollections: Bool = false,
        editAnyCollection: Bool = false,
        editAssignedCollections: Bool = false,
        manageGroups: Bool = false,
        managePolicies: Bool = false,
        manageResetPassword: Bool = false,
        manageScim: Bool = false,
        manageSso: Bool = false,
        manageUsers: Bool = false
    ) -> Permissions {
        self.init(
            accessEventLogs: accessEventLogs,
            accessImportExport: accessImportExport,
            accessReports: accessReports,
            createNewCollections: createNewCollections,
            deleteAnyCollection: deleteAnyCollection,
            deleteAssignedCollections: deleteAssignedCollections,
            editAnyCollection: editAnyCollection,
            editAssignedCollections: editAssignedCollections,
            manageGroups: manageGroups,
            managePolicies: managePolicies,
            manageResetPassword: manageResetPassword,
            manageScim: manageScim,
            manageSso: manageSso,
            manageUsers: manageUsers
        )
    }
}
