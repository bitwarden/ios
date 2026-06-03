import BitwardenSdk
import Foundation

extension CipherView {
    // MARK: Properties

    /// Whether this cipher can be archived.
    var canBeArchived: Bool {
        archivedDate == nil && deletedDate == nil
    }

    /// Whether this cipher can be unarchived.
    var canBeUnarchived: Bool {
        archivedDate != nil && deletedDate == nil
    }

    /// Whether the cipher is normally hidden for flows by being archived or deleted.
    var isHidden: Bool {
        archivedDate != nil || deletedDate != nil
    }

    // MARK: Init

    /// Creates a new login `CipherView` from a username, password, URI, and optional display name.
    ///
    /// - Parameters:
    ///   - username: The username for the login credential.
    ///   - password: The password for the login credential.
    ///   - uri: The URI associated with the credential.
    ///   - name: An optional display name; falls back to the URI's hostname, then the raw URI.
    ///   - creationDate: The creation date for the cipher; defaults to now.
    ///
    init(
        username: String,
        password: String,
        uri: String,
        name: String?,
        creationDate: Date = .now,
    ) {
        self.init(
            id: nil,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: name ?? URL(string: uri)?.host ?? uri,
            notes: nil,
            type: .login,
            login: BitwardenSdk.LoginView(
                username: username,
                password: password,
                passwordRevisionDate: creationDate,
                uris: [LoginUriView(uri: uri, match: nil, uriChecksum: nil)],
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil,
            ),
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
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: creationDate,
            archivedDate: nil,
        )
    }
}
