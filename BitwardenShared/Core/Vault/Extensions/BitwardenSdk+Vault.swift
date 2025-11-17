// swiftlint:disable:this file_name
// swiftlint:disable file_length

import BitwardenKit
import BitwardenResources
import BitwardenSdk

// MARK: - DataMappingError

/// Errors thrown from converting between SDK and app types.
///
enum DataMappingError: Error {
    /// Thrown if an object was unable to be constructed because the data was invalid.
    case invalidData

    /// Thrown if a required object identifier is nil.
    case missingId
}

// MARK: - Ciphers

extension AttachmentRequestModel {
    init(attachment: BitwardenSdk.Attachment) {
        self.init(
            fileName: attachment.fileName,
            key: attachment.key,
            size: attachment.size,
        )
    }
}

extension AttachmentResponseModel {
    init(attachment: BitwardenSdk.Attachment) {
        self.init(
            fileName: attachment.fileName,
            id: attachment.id,
            key: attachment.key,
            size: attachment.size,
            sizeName: attachment.sizeName,
            url: attachment.url,
        )
    }
}

extension AttachmentView: @retroactive Identifiable {}

extension CipherCardModel {
    init(card: BitwardenSdk.Card) {
        self.init(
            brand: card.brand,
            cardholderName: card.cardholderName,
            code: card.code,
            expMonth: card.expMonth,
            expYear: card.expYear,
            number: card.number,
        )
    }
}

extension CipherDetailsResponseModel {
    init(cipher: BitwardenSdk.Cipher) throws {
        guard let id = cipher.id else { throw DataMappingError.invalidData }
        self.init(
            archivedDate: cipher.archivedDate,
            attachments: cipher.attachments?.map(AttachmentResponseModel.init),
            card: cipher.card.map(CipherCardModel.init),
            collectionIds: cipher.collectionIds,
            creationDate: cipher.creationDate,
            deletedDate: cipher.deletedDate,
            edit: cipher.edit,
            favorite: cipher.favorite,
            fields: cipher.fields?.map(CipherFieldModel.init),
            folderId: cipher.folderId,
            id: id,
            identity: cipher.identity.map(CipherIdentityModel.init),
            key: cipher.key,
            login: cipher.login.map(CipherLoginModel.init),
            name: cipher.name,
            notes: cipher.notes,
            organizationId: cipher.organizationId,
            organizationUseTotp: cipher.organizationUseTotp,
            passwordHistory: cipher.passwordHistory?.map(CipherPasswordHistoryModel.init),
            permissions: CipherPermissionsModel(cipherPermissions: cipher.permissions),
            reprompt: BitwardenShared.CipherRepromptType(type: cipher.reprompt),
            revisionDate: cipher.revisionDate,
            secureNote: cipher.secureNote.map(CipherSecureNoteModel.init),
            sshKey: cipher.sshKey.map(CipherSSHKeyModel.init),
            type: BitwardenShared.CipherType(type: cipher.type),
            viewPassword: cipher.viewPassword,
        )
    }
}

extension CipherFieldModel {
    init(field: BitwardenSdk.Field) {
        self.init(
            linkedId: field.linkedId.flatMap(LinkedIdType.init),
            name: field.name,
            type: FieldType(fieldType: field.type),
            value: field.value,
        )
    }
}

extension CipherIdentityModel {
    init(identity: BitwardenSdk.Identity) {
        self.init(
            address1: identity.address1,
            address2: identity.address2,
            address3: identity.address3,
            city: identity.city,
            company: identity.company,
            country: identity.country,
            email: identity.email,
            firstName: identity.firstName,
            lastName: identity.lastName,
            licenseNumber: identity.licenseNumber,
            middleName: identity.middleName,
            passportNumber: identity.passportNumber,
            phone: identity.phone,
            postalCode: identity.postalCode,
            ssn: identity.ssn,
            state: identity.state,
            title: identity.title,
            username: identity.username,
        )
    }
}

