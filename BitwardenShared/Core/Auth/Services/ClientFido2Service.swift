import BitwardenSdk
import Foundation

/// A protocol for a service that handles Fido2 tasks. This is similar to
/// `ClientFido2Protocol` but returns the protocols so they can be mocked for testing.
///
protocol ClientFido2Service: AnyObject {
    /// Returns the `ClientFido2Authenticator` to perform Fido2 authenticator tasks.
    /// - Parameters:
    ///   - userInterface: `Fido2UserInterface` with necessary platform side logic related to UI.
    ///   - credentialStore: `Fido2CredentialStore` with necessary platform side logic related to credential storage.
    /// - Returns: Returns the `ClientFido2Authenticator` to perform Fido2 authenticator tasks
    func authenticator(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore
    ) -> ClientFido2AuthenticatorProtocol

    /// Returns the `ClientFido2Client` to perform Fido2 client tasks.
    /// - Parameters:
    ///   - userInterface: `Fido2UserInterface` with necessary platform side logic related to UI.
    ///   - credentialStore: `Fido2CredentialStore` with necessary platform side logic related to credential storage.
    /// - Returns: Returns the `ClientFido2Client` to perform Fido2 client tasks
    func client(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore
    ) -> ClientFido2ClientProtocol
}

// MARK: ClientPlatform

extension ClientFido2: ClientFido2Service {
    func authenticator(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore
    ) -> ClientFido2AuthenticatorProtocol {
        authenticator(userInterface: userInterface, credentialStore: credentialStore) as ClientFido2Authenticator
    }

    func client(
        userInterface: Fido2UserInterface,
        credentialStore: Fido2CredentialStore
    ) -> ClientFido2ClientProtocol {
        client(userInterface: userInterface, credentialStore: credentialStore) as ClientFido2Client
    }
}
