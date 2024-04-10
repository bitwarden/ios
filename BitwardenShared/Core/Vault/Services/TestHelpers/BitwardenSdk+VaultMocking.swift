// swiftlint:disable:this file_name

import BitwardenSdk

extension Attachment {
    init(attachmentView: AttachmentView) {
        self.init(
            id: attachmentView.id,
            url: attachmentView.url,
            size: attachmentView.size,
            sizeName: attachmentView.sizeName,
            fileName: attachmentView.fileName,
            key: attachmentView.key
        )
    }
}

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

extension Card {
    init(cardView: CardView) {
        self.init(
            cardholderName: cardView.cardholderName,
            expMonth: cardView.expMonth,
            expYear: cardView.expYear,
            code: cardView.code,
            brand: cardView.brand,
            number: cardView.number
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

extension Cipher {
    init(cipherView: CipherView) {
        self.init(
            id: cipherView.id,
            organizationId: cipherView.organizationId,
            folderId: cipherView.folderId,
            collectionIds: cipherView.collectionIds,
            key: cipherView.key,
            name: cipherView.name,
            notes: cipherView.notes,
            type: cipherView.type,
            login: cipherView.login.map(Login.init),
            identity: cipherView.identity.map(Identity.init),
            card: cipherView.card.map(Card.init),
            secureNote: cipherView.secureNote.map(SecureNote.init),
            favorite: cipherView.favorite,
            reprompt: cipherView.reprompt,
            organizationUseTotp: cipherView.organizationUseTotp,
            edit: cipherView.edit,
            viewPassword: cipherView.viewPassword,
            localData: cipherView.localData.map(LocalData.init),
            attachments: cipherView.attachments?.map(Attachment.init),
            fields: cipherView.fields?.map(Field.init),
            passwordHistory: cipherView.passwordHistory?.map(PasswordHistory.init),
            creationDate: cipherView.creationDate,
            deletedDate: cipherView.deletedDate,
            revisionDate: cipherView.revisionDate
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
            key: cipher.key,
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

extension CollectionView {
    init(collection: Collection) {
        self.init(
            id: collection.id,
            organizationId: collection.organizationId,
            name: collection.name,
            externalId: collection.externalId,
            hidePasswords: collection.hidePasswords,
            readOnly: collection.readOnly
        )
    }
}

extension Field {
    init(fieldView: FieldView) {
        self.init(
            name: fieldView.name,
            value: fieldView.value,
            type: fieldView.type,
            linkedId: fieldView.linkedId
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

extension Folder {
    init(folderView: FolderView) {
        self.init(
            id: folderView.id,
            name: folderView.name,
            revisionDate: folderView.revisionDate
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

extension Identity {
    init(identityView: IdentityView) {
        self.init(
            title: identityView.title,
            firstName: identityView.firstName,
            middleName: identityView.middleName,
            lastName: identityView.lastName,
            address1: identityView.address1,
            address2: identityView.address2,
            address3: identityView.address3,
            city: identityView.city,
            state: identityView.state,
            postalCode: identityView.postalCode,
            country: identityView.country,
            company: identityView.company,
            email: identityView.email,
            phone: identityView.phone,
            ssn: identityView.ssn,
            username: identityView.username,
            passportNumber: identityView.passportNumber,
            licenseNumber: identityView.licenseNumber
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

extension LocalData {
    init(localDataView: LocalDataView) {
        self.init(
            lastUsedDate: localDataView.lastUsedDate,
            lastLaunched: localDataView.lastLaunched
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

extension Login {
    init(loginView: LoginView) {
        self.init(
            username: loginView.username,
            password: loginView.password,
            passwordRevisionDate: loginView.passwordRevisionDate,
            uris: loginView.uris?.map(LoginUri.init),
            totp: loginView.totp,
            autofillOnPageLoad: loginView.autofillOnPageLoad,
            fido2Credentials: loginView.fido2Credentials
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
            autofillOnPageLoad: login.autofillOnPageLoad,
            fido2Credentials: login.fido2Credentials
        )
    }
}

extension LoginUri {
    init(loginUriView: LoginUriView) {
        self.init(
            uri: loginUriView.uri,
            match: loginUriView.match,
            uriChecksum: loginUriView.uriChecksum
        )
    }
}

extension LoginUriView {
    init(loginUri: LoginUri) {
        self.init(
            uri: loginUri.uri,
            match: loginUri.match,
            uriChecksum: loginUri.uriChecksum
        )
    }
}

extension PasswordHistory {
    init(passwordHistoryView: PasswordHistoryView) {
        self.init(
            password: passwordHistoryView.password,
            lastUsedDate: passwordHistoryView.lastUsedDate
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

extension SecureNote {
    init(secureNoteView: SecureNoteView) {
        self.init(type: secureNoteView.type)
    }
}

extension SecureNoteView {
    init(secureNote: SecureNote) {
        self.init(type: secureNote.type)
    }
}

extension SendFileView {
    init(sendFile: SendFile) {
        self.init(
            id: sendFile.id,
            fileName: sendFile.fileName,
            size: sendFile.size,
            sizeName: sendFile.sizeName
        )
    }
}

extension SendTextView {
    init(sendText: SendText) {
        self.init(
            text: sendText.text,
            hidden: sendText.hidden
        )
    }
}

extension SendView {
    init(send: Send) {
        self.init(
            id: send.id,
            accessId: send.accessId,
            name: send.name,
            notes: send.notes,
            key: send.key,
            newPassword: nil,
            hasPassword: !(send.password?.isEmpty ?? true),
            type: send.type,
            file: send.file.map(SendFileView.init),
            text: send.text.map(SendTextView.init),
            maxAccessCount: send.maxAccessCount,
            accessCount: send.accessCount,
            disabled: send.disabled,
            hideEmail: send.hideEmail,
            revisionDate: send.revisionDate,
            deletionDate: send.deletionDate,
            expirationDate: send.expirationDate
        )
    }
}

extension SendFile {
    init(sendFileView: SendFileView) {
        self.init(
            id: sendFileView.id,
            fileName: sendFileView.fileName,
            size: sendFileView.size,
            sizeName: sendFileView.sizeName
        )
    }
}

extension SendText {
    init(sendTextView: SendTextView) {
        self.init(
            text: sendTextView.text,
            hidden: sendTextView.hidden
        )
    }
}

extension Send {
    init(sendView: SendView) {
        self.init(
            id: sendView.id,
            accessId: sendView.accessId,
            name: sendView.name,
            notes: sendView.notes,
            key: sendView.key ?? "",
            password: sendView.newPassword,
            type: sendView.type,
            file: sendView.file.map(SendFile.init),
            text: sendView.text.map(SendText.init),
            maxAccessCount: sendView.maxAccessCount,
            accessCount: sendView.accessCount,
            disabled: sendView.disabled,
            hideEmail: sendView.hideEmail,
            revisionDate: sendView.revisionDate,
            deletionDate: sendView.deletionDate,
            expirationDate: sendView.expirationDate
        )
    }
} // swiftlint:disable:this file_length
