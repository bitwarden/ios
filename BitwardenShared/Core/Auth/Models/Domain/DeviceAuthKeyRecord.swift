import BitwardenSdk

/// Stored key material needed to assert the device auth key passkey.
struct DeviceAuthKeyRecord: Decodable, Encodable {
    let cipherId: String
    let cipherName: String
    let credentialId: String
    let keyType: String
    let keyAlgorithm: String
    let keyCurve: String
    let keyValue: String
    let rpId: String
    let rpName: String
    let userId: String
    let userName: String
    let userDisplayName: String
    let counter: String
    let discoverable: String
    let hmacSecret: String
    let creationDate: DateTime
    
    func toCipherView() -> CipherView {
        CipherView(
            id: cipherId,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: cipherName,
            notes: nil,
            type: .login,
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: true,
                fido2Credentials: [
                    Fido2Credential(
                        credentialId: credentialId,
                        keyType: keyType,
                        keyAlgorithm: keyAlgorithm,
                        keyCurve: keyCurve,
                        keyValue: keyValue,
                        rpId: rpId,
                        userHandle: userId,
                        userName: userName,
                        counter: counter,
                        rpName: rpName,
                        userDisplayName: userDisplayName,
                        discoverable: discoverable,
                        // TODO(PM-26177): SDK will add this field
                        // hmacSecret: hmacSecret,
                        creationDate: creationDate
                    ),
                ]
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
            viewPassword: false,
            localData: nil,
            attachments: nil,
            fields: nil,
            passwordHistory: nil,
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: creationDate,
            archivedDate: nil
        )
    }
    
    func toCipher() -> Cipher {
        Cipher(
            id: cipherId,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: cipherName,
            notes: nil,
            type: .login,
            login: BitwardenSdk.Login(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: true,
                fido2Credentials: [
                    Fido2Credential(
                        credentialId: credentialId,
                        keyType: keyType,
                        keyAlgorithm: keyAlgorithm,
                        keyCurve: keyCurve,
                        keyValue: keyValue,
                        rpId: rpId,
                        userHandle: userId,
                        userName: userName,
                        counter: counter,
                        rpName: rpName,
                        userDisplayName: userDisplayName,
                        discoverable: discoverable,
                        // TODO(PM-26177): SDK will add this field
                        // hmacSecret: hmacSecret,
                        creationDate: creationDate
                    ),
                ]
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
            viewPassword: false,
            localData: nil,
            attachments: nil,
            fields: nil,
            passwordHistory: nil,
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: creationDate,
            archivedDate: nil,
            data: nil,
        )
    }
}