extension CipherLoginFido2Credential {
    init(fido2Credential credential: Fido2Credential) {
        self.init(
            counter: credential.counter,
            creationDate: credential.creationDate,
            credentialId: credential.credentialId,
            discoverable: credential.discoverable,
            keyAlgorithm: credential.keyAlgorithm,
            keyCurve: credential.keyCurve,
            keyType: credential.keyType,
            keyValue: credential.keyValue,
            rpId: credential.rpId,
            rpName: credential.rpName,
            userDisplayName: credential.userDisplayName,
            userHandle: credential.userHandle,
            userName: credential.userName,
        )
    }
}

extension CipherLoginModel {
    init(login: BitwardenSdk.Login) {
        self.init(
            autofillOnPageLoad: login.autofillOnPageLoad,
            fido2Credentials: login.fido2Credentials?.map(CipherLoginFido2Credential.init),
            password: login.password,
            passwordRevisionDate: login.passwordRevisionDate,
            totp: login.totp,
            uris: login.uris?.map(CipherLoginUriModel.init),
            username: login.username,
        )
    }
}

extension CipherLoginUriModel {
    init(loginUri: BitwardenSdk.LoginUri) {
        self.init(
            match: loginUri.match.map(UriMatchType.init),
            uri: loginUri.uri,
            uriChecksum: loginUri.uriChecksum,
        )
    }
}

extension CipherPasswordHistoryModel {
    init(passwordHistory: BitwardenSdk.PasswordHistory) {
        self.init(
            lastUsedDate: passwordHistory.lastUsedDate,
            password: passwordHistory.password,
        )
    }
}

extension CipherPermissionsModel {
    init?(cipherPermissions: BitwardenSdk.CipherPermissions?) {
        guard let cipherPermissions else {
            return nil
        }
        self.init(delete: cipherPermissions.delete, restore: cipherPermissions.restore)
    }
}

extension CipherRepromptType {
    init(type: BitwardenSdk.CipherRepromptType) {
        switch type {
        case .none:
            self = .none
        case .password:
            self = .password
        }
    }
}

extension CipherSecureNoteModel {
    init(secureNote: BitwardenSdk.SecureNote) {
        self.init(type: SecureNoteType(type: secureNote.type))
    }
}

extension CipherSSHKeyModel {
    init(sshKey: BitwardenSdk.SshKey) {
        self.init(
            keyFingerprint: sshKey.fingerprint,
            privateKey: sshKey.privateKey,
            publicKey: sshKey.publicKey,
        )
    }
}

extension CipherType {
    init(type: BitwardenSdk.CipherType) {
        switch type {
        case .card:
            self = .card
        case .identity:
            self = .identity
        case .login:
            self = .login
        case .secureNote:
            self = .secureNote
        case .sshKey:
            self = .sshKey
        }
    }

    init(_ type: BitwardenSdk.CipherListViewType) {
        switch type {
        case .card:
            self = .card
        case .identity:
            self = .identity
        case .login:
            self = .login
        case .secureNote:
            self = .secureNote
        case .sshKey:
            self = .sshKey
        }
    }
}

extension FieldType {
    init(fieldType: BitwardenSdk.FieldType) {
        switch fieldType {
        case .boolean:
            self = .boolean
        case .hidden:
            self = .hidden
        case .linked:
            self = .linked
        case .text:
            self = .text
        }
    }
}

extension SecureNoteType {
    init(type: BitwardenSdk.SecureNoteType) {
        switch type {
        case .generic:
            self = .generic
        }
    }
}

extension UriMatchType {
    init(match: BitwardenSdk.UriMatchType) {
        switch match {
        case .domain:
            self = .domain
        case .host:
            self = .host
        case .startsWith:
            self = .startsWith
        case .exact:
            self = .exact
        case .regularExpression:
            self = .regularExpression
        case .never:
            self = .never
        }
    }
}

// MARK: - Ciphers (BitwardenSdk)

extension BitwardenSdk.Attachment {
    init(responseModel model: AttachmentResponseModel) {
        self.init(
            id: model.id,
            url: model.url,
            size: model.size,
            sizeName: model.sizeName,
            fileName: model.fileName,
            key: model.key,
        )
    }
}

