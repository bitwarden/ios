import Foundation

@testable import BitwardenShared

extension CollectionDetailsResponseModel {
    static func fixture(
        externalId: String? = nil,
        hidePasswords: Bool = false,
        id: String = UUID().uuidString,
        manage: Bool? = false,
        name: String = "",
        organizationId: String = UUID().uuidString,
        readOnly: Bool = false,
        defaultUserCollectionEmail: String? = nil,
        type: CollectionType = .sharedCollection,
    ) -> CollectionDetailsResponseModel {
        self.init(
            defaultUserCollectionEmail: defaultUserCollectionEmail,
            externalId: externalId,
            hidePasswords: hidePasswords,
            id: id,
            manage: manage,
            name: name,
            organizationId: organizationId,
            readOnly: readOnly,
            type: type,
        )
    }
}
