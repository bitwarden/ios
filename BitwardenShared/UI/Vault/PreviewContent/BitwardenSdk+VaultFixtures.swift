// swiftlint:disable:this file_name
// swiftlint:disable file_length

import BitwardenSdk
import Foundation

#if DEBUG
extension AttachmentView {
    static func fixture(
        fileName: String? = nil,
        id: String? = "1",
        key: String? = nil,
        size: String? = nil,
        sizeName: String? = nil,
        url: String? = nil,
    ) -> AttachmentView {
        .init(
            id: id,
            url: url,
            size: size,
            sizeName: sizeName,
            fileName: fileName,
            key: key,
        )
    }
}

extension Cipher {
    static func fixture(
        archivedDate: Date? = nil,
        attachments: [Attachment]? = nil,
        card: Card? = nil,
        collectionIds: [String] = [],
        creationDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        deletedDate: Date? = nil,
        edit: Bool = true,
        favorite: Bool = false,
        fields: [Field]? = nil,
        folderId: String? = nil,
        id: String? = nil,
        identity: Identity? = nil,
        key: String? = nil,
        localData: LocalData? = nil,
        login: BitwardenSdk.Login? = nil,
        name: String = "Bitwarden",
        notes: String? = nil,
        organizationId: String? = nil,
        organizationUseTotp: Bool = false,
        passwordHistory: [PasswordHistory]? = nil,
        permissions: CipherPermissions? = nil,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        revisionDate: Date = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        secureNote: SecureNote? = nil,
        sshKey: SshKey? = nil,
        type: BitwardenSdk.CipherType = .login,
        viewPassword: Bool = true,
    ) -> Cipher {
        Cipher(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: key,
            name: name,
            notes: notes,
            type: type,
            login: login,
            identity: identity,
            card: card,
            secureNote: secureNote,
            sshKey: sshKey,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            permissions: permissions,
            viewPassword: viewPassword,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate,
            archivedDate: archivedDate,
            data: nil,
        )
    }
}

extension CipherListView {
    static func fixture(
        id: Uuid? = "1",
        organizationId: Uuid? = nil,
        folderId: Uuid? = nil,
        collectionIds: [Uuid] = [],
        key: EncString? = nil,
        name: String = "Bitwarden",
        subtitle: String = "",
        type: CipherListViewType = .login(.fixture()),
        favorite: Bool = false,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        organizationUseTotp: Bool = false,
        edit: Bool = false,
        permissions: CipherPermissions? = nil,
        viewPassword: Bool = false,
        attachments: UInt32 = 0,
        hasOldAttachments: Bool = false,
        creationDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        deletedDate: DateTime? = nil,
        revisionDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        archivedDate: DateTime? = nil,
        copyableFields: [CopyableCipherFields] = [],
        localData: LocalDataView? = nil,
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
            hasOldAttachments: hasOldAttachments,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate,
            archivedDate: archivedDate,
            copyableFields: copyableFields,
            localData: localData,
        )
    }

    static func fixture(
        id: Uuid? = "1",
        organizationId: Uuid? = nil,
        folderId: Uuid? = nil,
        collectionIds: [Uuid] = [],
        key: EncString? = nil,
        login: LoginListView,
        name: String = "Bitwarden",
        subtitle: String = "",
        favorite: Bool = false,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        organizationUseTotp: Bool = false,
        edit: Bool = false,
        permissions: CipherPermissions? = nil,
        viewPassword: Bool = false,
        attachments: UInt32 = 0,
        hasOldAttachments: Bool = false,
        creationDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        deletedDate: DateTime? = nil,
        revisionDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        archivedDate: DateTime? = nil,
        copyableFields: [CopyableCipherFields] = [],
        localData: LocalDataView? = nil,
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
            hasOldAttachments: hasOldAttachments,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate,
            archivedDate: archivedDate,
            copyableFields: copyableFields,
            localData: localData,
        )
    }
}

