import BitwardenSdk
import Foundation

@testable import BitwardenShared

extension CollectionView {
    static func fixture(
        externalId: String? = nil,
        hidePassword: Bool = false,
        id: String = UUID().uuidString,
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
