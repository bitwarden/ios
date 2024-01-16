import BitwardenSdk
import Foundation

/// A helper object to handle filtering a list of ciphers that match a URI.
///
class CipherMatchingHelper {
    // MARK: Properties

    /// The service used by the application to manage user settings.
    let settingsService: SettingsService

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `CipherMatchingHelper`.
    ///
    /// - Parameters:
    ///   - settingsService: The service used by the application to manage user settings.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(settingsService: SettingsService, stateService: StateService) {
        self.settingsService = settingsService
        self.stateService = stateService
    }

    // MARK: Methods

    /// Returns the list of ciphers that match the URI.
    ///
    /// - Parameters:
    ///   - uri: The URI used to filter the list of ciphers.
    ///   - ciphers: The list of ciphers to filter.
    /// - Returns: The list of ciphers that match the URI.
    ///
    func ciphersMatching(uri: String?, ciphers: [CipherView]) async -> [CipherView] {
        guard let uri else { return [] }

        let matchURL = URL(string: uri)
        let matchDomain = matchURL?.domain

        let matchingDomains = await getMatchingDomains(for: matchDomain)
        let defaultMatchType = await (try? stateService.getDefaultUriMatchType()) ?? .domain

        let matchingCiphers = ciphers.reduce(into: [CipherView]()) { result, cipher in
            let isMatch = checkForCipherMatch(
                cipher: cipher,
                defaultMatchType: defaultMatchType,
                matchUri: uri,
                matchingDomains: matchingDomains
            )
            guard isMatch else { return }
            result.append(cipher)
        }

        return matchingCiphers
    }

    // MARK: Private

    /// Determines if a list of domains contains a match for a cipher's URI.
    ///
    /// - Parameters:
    ///   - loginUri: The login's URI.
    ///   - matchingDomains: A list of domains to match against.
    /// - Returns: Whether the login's URI matches one of the domains in the `matchingDomains` list.
    ///
    private func checkForCipherDomainMatch(
        loginUri: String,
        matchingDomains: Set<String>
    ) -> Bool {
        let loginUriDomain = URL(string: loginUri)?.domain?.lowercased()

        if matchingDomains.contains(loginUri) {
            return true
        }

        if let loginUriDomain, matchingDomains.contains(loginUriDomain) {
            return true
        }

        return false
    }

    /// Returns the result of checking if a cipher matches a URI.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to check if it matches the URI.
    ///   - defaultMatchType: The default match type to use if the cipher doesn't specify one.
    ///   - matchUri: The URI used to check if the cipher matches.
    ///   - matchingDomains: A list of domains that match the `matchUri`'s domain to match against.
    /// - Returns: The result of the match for the cipher and URI.
    ///
    private func checkForCipherMatch(
        cipher: CipherView,
        defaultMatchType: UriMatchType,
        matchUri: String,
        matchingDomains: Set<String>
    ) -> Bool {
        guard cipher.type == .login,
              let login = cipher.login,
              let loginUris = login.uris,
              cipher.deletedDate == nil else {
            return false
        }

        var isMatch = false
        for loginUri in loginUris {
            guard let uri = loginUri.uri, !uri.isEmpty else { continue }
            let uriMatchType = loginUri.match ?? BitwardenSdk.UriMatchType(type: defaultMatchType)

            switch uriMatchType {
            case .domain:
                isMatch = checkForCipherDomainMatch(
                    loginUri: uri,
                    matchingDomains: matchingDomains
                )
            case .host:
                let uriHost = URL(string: uri)?.hostWithPort
                let matchUriHost = URL(string: matchUri)?.hostWithPort
                if let uriHost, let matchUriHost, uriHost == matchUriHost {
                    isMatch = true
                }
            case .startsWith:
                isMatch = matchUri.starts(with: uri)
            case .exact:
                isMatch = uri == matchUri
            case .regularExpression:
                let range = matchUri.range(of: uri, options: [.caseInsensitive, .regularExpression])
                isMatch = range != nil
            case .never:
                isMatch = false
            }

            if isMatch {
                break
            }
        }

        return isMatch
    }

    /// Returns a list of domains that match the specified domain. If the domain is contained
    /// within the equivalent domains list, this will return all equivalent domains. Otherwise, it
    /// will just return the domain.
    ///
    /// - Parameter matchDomain: The domain used to check for equivalent domains.
    /// - Returns: A list of domains to match against.
    ///
    private func getMatchingDomains(for matchDomain: String?) async -> Set<String> {
        guard let matchDomain else { return [] }

        let equivalentDomains = await (try? settingsService.fetchEquivalentDomains()) ?? [[]]

        var matchingDomains = [String]()
        for domain in equivalentDomains {
            let domainSet = Set(domain)
            if domainSet.contains(matchDomain) {
                matchingDomains.append(contentsOf: domainSet)
            }
        }

        if matchingDomains.isEmpty {
            matchingDomains.append(matchDomain)
        }

        return Set(matchingDomains)
    }
}