extension BitwardenSdk.Card {
    init(cipherCardModel model: CipherCardModel) {
        self.init(
            cardholderName: model.cardholderName,
            expMonth: model.expMonth,
            expYear: model.expYear,
            code: model.code,
            brand: model.brand,
            number: model.number,
        )
    }
}

extension BitwardenSdk.Cipher {
    init(cipherData: CipherData) throws {
        guard let model = cipherData.model else {
            throw DataMappingError.invalidData
        }
        self.init(responseModel: model)
    }

    init(responseModel model: CipherDetailsResponseModel) {
        self.init(
            id: model.id,
            organizationId: model.organizationId,
            folderId: model.folderId,
            collectionIds: model.collectionIds ?? [],
            key: model.key,
            name: model.name,
            notes: model.notes,
            type: BitwardenSdk.CipherType(model.type),
            login: model.login.map(Login.init),
            identity: model.identity.map(Identity.init),
            card: model.card.map(Card.init),
            secureNote: model.secureNote.map(SecureNote.init),
            sshKey: model.sshKey.map(SshKey.init),
            favorite: model.favorite,
            reprompt: BitwardenSdk.CipherRepromptType(model.reprompt),
            organizationUseTotp: model.organizationUseTotp,
            edit: model.edit,
            permissions: model.permissions.map(CipherPermissions.init),
            viewPassword: model.viewPassword,
            localData: nil,
            attachments: model.attachments?.map(Attachment.init),
            fields: model.fields?.map(Field.init),
            passwordHistory: model.passwordHistory?.map(PasswordHistory.init),
            creationDate: model.creationDate,
            deletedDate: model.deletedDate,
            revisionDate: model.revisionDate,
            archivedDate: model.archivedDate,
            data: nil,
        )
    }
}

extension BitwardenSdk.CipherListView: @retroactive Identifiable, Fido2UserVerifiableCipherView {}

extension BitwardenSdk.CipherListViewType {
    /// Whether the type is card.
    var isCard: Bool {
        switch self {
        case .card:
            true
        default:
            false
        }
    }

    /// Whether the type is login.
    var isLogin: Bool {
        switch self {
        case .login:
            true
        default:
            false
        }
    }

    /// The `LoginListView` if this type is a `.login`, otherwise `nil`.
    var loginListView: BitwardenSdk.LoginListView? {
        guard case let .login(loginListView) = self else {
            return nil
        }
        return loginListView
    }
}

extension BitwardenSdk.CipherView: @retroactive Identifiable, Fido2UserVerifiableCipherView {
    /// Initializes a new `CipherView` based on a `Fido2CredentialNewView`
    /// - Parameters:
    ///   - fido2CredentialNewView: The `Fido2CredentialNewView` for the Fido2 creation flow
    ///   - timeProvider: The time provider.
    init(fido2CredentialNewView: Fido2CredentialNewView, timeProvider: TimeProvider) {
        self = CipherView(
            id: nil,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: fido2CredentialNewView.rpName ?? fido2CredentialNewView.rpId,
            notes: nil,
            type: .login,
            login: BitwardenSdk.LoginView(
                username: fido2CredentialNewView.userName ?? "",
                password: nil,
                passwordRevisionDate: nil,
                uris: [
                    LoginUriView(uri: fido2CredentialNewView.rpId, match: nil, uriChecksum: nil),
                ],
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: nil,
            ),
            identity: nil,
            card: nil,
            secureNote: nil,
            sshKey: nil,
            favorite: false,
            reprompt: .none,
            organizationUseTotp: false,
            edit: false,
            permissions: nil,
            viewPassword: true,
            localData: nil,
            attachments: nil,
            fields: nil,
            passwordHistory: nil,
            creationDate: timeProvider.presentTime,
            deletedDate: nil,
            revisionDate: timeProvider.presentTime,
            archivedDate: nil,
        )
    }
}

