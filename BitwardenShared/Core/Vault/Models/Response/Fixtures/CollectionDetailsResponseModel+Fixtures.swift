import Foundation

@testable import BitwardenShared

extension CollectionDetailsResponseModel {
    static func fixture(
        externalId: String? = nil,
        hidePasswords: Bool = false,
        id: String = UUID().uuidString,
        name: String = "",
        organizationId: String = UUID().uuidString,
        readOnly: Bool = false
    ) -> CollectionDetailsResponseModel {
        self.init(
            externalId: externalId,
            hidePasswords: hidePasswords,
            id: id,
            name: name,
            organizationId: organizationId,
            readOnly: readOnly
        )
    }
}