extension CipherView {
    static func fixture(
        archivedDate: Date? = nil,
        attachments: [AttachmentView]? = nil,
        card: CardView? = nil,
        collectionIds: [String] = [],
        creationDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        deletedDate: Date? = nil,
        edit: Bool = true,
        favorite: Bool = false,
        fields: [FieldView]? = nil,
        folderId: String? = nil,
        id: String? = "1",
        identity: IdentityView? = nil,
        key: String? = nil,
        localData: LocalDataView? = nil,
        login: BitwardenSdk.LoginView? = nil,
        name: String = "Bitwarden",
        notes: String? = nil,
        organizationId: String? = nil,
        organizationUseTotp: Bool = false,
        passwordHistory: [PasswordHistoryView]? = nil,
        permissions: CipherPermissions? = nil,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        revisionDate: Date = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        secureNote: SecureNoteView? = nil,
        sshKey: SshKeyView? = nil,
        type: BitwardenSdk.CipherType = .login,
        viewPassword: Bool = true,
    ) -> CipherView {
        CipherView(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: key,
            name: name,
            notes: notes,
            type: type,
            login: login,
            identity: identity,
            card: card,
            secureNote: secureNote,
            sshKey: sshKey,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            permissions: permissions,
            viewPassword: viewPassword,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate,
            archivedDate: archivedDate,
        )
    }

    static func cardFixture(
        archivedDate: Date? = nil,
        attachments: [AttachmentView]? = nil,
        card: CardView = CardView.fixture(),
        collectionIds: [String] = [],
        creationDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        deletedDate: Date? = nil,
        edit: Bool = true,
        favorite: Bool = false,
        fields: [FieldView]? = nil,
        folderId: String? = nil,
        id: String = "8675",
        key: String? = nil,
        localData: LocalDataView? = nil,
        name: String = "Bitwarden",
        notes: String? = nil,
        organizationId: String? = nil,
        organizationUseTotp: Bool = false,
        passwordHistory: [PasswordHistoryView]? = nil,
        permissions: CipherPermissions? = nil,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        revisionDate: Date = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        viewPassword: Bool = true,
    ) -> CipherView {
        CipherView(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: key,
            name: name,
            notes: notes,
            type: .card,
            login: nil,
            identity: nil,
            card: card,
            secureNote: nil,
            sshKey: nil,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            permissions: permissions,
            viewPassword: viewPassword,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate,
            archivedDate: archivedDate,
        )
    }

    static func loginFixture(
        archivedDate: Date? = nil,
        attachments: [AttachmentView]? = nil,
        collectionIds: [String] = [],
        creationDate: DateTime = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        deletedDate: Date? = nil,
        edit: Bool = true,
        favorite: Bool = false,
        fields: [FieldView]? = nil,
        folderId: String? = nil,
        id: String = "8675",
        key: String? = nil,
        localData: LocalDataView? = nil,
        login: BitwardenSdk.LoginView = .fixture(),
        name: String = "Bitwarden",
        notes: String? = nil,
        organizationId: String? = nil,
        organizationUseTotp: Bool = false,
        passwordHistory: [PasswordHistoryView]? = nil,
        permissions: CipherPermissions? = nil,
        reprompt: BitwardenSdk.CipherRepromptType = .none,
        revisionDate: Date = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41),
        viewPassword: Bool = true,
    ) -> CipherView {
        CipherView(
            id: id,
            organizationId: organizationId,
            folderId: folderId,
            collectionIds: collectionIds,
            key: key,
            name: name,
            notes: notes,
            type: .login,
            login: login,
            identity: nil,
            card: nil,
            secureNote: nil,
            sshKey: nil,
            favorite: favorite,
            reprompt: reprompt,
            organizationUseTotp: organizationUseTotp,
            edit: edit,
            permissions: permissions,
            viewPassword: viewPassword,
            localData: localData,
            attachments: attachments,
            fields: fields,
            passwordHistory: passwordHistory,
            creationDate: creationDate,
            deletedDate: deletedDate,
            revisionDate: revisionDate,
            archivedDate: archivedDate,
        )
    }

    static func totpFixture(
        id: String = "8675",
        name: String = "Bitwarden",
        totp: String = "1234",
    ) -> CipherView {
        .loginFixture(
            id: id,
            login: .fixture(totp: totp),
            name: name,
        )
    }
}

extension Collection {
    static func fixture(
        id: String? = "",
        organizationId: String = "",
        name: String = "",
        externalId: String = "",
        hidePasswords: Bool = false,
        manage: Bool = false,
        readOnly: Bool = false,
        defaultUserCollectionEmail: String? = nil,
        type: BitwardenSdk.CollectionType = .sharedCollection,
    ) -> Collection {
        Collection(
            id: id,
            organizationId: organizationId,
            name: name,
            externalId: externalId,
            hidePasswords: hidePasswords,
            readOnly: readOnly,
            manage: manage,
            defaultUserCollectionEmail: defaultUserCollectionEmail,
            type: type,
        )
    }
}

