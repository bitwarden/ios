import BitwardenSdk
import CryptoKit
import Foundation

/// A protocol for a service that handles Fido2 tasks. This is similar to
/// `ClientFido2Protocol` but returns the protocols so they can be mocked for testing.
///
protocol ClientFido2Service: AnyObject {
    /// Returns the `ClientFido2Authenticator` to perform Fido2 authenticator tasks on vault items.
    /// - Parameters:
    ///   - userInterface: `Fido2UserInterface` with necessary platform side logic related to UI.
    ///   - credentialStore: `Fido2CredentialStore` with necessary platform side logic related to credential storage.
    /// - Returns: Returns the `ClientFido2Authenticator` to perform Fido2 authenticator tasks
    func vaultAuthenticator(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore,
    ) -> ClientFido2AuthenticatorProtocol
    
    /// - Parameters:
    ///   - userInterface: `Fido2UserInterface` with necessary platform side logic related to UI.
    ///   - credentialStore: `Fido2CredentialStore` with necessary platform side logic related to credential storage.
    ///   - deviceKey: `SymmetricKey` used to encrypt data on the device.
    /// - Returns: Returns the `ClientFido2Authenticator` to perform Fido2 authenticator tasks
    func deviceAuthenticator(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore,
        deviceKey: SymmetricKey,
    ) -> ClientFido2AuthenticatorProtocol

    /// Returns the `ClientFido2Authenticator` to perform Fido2 authenticator tasks on keychain items.
    /// - Parameters:
    ///   - userInterface: `Fido2UserInterface` with necessary platform side logic related to UI.
    ///   - credentialStore: `Fido2CredentialStore` with necessary platform side logic related to credential storage.
    ///   - deviceKey: `SymmetricKey` used to encrypt data on the device.
    /// - Returns: Returns the `ClientFido2Authenticator` to perform Fido2 authenticator tasks
    func deviceAuthenticator(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore,
        deviceKey: SymmetricKey
    ) -> ClientFido2AuthenticatorProtocol

    /// Returns the `ClientFido2Client` to perform Fido2 client tasks.
    /// - Parameters:
    ///   - userInterface: `Fido2UserInterface` with necessary platform side logic related to UI.
    ///   - credentialStore: `Fido2CredentialStore` with necessary platform side logic related to credential storage.
    /// - Returns: Returns the `ClientFido2Client` to perform Fido2 client tasks
    func client(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore,
    ) -> ClientFido2ClientProtocol

    /// Decrypts the `CipherView` Fido2 credentials but returning an array of `Fido2CredentialAutofillView`
    /// - Parameter cipherView: `CipherView` containing the Fido2 credentials to decrypt.
    /// - Returns: An array of decrypted Fido2 credentials of type `Fido2CredentialAutofillView`.
    func decryptFido2AutofillCredentials(
        cipherView: CipherView,
        encryptionKey: SymmetricKey?
    ) throws -> [Fido2CredentialAutofillView]
}

// MARK: ClientFido2

extension ClientFido2: ClientFido2Service {
    func vaultAuthenticator(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore
    ) -> ClientFido2AuthenticatorProtocol {
        vaultAuthenticator(
            userInterface: userInterface,
            credentialStore: credentialStore
        ) as ClientFido2Authenticator
    }

    func deviceAuthenticator(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore,
        deviceKey: SymmetricKey,
    ) -> ClientFido2AuthenticatorProtocol {
        let encryptionKey = deviceKey.withUnsafeBytes { bytes in
            Data(Array(bytes))
        }
        return deviceAuthenticator(
            userInterface: userInterface,
            credentialStore: credentialStore,
            encryptionKey: encryptionKey
        ) as ClientFido2Authenticator
    }
    
    func client(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore,
    ) -> ClientFido2ClientProtocol {
        client(userInterface: userInterface, credentialStore: credentialStore) as ClientFido2Client
    }

    func decryptFido2AutofillCredentials(
        cipherView: CipherView,
        encryptionKey: SymmetricKey?
    ) throws -> [Fido2CredentialAutofillView] {
        let key = encryptionKey.map { key in
            key.withUnsafeBytes { bytes in
                Data(Array(bytes))
            }
        }
        return try decryptFido2AutofillCredentials(cipherView: cipherView, encryptionKey: key)
    }
}
