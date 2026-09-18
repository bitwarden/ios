import BitwardenSdk
import Foundation

extension CipherView {
    static func fixture(
        id: CipherId? = nil,
        login: LoginView? = .fixture(),
        name: String = "Example",
    ) -> CipherView {
        CipherView(
            id: id,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: name,
            notes: nil,
            type: .login,
            login: login,
            identity: nil,
            card: nil,
            secureNote: nil,
            sshKey: nil,
            bankAccount: nil,
            driversLicense: nil,
            passport: nil,
            favorite: false,
            reprompt: .none,
            organizationUseTotp: false,
            edit: true,
            permissions: nil,
            viewPassword: true,
            localData: nil,
            attachments: nil,
            attachmentDecryptionFailures: nil,
            fields: nil,
            passwordHistory: nil,
            creationDate: Date(timeIntervalSince1970: 0),
            deletedDate: nil,
            revisionDate: Date(timeIntervalSince1970: 0),
            archivedDate: nil,
        )
    }
}

extension LoginView {
    static func fixture(
        fido2Credentials: [Fido2Credential]? = nil,
        username: String? = "user@example.com",
    ) -> LoginView {
        LoginView(
            username: username,
            password: nil,
            passwordRevisionDate: nil,
            uris: nil,
            totp: nil,
            autofillOnPageLoad: nil,
            fido2Credentials: fido2Credentials,
        )
    }
}
