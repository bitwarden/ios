// swiftlint:disable:this file_name
// swiftlint:disable file_length

import BitwardenSdk

// MARK: - Ciphers

extension CipherCardModel {
    init(card: BitwardenSdk.Card) {
        self.init(
            brand: card.brand,
            cardholderName: card.cardholderName,
            code: card.code,
            expMonth: card.expMonth,
            expYear: card.expYear,
            number: card.number
        )
    }
}

extension CipherFieldModel {
    init(field: BitwardenSdk.Field) {
        self.init(
            linkedId: field.linkedId.flatMap(LinkedIdType.init),
            name: field.name,
            type: FieldType(fieldType: field.type),
            value: field.value
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
            username: identity.username
        )
    }
}

extension CipherLoginModel {
    init(login: BitwardenSdk.Login) {
        self.init(
            autofillOnPageLoad: login.autofillOnPageLoad,
            password: login.password,
            passwordRevisionDate: login.passwordRevisionDate,
            totp: login.totp,
            uris: login.uris?.map(CipherLoginUriModel.init),
            username: login.username
        )
    }
}

extension CipherLoginUriModel {
    init(loginUri: BitwardenSdk.LoginUri) {
        self.init(
            match: loginUri.match.map(UriMatchType.init),
            uri: loginUri.uri
        )
    }
}

extension CipherPasswordHistoryModel {
    init(passwordHistory: BitwardenSdk.PasswordHistory) {
        self.init(
            lastUsedDate: passwordHistory.lastUsedDate,
            password: passwordHistory.password
        )
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
            key: model.key
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
            number: model.number
        )
    }
}

extension BitwardenSdk.Cipher {
    init(responseModel model: CipherDetailsResponseModel) {
        self.init(
            id: model.id,
            organizationId: model.organizationId,
            folderId: model.folderId,
            collectionIds: model.collectionIds ?? [],
            name: model.name,
            notes: model.notes,
            type: BitwardenSdk.CipherType(model.type),
            login: model.login.map(Login.init),
            identity: model.identity.map(Identity.init),
            card: model.card.map(Card.init),
            secureNote: model.secureNote.map(SecureNote.init),
            favorite: model.favorite,
            reprompt: BitwardenSdk.CipherRepromptType(model.reprompt),
            organizationUseTotp: model.organizationUseTotp,
            edit: model.edit,
            viewPassword: model.viewPassword,
            localData: nil,
            attachments: model.attachments?.map(Attachment.init),
            fields: model.fields?.map(Field.init),
            passwordHistory: model.passwordHistory?.map(PasswordHistory.init),
            creationDate: model.creationDate,
            deletedDate: model.deletedDate,
            revisionDate: model.revisionDate
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

extension BitwardenSdk.Field {
    init(cipherFieldModel model: CipherFieldModel) {
        self.init(
            name: model.name,
            value: model.value,
            type: BitwardenSdk.FieldType(fieldType: model.type),
            linkedId: model.linkedId?.rawValue
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
            licenseNumber: model.licenseNumber
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
            autofillOnPageLoad: model.autofillOnPageLoad
        )
    }
}

extension BitwardenSdk.LoginUri {
    init(cipherLoginUriModel model: CipherLoginUriModel) {
        self.init(
            uri: model.uri,
            match: model.match.map(BitwardenSdk.UriMatchType.init)
        )
    }
}

extension BitwardenSdk.PasswordHistory {
    init(cipherPasswordHistoryModel model: CipherPasswordHistoryModel) {
        self.init(
            password: model.password,
            lastUsedDate: model.lastUsedDate
        )
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

// MARK: Collections (BitwardenSdk)

extension BitwardenSdk.Collection {
    init(collectionDetailsResponseModel model: CollectionDetailsResponseModel) {
        self.init(
            id: model.id,
            organizationId: model.organizationId,
            name: model.name,
            externalId: model.externalId,
            hidePasswords: model.hidePasswords,
            readOnly: model.readOnly
        )
    }
}

// MARK: - Folders (BitwardenSdk)

extension BitwardenSdk.Folder {
    init(folderResponseModel model: FolderResponseModel) {
        self.init(
            id: model.id,
            name: model.name,
            revisionDate: model.revisionDate
        )
    }
}

// MARK: - Sends (BitwardenSdk)

extension BitwardenSdk.Send {
    init(sendResponseModel model: SendResponseModel) {
        self.init(
            id: model.id,
            accessId: model.accessId,
            name: model.name,
            notes: model.notes,
            key: model.key,
            password: model.password,
            type: BitwardenSdk.SendType(type: model.type),
            file: model.file.map(SendFile.init),
            text: model.text.map(SendText.init),
            maxAccessCount: model.maxAccessCount,
            accessCount: model.accessCount,
            disabled: model.disabled,
            hideEmail: model.hideEmail,
            revisionDate: model.revisionDate,
            deletionDate: model.deletionDate,
            expirationDate: model.expirationDate
        )
    }
}

extension BitwardenSdk.SendType {
    init(type: SendType) {
        switch type {
        case .file:
            self = .file
        case .text:
            self = .text
        }
    }
}

extension BitwardenSdk.SendFile {
    init(sendFileModel model: SendFileModel) {
        self.init(
            id: model.id,
            fileName: model.fileName,
            size: model.size,
            sizeName: model.sizeName
        )
    }
}

extension BitwardenSdk.SendText {
    init(sendTextModel model: SendTextModel) {
        self.init(
            text: model.text,
            hidden: model.hidden
        )
    }
}
