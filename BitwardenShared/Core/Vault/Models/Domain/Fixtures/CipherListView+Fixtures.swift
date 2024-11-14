import BitwardenSdk
import Foundation

extension CipherListView {
    static func fixture(
        id: String? = "1",
        organizationId: String? = nil,
        folderId: String? = nil,
        collectionIds: [String] = [],
        key: String? = nil,
        name: String = "Example",
        subTitle: String = "email@example.com",
        type: BitwardenSdk.CipherListViewType = .login(LoginListView(hasFido2: false, totp: nil, uris: nil)),
        favorite: Bool = true,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        organizationUseTotp: Bool = false,
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
            key: key,
            name: name,
            subtitle: subTitle,
            type: type,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            viewPassword: viewPassword,
            attachments: attachments,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate
        )
    }
}
