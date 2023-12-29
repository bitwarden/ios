import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension CollectionView {
    static func fixture(
        externalId: String? = nil,
        hidePassword: Bool = false,
        id: String = "collectionView-1",
        name: String = "",
        organizationId: String = "",
        readOnly: Bool = false
    ) -> CollectionView {
        CollectionView(
            id: id,
            organizationId: organizationId,
            name: name,
            externalId: externalId,
            hidePasswords: hidePassword,
            readOnly: readOnly
        )
    }
}
