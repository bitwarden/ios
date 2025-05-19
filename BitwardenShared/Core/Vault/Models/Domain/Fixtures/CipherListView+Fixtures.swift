import BitwardenSdk
import Foundation

extension CipherListView {
    static func fixture(
        id: String? = "1",
        organizationId: String? = nil,
        folderId: String? = nil,
        collectionIds: [String] = [],
        key: String? = nil,
        name: String = "Bitwarden",
        subtitle: String = "",
        type: BitwardenSdk.CipherListViewType = .login(.fixture()),
        favorite: Bool = false,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        organizationUseTotp: Bool = false,
        edit: Bool = true,
        permissions: BitwardenSdk.CipherPermissions? = nil,
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
            subtitle: subtitle,
            type: type,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            permissions: permissions,
            viewPassword: viewPassword,
            attachments: attachments,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate
        )
    }

    static func fixture(
        id: String? = "1",
        organizationId: String? = nil,
        folderId: String? = nil,
        collectionIds: [String] = [],
        key: String? = nil,
        login: LoginListView,
        name: String = "Example",
        subtitle: String = "",
        favorite: Bool = false,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        organizationUseTotp: Bool = false,
        edit: Bool = true,
        permissions: BitwardenSdk.CipherPermissions? = nil,
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
            subtitle: subtitle,
            type: .login(login),
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            permissions: permissions,
            viewPassword: viewPassword,
            attachments: attachments,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate
        )
    }
}
