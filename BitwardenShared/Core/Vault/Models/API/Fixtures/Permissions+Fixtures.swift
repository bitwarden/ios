@testable import BitwardenShared

extension Permissions {
    static func fixture(
        managePolicies: Bool = false,
        manageResetPassword: Bool = false
    ) -> Permissions {
        self.init(
            managePolicies: managePolicies,
            manageResetPassword: manageResetPassword
        )
    }
}