extension BitwardenSdk.CardView {
    static func fixture(
        brand: String? = nil,
        cardholderName: String? = nil,
        code: String? = nil,
        expMonth: String? = nil,
        expYear: String? = nil,
        number: String? = nil,
    ) -> BitwardenSdk.CardView {
        BitwardenSdk.CardView(
            cardholderName: cardholderName,
            expMonth: expMonth,
            expYear: expYear,
            code: code,
            brand: brand,
            number: number,
        )
    }
}

extension CollectionView {
    static func fixture(
        externalId: String = "",
        hidePasswords: Bool = false,
        id: String? = "collection-view-1",
        name: String = "",
        organizationId: String = "",
        manage: Bool = false,
        readOnly: Bool = false,
        type: BitwardenSdk.CollectionType = .sharedCollection,
    ) -> CollectionView {
        CollectionView(
            id: id,
            organizationId: organizationId,
            name: name,
            externalId: externalId,
            hidePasswords: hidePasswords,
            readOnly: readOnly,
            manage: manage,
            type: type,
        )
    }
}

extension Fido2Credential {
    static func fixture(
        counter: String = "",
        creationDate: Date = Date(year: 2024, month: 3, day: 15, hour: 9, minute: 15),
        credentialId: String = "",
        discoverable: String = "",
        keyAlgorithm: String = "",
        keyCurve: String = "",
        keyType: String = "",
        keyValue: String = "",
        rpId: String = "",
        rpName: String? = nil,
        userDisplayName: String? = nil,
        userHandle: String? = nil,
        userName: String? = nil,
    ) -> Fido2Credential {
        Fido2Credential(
            credentialId: credentialId,
            keyType: keyType,
            keyAlgorithm: keyAlgorithm,
            keyCurve: keyCurve,
            keyValue: keyValue,
            rpId: rpId,
            userHandle: userHandle,
            userName: userName,
            counter: counter,
            rpName: rpName,
            userDisplayName: userDisplayName,
            discoverable: discoverable,
            creationDate: creationDate,
        )
    }
}

extension BitwardenSdk.Fido2CredentialAutofillView {
    static func fixture(
        credentialId: Data = Data(capacity: 16),
        cipherId: String = "1",
        rpId: String = "myApp.com",
        userNameForUi: String? = nil,
        userHandle: Data = Data(capacity: 64),
        hasCounter: Bool = false,
    ) -> BitwardenSdk.Fido2CredentialAutofillView {
        .init(
            credentialId: credentialId,
            cipherId: cipherId,
            rpId: rpId,
            userNameForUi: userNameForUi,
            userHandle: userHandle,
            hasCounter: hasCounter,
        )
    }
}

extension Fido2CredentialListView {
    static func fixture(
        credentialId: String = "1",
        rpId: String = "myApp.com",
        userHandle: String? = nil,
        userName: String? = nil,
        userDisplayName: String? = nil,
        counter: String = "0",
    ) -> Fido2CredentialListView {
        .init(
            credentialId: credentialId,
            rpId: rpId,
            userHandle: userHandle,
            userName: userName,
            userDisplayName: userDisplayName,
            counter: counter,
        )
    }
}

extension Fido2CredentialView {
    static func fixture(
        counter: String = "",
        creationDate: Date = Date(year: 2024, month: 3, day: 15, hour: 9, minute: 15),
        credentialId: String = "",
        discoverable: String = "",
        keyAlgorithm: String = "",
        keyCurve: String = "",
        keyType: String = "",
        keyValue: String = "",
        rpId: String = "",
        rpName: String? = nil,
        userDisplayName: String? = nil,
        userHandle: String? = nil,
        userName: String? = nil,
    ) -> Fido2CredentialView {
        Fido2CredentialView(
            credentialId: credentialId,
            keyType: keyType,
            keyAlgorithm: keyAlgorithm,
            keyCurve: keyCurve,
            keyValue: keyValue,
            rpId: rpId,
            userHandle: userHandle,
            userName: userName,
            counter: counter,
            rpName: rpName,
            userDisplayName: userDisplayName,
            discoverable: discoverable,
            creationDate: creationDate,
        )
    }
}

extension BitwardenSdk.FieldView {
    static func fixture(
        name: String? = "Name",
        value: String? = "1",
        type: BitwardenSdk.FieldType = BitwardenSdk.FieldType.hidden,
        linkedId: BitwardenSdk.LinkedIdType? = nil,
    ) -> BitwardenSdk.FieldView {
        BitwardenSdk.FieldView(
            name: name,
            value: value,
            type: type,
            linkedId: linkedId,
        )
    }
}

