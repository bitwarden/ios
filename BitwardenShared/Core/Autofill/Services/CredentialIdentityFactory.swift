import AuthenticationServices
import BitwardenSdk

/// Protocol of the factory to create credential identities.
protocol CredentialIdentityFactory {
    /// Creates the `ASCredentialIdentity` array from a `CipherView` (it may return empty).
    /// - Parameters:
    ///   - cipher: The cipher to get the identities from.
    ///   - accountHasPremium: Whether the active account has Premium access.
    /// - Returns: An array of `ASCredentialIdentity` (password or one time code)
    @available(iOS 17.0, *)
    func createCredentialIdentities(from cipher: CipherView, accountHasPremium: Bool) async -> [ASCredentialIdentity]

    /// Tries to create a `ASPasswordCredentialIdentity` from the given `cipher`
    /// - Parameter cipher: CIpher to create the password identity.
    /// - Returns: The password credential identity or `nil` if it can't be created.
    func tryCreatePasswordCredentialIdentity(from cipher: CipherView) -> ASPasswordCredentialIdentity?
}

/// Default implementation of `CredentialIdentityFactory` to create credential identities.
struct DefaultCredentialIdentityFactory: CredentialIdentityFactory {
    @available(iOS 17.0, *)
    func createCredentialIdentities(from cipher: CipherView, accountHasPremium: Bool) async -> [ASCredentialIdentity] {
        var identities = [ASCredentialIdentity]()

        let isTotpAuthorized = accountHasPremium || cipher.organizationUseTotp
        if isTotpAuthorized, let oneTimeCodeIdentity = tryCreateOneTimeCodeIdentity(from: cipher) {
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
        guard let firstUri = uris?.first, let uriString = firstUri.uri else {
            return nil
        }

        // Web URIs matched by domain or host are registered as a `.domain` service identifier with the
        // URI's host, so the system matches them regardless of the website's scheme or path. URIs
        // matched exactly or by prefix, regular expressions, and non-web URIs (e.g. app URIs) are
        // registered as a `.URL` service identifier with the URI as it's saved.
        if let host = domainIdentifier(for: uriString, match: firstUri.match) {
            return ASCredentialServiceIdentifier(identifier: host, type: .domain)
        }

        // The system doesn't match a `.URL` service identifier without a scheme (e.g. `www.example.com`)
        // to the website, so add one to an exact match URI that doesn't have one.
        let urlIdentifier = firstUri.match == .exact && !uriString.contains("://") ? "https://" + uriString : uriString
        return ASCredentialServiceIdentifier(identifier: urlIdentifier, type: .URL)
    }

    /// Returns the host to register as a `.domain` service identifier for a login URI, if the URI
    /// is matched by domain or host.
    ///
    /// - Parameters:
    ///   - uri: The login URI as it's saved, with or without a scheme.
    ///   - match: The login URI's match type.
    /// - Returns: The lowercased host (without a scheme, port, or path) for a `.domain`, `.host`, or
    ///   default match type, or `nil` if the URI has a different match type or isn't an `http` or
    ///   `https` URI with a host.
    ///
    private func domainIdentifier(for uri: String, match: BitwardenSdk.UriMatchType?) -> String? {
        switch match {
        case .domain, .host, nil:
            break
        case .exact, .never, .regularExpression, .startsWith:
            return nil
        }

        // A URI without a scheme (e.g. `www.example.com`) can't be parsed for its host, so add one
        // before parsing. `httpsNormalized()` isn't used because it would also add `https://` before
        // app URIs (e.g. `iosapp://`), which would then be parsed as a web URI.
        let trimmedUri = uri.trimmingCharacters(in: .whitespaces)
        let uriWithScheme = trimmedUri.contains("://") ? trimmedUri : "https://" + trimmedUri

        guard let url = URL(string: uriWithScheme),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else {
            return nil
        }
        return host.lowercased()
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