extension BitwardenSdk.CipherType {
    init(_ cipherType: CipherType) {
        switch cipherType {
        case .login:
            self = .login
        case .secureNote:
            self = .secureNote
        case .card:
            self = .card
        case .identity:
            self = .identity
        case .sshKey:
            self = .sshKey
        }
    }
}

extension BitwardenSdk.CipherRepromptType {
    init(_ cipherRepromptType: CipherRepromptType) {
        switch cipherRepromptType {
        case .none:
            self = .none
        case .password:
            self = .password
        }
    }
}

extension BitwardenSdk.Fido2Credential: @retroactive Identifiable, @unchecked @retroactive Sendable {
    public var id: String { credentialId }

    init(cipherLoginFido2Credential model: CipherLoginFido2Credential) {
        self.init(
            credentialId: model.credentialId,
            keyType: model.keyType,
            keyAlgorithm: model.keyAlgorithm,
            keyCurve: model.keyCurve,
            keyValue: model.keyValue,
            rpId: model.rpId,
            userHandle: model.userHandle,
            userName: model.userName,
            counter: model.counter,
            rpName: model.rpName,
            userDisplayName: model.userDisplayName,
            discoverable: model.discoverable,
            creationDate: model.creationDate,
        )
    }
}

extension BitwardenSdk.Fido2CredentialView: @unchecked @retroactive Sendable {}

extension BitwardenSdk.Fido2CredentialAutofillView: @unchecked @retroactive Sendable {}

extension BitwardenSdk.Field {
    init(cipherFieldModel model: CipherFieldModel) {
        self.init(
            name: model.name,
            value: model.value,
            type: BitwardenSdk.FieldType(fieldType: model.type),
            linkedId: model.linkedId?.rawValue,
        )
    }
}

extension BitwardenSdk.FieldType {
    init(fieldType: FieldType) {
        switch fieldType {
        case .boolean:
            self = .boolean
        case .hidden:
            self = .hidden
        case .linked:
            self = .linked
        case .text:
            self = .text
        }
    }
}

extension BitwardenSdk.Identity {
    init(cipherIdentityModel model: CipherIdentityModel) {
        self.init(
            title: model.title,
            firstName: model.firstName,
            middleName: model.middleName,
            lastName: model.lastName,
            address1: model.address1,
            address2: model.address2,
            address3: model.address3,
            city: model.city,
            state: model.state,
            postalCode: model.postalCode,
            country: model.country,
            company: model.company,
            email: model.email,
            phone: model.phone,
            ssn: model.ssn,
            username: model.username,
            passportNumber: model.passportNumber,
            licenseNumber: model.licenseNumber,
        )
    }
}

extension BitwardenSdk.Login {
    init(cipherLoginModel model: CipherLoginModel) {
        self.init(
            username: model.username,
            password: model.password,
            passwordRevisionDate: model.passwordRevisionDate,
            uris: model.uris?.map(LoginUri.init),
            totp: model.totp,
            autofillOnPageLoad: model.autofillOnPageLoad,
            fido2Credentials: model.fido2Credentials?.map(Fido2Credential.init),
        )
    }
}

extension BitwardenSdk.LoginUri {
    init(cipherLoginUriModel model: CipherLoginUriModel) {
        self.init(
            uri: model.uri,
            match: model.match.map(BitwardenSdk.UriMatchType.init),
            uriChecksum: model.uriChecksum,
        )
    }
}

extension BitwardenSdk.LoginListView: CipherDecorativeIconDataView {}

extension BitwardenSdk.LoginView: CipherDecorativeIconDataView {}

extension BitwardenSdk.PasswordHistory {
    init(cipherPasswordHistoryModel model: CipherPasswordHistoryModel) {
        self.init(
            password: model.password,
            lastUsedDate: model.lastUsedDate,
        )
    }

    init(passwordHistoryData: PasswordHistoryData) throws {
        guard let password = passwordHistoryData.password,
              let lastUsedDate = passwordHistoryData.lastUsedDate else {
            throw DataMappingError.invalidData
        }
        self.init(
            password: password,
            lastUsedDate: lastUsedDate,
        )
    }
}