extension BitwardenSdk.IdentityView {
    static func fixture(
        title: String? = nil,
        firstName: String? = nil,
        middleName: String? = nil,
        lastName: String? = nil,
        address1: String? = nil,
        address2: String? = nil,
        address3: String? = nil,
        city: String? = nil,
        state: String? = nil,
        postalCode: String? = nil,
        country: String? = nil,
        company: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        ssn: String? = nil,
        username: String? = nil,
        passportNumber: String? = nil,
        licenseNumber: String? = nil,
    ) -> BitwardenSdk.IdentityView {
        BitwardenSdk.IdentityView(
            title: title,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            address1: address1,
            address2: address2,
            address3: address3,
            city: city,
            state: state,
            postalCode: postalCode,
            country: country,
            company: company,
            email: email,
            phone: phone,
            ssn: ssn,
            username: username,
            passportNumber: passportNumber,
            licenseNumber: licenseNumber,
        )
    }
}

extension BitwardenSdk.Login {
    static func fixture(
        autofillOnPageLoad: Bool? = nil,
        fido2Credentials: [Fido2Credential]? = nil,
        password: String? = nil,
        passwordRevisionDate: Date? = nil,
        uris: [LoginUri]? = nil,
        username: String? = nil,
        totp: String? = nil,
    ) -> BitwardenSdk.Login {
        BitwardenSdk.Login(
            username: username,
            password: password,
            passwordRevisionDate: passwordRevisionDate,
            uris: uris,
            totp: totp,
            autofillOnPageLoad: autofillOnPageLoad,
            fido2Credentials: fido2Credentials,
        )
    }
}

extension BitwardenSdk.LoginListView {
    static func fixture(
        fido2Credentials: [Fido2CredentialListView]? = nil,
        hasFido2: Bool = false,
        username: String? = nil,
        totp: EncString? = nil,
        uris: [LoginUriView]? = nil,
    ) -> LoginListView {
        .init(
            fido2Credentials: fido2Credentials,
            hasFido2: hasFido2,
            username: username,
            totp: totp,
            uris: uris,
        )
    }
}

extension BitwardenSdk.LoginView {
    static func fixture(
        fido2Credentials: [Fido2Credential]? = nil,
        password: String? = nil,
        passwordRevisionDate: DateTime? = nil,
        uris: [LoginUriView]? = nil,
        username: String? = nil,
        totp: String? = nil,
        autofillOnPageLoad: Bool? = nil,
    ) -> BitwardenSdk.LoginView {
        BitwardenSdk.LoginView(
            username: username,
            password: password,
            passwordRevisionDate: passwordRevisionDate,
            uris: uris,
            totp: totp,
            autofillOnPageLoad: autofillOnPageLoad,
            fido2Credentials: fido2Credentials,
        )
    }
}

extension BitwardenSdk.LoginUri {
    static func fixture(
        uri: String? = "https://example.com",
        match: BitwardenSdk.UriMatchType? = nil,
        uriChecksum: String? = nil,
    ) -> LoginUri {
        LoginUri(
            uri: uri,
            match: match,
            uriChecksum: uriChecksum,
        )
    }
}

extension BitwardenSdk.LoginUriView {
    static func fixture(
        uri: String? = "https://example.com",
        match: BitwardenSdk.UriMatchType? = nil,
        uriChecksum: String? = nil,
    ) -> LoginUriView {
        LoginUriView(
            uri: uri,
            match: match,
            uriChecksum: uriChecksum,
        )
    }
}

extension BitwardenSdk.SshKey {
    static func fixture(
        privateKey: String = "privateKey",
        publicKey: String = "publicKey",
        fingerprint: String = "fingerprint",
    ) -> SshKey {
        SshKey(privateKey: privateKey, publicKey: publicKey, fingerprint: fingerprint)
    }
}

extension BitwardenSdk.SshKeyView {
    static func fixture(
        privateKey: String = "privateKey",
        publicKey: String = "publicKey",
        fingerprint: String = "fingerprint",
    ) -> SshKeyView {
        SshKeyView(privateKey: privateKey, publicKey: publicKey, fingerprint: fingerprint)
    }
}

extension PasswordHistoryView {
    static func fixture(
        password: String = "",
        lastUsedDate: Date = Date(year: 2024, month: 1, day: 1),
    ) -> PasswordHistoryView {
        PasswordHistoryView(
            password: password,
            lastUsedDate: lastUsedDate,
        )
    }
}
#endif
