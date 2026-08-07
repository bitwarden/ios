import BitwardenSdk
import Foundation

// MARK: - SDKStoredCipher

/// A `Codable` mirror of the handful of `Cipher`/`Fido2Credential` fields the SDK-backed passkey
/// scenarios actually populate, since `BitwardenSdk.Cipher` doesn't itself conform to `Codable`.
/// Every cipher these scenarios create is a login-type cipher with exactly one Fido2 credential,
/// so the remaining `Cipher` fields are reconstructed with the same fixed defaults used when the
/// cipher was originally created rather than persisted.
///
struct SDKStoredCipher: Codable, Equatable {
    /// The Fido2 credential's signature counter.
    let counter: String

    /// The cipher's creation date.
    let creationDate: Date

    /// The Fido2 credential's ID.
    let credentialId: String

    /// Whether the Fido2 credential is discoverable.
    let discoverable: String

    /// The Fido2 credential's creation date.
    let fido2CreationDate: Date

    /// The cipher's ID.
    let id: String?

    /// The cipher's individual encryption key.
    let key: String?

    /// The Fido2 credential's key algorithm.
    let keyAlgorithm: String

    /// The Fido2 credential's key curve.
    let keyCurve: String

    /// The Fido2 credential's key type.
    let keyType: String

    /// The Fido2 credential's private key value.
    let keyValue: String

    /// The cipher's name.
    let name: String?

    /// The cipher's revision date.
    let revisionDate: Date

    /// The Fido2 credential's relying party ID.
    let rpId: String

    /// The Fido2 credential's relying party name.
    let rpName: String?

    /// The Fido2 credential's user display name.
    let userDisplayName: String?

    /// The Fido2 credential's user handle.
    let userHandle: String?

    /// The Fido2 credential's username.
    let userName: String?

    /// The cipher's login username.
    let username: String?
}

extension SDKStoredCipher {
    /// Reconstructs the `Cipher` this `SDKStoredCipher` mirrors.
    var cipher: Cipher {
        Cipher(
            id: id,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: key,
            name: name,
            notes: nil,
            type: .login,
            login: Login(
                username: username,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil,
                fido2Credentials: [
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
                        creationDate: fido2CreationDate,
                    ),
                ],
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
            fields: nil,
            passwordHistory: nil,
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: revisionDate,
            archivedDate: nil,
            data: nil,
        )
    }

    /// Initializes an `SDKStoredCipher` from a `Cipher`.
    ///
    /// - Parameter cipher: The cipher to mirror. Returns `nil` if it isn't a login cipher with a
    ///   Fido2 credential, since that's the only shape this scenario ever creates.
    ///
    init?(cipher: Cipher) {
        guard let login = cipher.login, let fido2Credential = login.fido2Credentials?.first else {
            return nil
        }

        counter = fido2Credential.counter
        creationDate = cipher.creationDate
        credentialId = fido2Credential.credentialId
        discoverable = fido2Credential.discoverable
        fido2CreationDate = fido2Credential.creationDate
        id = cipher.id
        key = cipher.key
        keyAlgorithm = fido2Credential.keyAlgorithm
        keyCurve = fido2Credential.keyCurve
        keyType = fido2Credential.keyType
        keyValue = fido2Credential.keyValue
        name = cipher.name
        revisionDate = cipher.revisionDate
        rpId = fido2Credential.rpId
        rpName = fido2Credential.rpName
        userDisplayName = fido2Credential.userDisplayName
        userHandle = fido2Credential.userHandle
        userName = fido2Credential.userName
        username = login.username
    }
}
