import AuthenticationServices
import BitwardenSdk

/// Protocol of the factory to create credential identities.
protocol CredentialIdentityFactory {
    /// Creates the `ASCredentialIdentity` array from a `CipherView` (it may return empty).
    ///
    /// Identities are created for each of the login's URIs that's used for AutoFill, so the login is
    /// suggested on every site or app it's saved for.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to get the identities from.
    ///   - accountHasPremium: Whether the active account has Premium access.
    /// - Returns: An array of `ASCredentialIdentity` (password or one time code)
    @available(iOS 17.0, *)
    func createCredentialIdentities(from cipher: CipherView, accountHasPremium: Bool) async -> [ASCredentialIdentity]

    /// Creates an `ASPasswordCredentialIdentity` for each of the `cipher`'s login URIs that's used
    /// for AutoFill.
    ///
    /// - Parameter cipher: Cipher to create the password identities.
    /// - Returns: The password credential identities, or an empty array if they can't be created.
    func createPasswordCredentialIdentities(from cipher: CipherView) -> [ASPasswordCredentialIdentity]
}

/// Default implementation of `CredentialIdentityFactory` to create credential identities.
struct DefaultCredentialIdentityFactory: CredentialIdentityFactory {
    @available(iOS 17.0, *)
    func createCredentialIdentities(from cipher: CipherView, accountHasPremium: Bool) async -> [ASCredentialIdentity] {
        var identities = [ASCredentialIdentity]()

        let isTotpAuthorized = accountHasPremium || cipher.organizationUseTotp
        if isTotpAuthorized {
            identities.append(contentsOf: createOneTimeCodeIdentities(from: cipher))
        }

        guard !cipher.hasFido2Credentials || cipher.login?.password != nil else {
            // if this is the case then a passkey credential identity needs to be provided
            // but that's handled differently to improve performance from the SDK.
            return identities
        }

        identities.append(contentsOf: createPasswordCredentialIdentities(from: cipher))
        return identities
    }

    func createPasswordCredentialIdentities(from cipher: BitwardenSdk.CipherView) -> [ASPasswordCredentialIdentity] {
        guard let username = cipher.login?.username, !username.isEmpty else {
            return []
        }

        return createServiceIdentifiers(of: cipher).map { serviceIdentifier in
            ASPasswordCredentialIdentity(
                serviceIdentifier: serviceIdentifier,
                user: username,
                recordIdentifier: cipher.id,
            )
        }
    }

    // MARK: Private

    /// Creates an `ASOneTimeCodeCredentialIdentity` for each of the `cipher`'s login URIs that's
    /// used for AutoFill, if the cipher has a TOTP.
    ///
    /// - Parameter cipher: The cipher to get the one time code identities.
    /// - Returns: The one time code credential identities, or an empty array if they can't be created.
    @available(iOS 17.0, *)
    private func createOneTimeCodeIdentities(from cipher: CipherView) -> [ASCredentialIdentity] {
        guard #available(iOSApplicationExtension 18.0, *), cipher.login?.totp != nil else {
            return []
        }

        return createServiceIdentifiers(of: cipher).map { serviceIdentifier in
            ASOneTimeCodeCredentialIdentity(
                serviceIdentifier: serviceIdentifier,
                label: cipher.name,
                recordIdentifier: cipher.id,
            )
        }
    }

    /// Creates a service identifier for each of the cipher's login URIs that's used for AutoFill.
    ///
    /// URIs that map to the same service identifier (e.g. `https://example.com` and
    /// `https://example.com/login`, which are both registered as the `example.com` domain) are only
    /// included once.
    ///
    /// - Parameter cipher: The cipher to get the service identifiers from.
    /// - Returns: The unique service identifiers, in the order of the login's URIs.
    ///
    private func createServiceIdentifiers(of cipher: CipherView) -> [ASCredentialServiceIdentifier] {
        var serviceIdentifiers = [ASCredentialServiceIdentifier]()
        for serviceIdentifier in cipher.login?.uris?.compactMap(\.credentialServiceIdentifier) ?? [] {
            let isDuplicate = serviceIdentifiers.contains { existing in
                existing.type == serviceIdentifier.type && existing.identifier == serviceIdentifier.identifier
            }
            if !isDuplicate {
                serviceIdentifiers.append(serviceIdentifier)
            }
        }
        return serviceIdentifiers
    }
}
