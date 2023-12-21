import Foundation

@testable import BitwardenShared

extension Organization {
    static func fixture(
        id: String = UUID().uuidString,
        name: String = ""
    ) -> Organization {
        Organization(
            id: id,
            name: name
        )
    }
}
