import BitwardenSdk
import Foundation

extension CipherListView {
    static func fixture(
        id: String? = "1",
        organizationId: String? = nil,
        folderId: String? = nil,
        collectionIds: [String] = [],
        name: String = "Example",
        subTitle: String = "email@example.com",
        type: BitwardenSdk.CipherType = .login,
        favorite: Bool = true,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        edit: Bool = false,
        viewPassword: Bool = true,
        attachments: UInt32 = 0,
        creationDate: Date = Date(),
        deletedDate: Date? = nil,
        revisionDate: Date = Date()
    ) -> CipherListView {
        .init(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            name: name,
            subTitle: subTitle,
            type: type,
            favorite: favorite,
            reprompt: reprompt,
            edit: edit,
            viewPassword: viewPassword,
            attachments: attachments,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate
        )
    }
}
