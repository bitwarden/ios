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
        guard let firstUri = uris?.first, let uri = firstUri.uri else {
            return nil
        }

        // The system doesn't match a `.URL` service identifier without a scheme (e.g. `www.example.com`)
        // to the website, and a URI without a scheme can't be parsed for its host, so add one before
        // parsing or registering the URI. `httpsNormalized()` isn't used because it would also add
        // `https://` before app URIs (e.g. `iosapp://`) and remove trailing slashes.
        let trimmedUri = uri.trimmingCharacters(in: .whitespaces)
        let uriWithScheme = trimmedUri.contains("://") ? trimmedUri : "https://" + trimmedUri

        // Web URIs matched by domain or host are registered as a `.domain` service identifier, so the
        // system matches them regardless of the website's scheme or path. URIs matched exactly or by
        // prefix, regular expressions, and non-web URIs (e.g. app URIs) are registered as a `.URL`
        // service identifier.
        if let domain = domainIdentifier(for: uriWithScheme, match: firstUri.match) {
            return ASCredentialServiceIdentifier(identifier: domain, type: .domain)
        }

        return ASCredentialServiceIdentifier(identifier: uriWithScheme, type: .URL)
    }

    /// Returns the domain to register as a `.domain` service identifier for a login URI, if the
    /// URI can be matched by domain.
    ///
    /// - Parameters:
    ///   - uri: The login URI, including a scheme.
    ///   - match: The login URI's match type.
    /// - Returns: The lowercased base domain for a `.domain` match type (or the default match type),
    ///   the lowercased host (without a port) for a `.host` match type, or `nil` if the URI isn't an
    ///   `http` or `https` URI with a host or has a match type that isn't matched by domain or host.
    ///
    private func domainIdentifier(for uri: String, match: BitwardenSdk.UriMatchType?) -> String? {
        guard let url = URL(string: uri),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }

        let domain: String? = switch match {
        case .domain, nil:
            url.domain
        case .host:
            url.host
        case .exact, .never, .regularExpression, .startsWith:
            nil
        }
        return domain?.lowercased()
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
