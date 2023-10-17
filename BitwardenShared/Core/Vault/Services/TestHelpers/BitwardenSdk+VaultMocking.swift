// swiftlint:disable:this file_name

import BitwardenSdk

extension AttachmentView {
    init(attachment: Attachment) {
        self.init(
            id: attachment.id,
            url: attachment.url,
            size: attachment.size,
            sizeName: attachment.sizeName,
            fileName: attachment.fileName,
            key: attachment.key
        )
    }
}

extension CardView {
    init(card: Card) {
        self.init(
            cardholderName: card.cardholderName,
            expMonth: card.expMonth,
            expYear: card.expYear,
            code: card.code,
            brand: card.brand,
            number: card.number
        )
    }
}

extension CipherListView {
    init(cipher: Cipher) {
        self.init(
            id: cipher.id,
            organizationId: cipher.organizationId,
            folderId: cipher.folderId,
            collectionIds: cipher.collectionIds,
            name: cipher.name,
            subTitle: "",
            type: cipher.type,
            favorite: cipher.favorite,
            reprompt: cipher.reprompt,
            edit: cipher.edit,
            viewPassword: cipher.viewPassword,
            attachments: UInt32(cipher.attachments?.count ?? 0),
            creationDate: cipher.creationDate,
            deletedDate: cipher.deletedDate,
            revisionDate: cipher.revisionDate
        )
    }
}

extension CipherView {
    init(cipher: Cipher) {
        self.init(
            id: cipher.id,
            organizationId: cipher.organizationId,
            folderId: cipher.folderId,
            collectionIds: cipher.collectionIds,
            name: cipher.name,
            notes: cipher.notes,
            type: cipher.type,
            login: cipher.login.map(LoginView.init),
            identity: cipher.identity.map(IdentityView.init),
            card: cipher.card.map(CardView.init),
            secureNote: cipher.secureNote.map(SecureNoteView.init),
            favorite: cipher.favorite,
            reprompt: cipher.reprompt,
            organizationUseTotp: cipher.organizationUseTotp,
            edit: cipher.edit,
            viewPassword: cipher.viewPassword,
            localData: cipher.localData.map(LocalDataView.init),
            attachments: cipher.attachments?.map(AttachmentView.init),
            fields: cipher.fields?.map(FieldView.init),
            passwordHistory: cipher.passwordHistory?.map(PasswordHistoryView.init),
            creationDate: cipher.creationDate,
            deletedDate: cipher.deletedDate,
            revisionDate: cipher.revisionDate
        )
    }
}

extension FieldView {
    init(field: Field) {
        self.init(
            name: field.name,
            value: field.value,
            type: field.type,
            linkedId: field.linkedId
        )
    }
}

extension FolderView {
    init(folder: Folder) {
        self.init(
            id: folder.id,
            name: folder.name,
            revisionDate: folder.revisionDate
        )
    }
}

extension IdentityView {
    init(identity: Identity) {
        self.init(
            title: identity.title,
            firstName: identity.firstName,
            middleName: identity.middleName,
            lastName: identity.lastName,
            address1: identity.address1,
            address2: identity.address2,
            address3: identity.address3,
            city: identity.city,
            state: identity.state,
            postalCode: identity.postalCode,
            country: identity.country,
            company: identity.company,
            email: identity.email,
            phone: identity.phone,
            ssn: identity.ssn,
            username: identity.username,
            passportNumber: identity.passportNumber,
            licenseNumber: identity.licenseNumber
        )
    }
}

extension LocalDataView {
    init(localData: LocalData) {
        self.init(
            lastUsedDate: localData.lastUsedDate,
            lastLaunched: localData.lastLaunched
        )
    }
}

extension LoginView {
    init(login: Login) {
        self.init(
            username: login.username,
            password: login.password,
            passwordRevisionDate: login.passwordRevisionDate,
            uris: login.uris?.map(LoginUriView.init),
            totp: login.totp,
            autofillOnPageLoad: login.autofillOnPageLoad
        )
    }
}

extension LoginUriView {
    init(loginUri: LoginUri) {
        self.init(
            uri: loginUri.uri,
            match: loginUri.match
        )
    }
}

extension PasswordHistoryView {
    init(passwordHistory: PasswordHistory) {
        self.init(
            password: passwordHistory.password,
            lastUsedDate: passwordHistory.lastUsedDate
        )
    }
}

extension SecureNoteView {
    init(secureNote: SecureNote) {
        self.init(type: secureNote.type)
    }
}
