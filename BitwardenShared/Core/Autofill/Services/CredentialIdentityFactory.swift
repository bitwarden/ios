import AuthenticationServices
import BitwardenSdk

/// Protocol of the factory to create credential identities.
protocol CredentialIdentityFactory {
    /// Creates the `ASCredentialIdentity` array from a `CipherView` (it may return empty).
    /// - Parameter cipher: The cipher to get the identities from.
    /// - Returns: An array of `ASCredentialIdentity` (password or one time code)
    @available(iOS 17.0, *)
    func createCredentialIdentities(from cipher: CipherView) async -> [ASCredentialIdentity]

    /// Tries to create a `ASPasswordCredentialIdentity` from the given `cipher`
    /// - Parameter cipher: CIpher to create the password identity.
    /// - Returns: The password credential identity or `nil` if it can't be created.
    func tryCreatePasswordCredentialIdentity(from cipher: CipherView) -> ASPasswordCredentialIdentity?
}

/// Default implementation of `CredentialIdentityFactory` to create credential identities.
struct DefaultCredentialIdentityFactory: CredentialIdentityFactory {
    @available(iOS 17.0, *)
    func createCredentialIdentities(from cipher: CipherView) async -> [ASCredentialIdentity] {
        var identities = [ASCredentialIdentity]()

        if let oneTimeCodeIdentity = tryCreateOneTimeCodeIdentity(from: cipher) {
            identities.append(oneTimeCodeIdentity)
        }

        guard !cipher.hasFido2Credentials || cipher.login?.password != nil else {
            // if this is the case then a passkey credential identity needs to be provided
            // but that's handled differently to improve performance from the SDK.
            return identities
        }

        if let passwordIdentity = tryCreatePasswordCredentialIdentity(from: cipher) {
            identities.append(passwordIdentity)
        }
        return identities
    }

    func tryCreatePasswordCredentialIdentity(from cipher: BitwardenSdk.CipherView) -> ASPasswordCredentialIdentity? {
        guard let serviceIdentifier = createServiceIdentifierFromFirstLoginUri(of: cipher),
              let username = cipher.login?.username, !username.isEmpty
        else {
            return nil
        }

        return ASPasswordCredentialIdentity(
            serviceIdentifier: serviceIdentifier,
            user: username,
            recordIdentifier: cipher.id,
        )
    }

    // MARK: Private

    /// Gets the service identifier based on the first login uri, if there's one.
    private func createServiceIdentifierFromFirstLoginUri(of cipher: CipherView) -> ASCredentialServiceIdentifier? {
        let uris = cipher.login?.uris?.filter { $0.match != .never && $0.uri.isEmptyOrNil == false }
        guard let uri = uris?.first?.uri else {
            return nil
        }

        return ASCredentialServiceIdentifier(identifier: uri, type: .URL)
    }

    /// Tries to create a one time code credential identity if possible from the `cipher`.
    /// - Parameter cipher: The cipher to get the one time code identity.
    /// - Returns: An `ASOneTimeCodeCredentialIdentity` if possible, `nil` otherwise.
    @available(iOS 17.0, *)
    private func tryCreateOneTimeCodeIdentity(from cipher: CipherView) -> ASCredentialIdentity? {
        guard #available(iOSApplicationExtension 18.0, *) else {
            return nil
        }

        guard let serviceIdentifier = createServiceIdentifierFromFirstLoginUri(of: cipher),
              cipher.login?.totp != nil else {
            return nil
        }

        return ASOneTimeCodeCredentialIdentity(
            serviceIdentifier: serviceIdentifier,
            label: cipher.name,
            recordIdentifier: cipher.id,
        )
    }
}