extension BitwardenSdk.CipherPermissions {
    init(cipherPermissionsModel model: CipherPermissionsModel) {
        self.init(delete: model.delete, restore: model.restore)
    }
}

extension BitwardenSdk.SecureNote {
    init(cipherSecureNoteModel model: CipherSecureNoteModel) {
        self.init(type: BitwardenSdk.SecureNoteType(type: model.type))
    }
}

extension BitwardenSdk.SecureNoteType {
    init(type: SecureNoteType) {
        switch type {
        case .generic:
            self = .generic
        }
    }
}

extension BitwardenSdk.SshKey {
    init(sshKeyModel model: CipherSSHKeyModel) {
        self.init(
            privateKey: model.privateKey,
            publicKey: model.publicKey,
            fingerprint: model.keyFingerprint,
        )
    }
}

extension BitwardenSdk.UriMatchType {
    init(type: UriMatchType) {
        switch type {
        case .domain:
            self = .domain
        case .exact:
            self = .exact
        case .host:
            self = .host
        case .never:
            self = .never
        case .regularExpression:
            self = .regularExpression
        case .startsWith:
            self = .startsWith
        }
    }
}

// MARK: Collections

extension CollectionDetailsResponseModel {
    init(collection: Collection) throws {
        guard let id = collection.id else { throw DataMappingError.missingId }
        self.init(
            defaultUserCollectionEmail: collection.defaultUserCollectionEmail,
            externalId: collection.externalId,
            hidePasswords: collection.hidePasswords,
            id: id,
            manage: collection.manage,
            name: collection.name,
            organizationId: collection.organizationId,
            readOnly: collection.readOnly,
            type: BitwardenShared.CollectionType(type: collection.type),
        )
    }
}

extension CollectionType {
    init(type: BitwardenSdk.CollectionType) {
        switch type {
        case .sharedCollection:
            self = .sharedCollection
        case .defaultUserCollection:
            self = .defaultUserCollection
        }
    }
}

// MARK: Collections (BitwardenSdk)

extension BitwardenSdk.Collection {
    init(collectionData: CollectionData) throws {
        guard let model = collectionData.model else {
            throw DataMappingError.invalidData
        }
        self.init(collectionDetailsResponseModel: model)
    }

    init(collectionDetailsResponseModel model: CollectionDetailsResponseModel) {
        self.init(
            id: model.id,
            organizationId: model.organizationId,
            name: model.name,
            externalId: model.externalId,
            hidePasswords: model.hidePasswords,
            readOnly: model.readOnly,
            manage: model.manage ?? !model.readOnly,
            defaultUserCollectionEmail: model.defaultUserCollectionEmail,
            type: BitwardenSdk.CollectionType(type: model.type),
        )
    }
}

extension BitwardenSdk.CollectionType {
    init(type: CollectionType) {
        switch type {
        case .sharedCollection:
            self = .sharedCollection
        case .defaultUserCollection:
            self = .defaultUserCollection
        }
    }
}

extension BitwardenSdk.CollectionView: @unchecked @retroactive Sendable, @retroactive Identifiable, TreeNodeModel {}

// MARK: - Folders (BitwardenSdk)

extension BitwardenSdk.Folder {
    init(folderResponseModel model: FolderResponseModel) {
        self.init(
            id: model.id,
            name: model.name,
            revisionDate: model.revisionDate,
        )
    }

    init(folderData: FolderData) throws {
        guard let id = folderData.id,
              let name = folderData.model?.name,
              let revisionDate = folderData.model?.revisionDate else {
            throw DataMappingError.invalidData
        }
        self.init(
            id: id,
            name: name,
            revisionDate: revisionDate,
        )
    }
}

extension BitwardenSdk.FolderView: Menuable, @unchecked @retroactive Sendable, TreeNodeModel {
    public static var defaultValueLocalizedName: String {
        Localizations.folderNone
    }

    public var localizedName: String {
        name
    }
}
