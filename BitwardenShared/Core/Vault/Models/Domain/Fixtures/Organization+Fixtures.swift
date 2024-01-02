import Foundation

@testable import BitwardenShared

extension Organization {
    static func fixture(
        id: String = "organization-1",
        name: String = ""
    ) -> Organization {
        Organization(
            id: id,
            name: name
        )
    }
}
