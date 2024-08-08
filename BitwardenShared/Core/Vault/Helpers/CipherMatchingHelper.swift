import BitwardenSdk
import Foundation

/// A helper object to handle filtering a list of ciphers that match a URI.
///
class CipherMatchingHelper {
    // MARK: Types

    /// An enum describing the strength that a cipher matches a URI.
    ///
    enum MatchResult {
        /// The cipher is an exact match for the URI.
        case exact

        /// The cipher is a close match for the URI.
        case fuzzy

        /// The cipher doesn't match the URI.
        case none
    }

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
        let matchIsApp = matchURL?.isApp ?? false
        let matchDomain = matchIsApp ? matchURL?.domain : matchURL?.sanitized.domain
        let matchAppWebURL = matchURL?.appWebURL

        let (matching: matchingDomains, fuzzyMatching: matchingFuzzyDomains) = await getMatchingDomains(
            appWebURL: matchAppWebURL,
            isApp: matchIsApp,
            matchDomain: matchDomain,
            matchUri: uri
        )
        let defaultMatchType = await (try? stateService.getDefaultUriMatchType()) ?? .domain

        let matchingCiphers = ciphers.reduce(
            into: (exact: [CipherView], fuzzy: [CipherView])([], [])
        ) { result, cipher in
            let match = checkForCipherMatch(
                cipher: cipher,
                defaultMatchType: defaultMatchType,
                isApp: matchIsApp,
                matchUri: uri,
                matchingDomains: matchingDomains,
                matchingFuzzyDomains: matchingFuzzyDomains
            )
            switch match {
            case .exact:
                result.exact.append(cipher)
            case .fuzzy:
                result.fuzzy.append(cipher)
            case .none:
                // No-op: don't add non-matching ciphers.
                break
            }
        }

        return matchingCiphers.exact + matchingCiphers.fuzzy
    }

    // MARK: Private

    /// Determines if a list of domains contains a match for a cipher's URI.
    ///
    /// - Parameters:
    ///   - isApp: Whether the URL is an app URL.
    ///   - loginUri: The login's URI.
    ///   - matchingDomains: A list of domains to match against.
    ///   - matchingFuzzyDomains: A list of domains to fuzzy match against.
    /// - Returns: Whether the login's URI matches one of the domains in the `matchingDomains` list.
    ///
    private func checkForCipherDomainMatch(
        isApp: Bool,
        loginUri: String,
        matchingDomains: Set<String>,
        matchingFuzzyDomains: Set<String>
    ) -> MatchResult {
        let loginUriDomain = URL(string: loginUri)?.sanitized.domain?.lowercased()

        if matchingDomains.contains(loginUri) {
            return .exact
        } else if isApp, matchingFuzzyDomains.contains(loginUri) {
            return .fuzzy
        }

        if let loginUriDomain {
            if matchingDomains.contains(loginUriDomain) {
                return .exact
            } else if isApp, matchingFuzzyDomains.contains(loginUriDomain) {
                return .fuzzy
            }
        }

        return .none
    }

    /// Returns the result of checking if a cipher matches a URI.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to check if it matches the URI.
    ///   - defaultMatchType: The default match type to use if the cipher doesn't specify one.
    ///   - isApp: Whether the URL is an app URL.
    ///   - matchUri: The URI used to check if the cipher matches.
    ///   - matchingDomains: A list of domains that match the `matchUri`'s domain to match against.
    ///   - matchingFuzzyDomains: A list of domains that closely match the `matchUri`'s domain to match against.
    /// - Returns: The result of the match for the cipher and URI.
    ///
    private func checkForCipherMatch( // swiftlint:disable:this function_parameter_count
        cipher: CipherView,
        defaultMatchType: UriMatchType,
        isApp: Bool,
        matchUri: String,
        matchingDomains: Set<String>,
        matchingFuzzyDomains: Set<String>
    ) -> MatchResult {
        guard cipher.type == .login,
              let login = cipher.login,
              let loginUris = login.uris,
              cipher.deletedDate == nil else {
            return .none
        }

        var matchResult = MatchResult.none
        for loginUri in loginUris {
            guard let uri = loginUri.uri, !uri.isEmpty else { continue }
            let uriMatchType = loginUri.match ?? BitwardenSdk.UriMatchType(type: defaultMatchType)

            switch uriMatchType {
            case .domain:
                matchResult = checkForCipherDomainMatch(
                    isApp: isApp,
                    loginUri: uri,
                    matchingDomains: matchingDomains,
                    matchingFuzzyDomains: matchingFuzzyDomains
                )
            case .host:
                let uriHost = URL(string: uri)?.hostWithPort
                let matchUriHost = URL(string: matchUri)?.hostWithPort
                if let uriHost, let matchUriHost, uriHost == matchUriHost {
                    matchResult = .exact
                }
            case .startsWith:
                if matchUri.starts(with: uri) {
                    matchResult = .exact
                }
            case .exact:
                if uri == matchUri {
                    matchResult = .exact
                }
            case .regularExpression:
                let range = matchUri.range(of: uri, options: [.caseInsensitive, .regularExpression])
                if range != nil {
                    matchResult = .exact
                }
            case .never:
                matchResult = .none
            }

            if matchResult != .none {
                break
            }
        }

        return matchResult
    }

    /// Returns a list of domains that match the specified domain. If the domain is contained
    /// within the equivalent domains list, this will return all equivalent domains. Otherwise, it
    /// will just return the domain.
    ///
    /// - Parameters:
    ///   - appWebURL: The app's web URL minus the custom URL scheme.
    ///   - isApp: Whether the URL is an app URL.
    ///   - matchDomain: The domain used to check for equivalent domains.
    ///   - matchUri:The URI to match against.
    /// - Returns: A list of domains to match against.
    ///
    private func getMatchingDomains(
        appWebURL: URL?,
        isApp: Bool,
        matchDomain: String?,
        matchUri: String
    ) async -> (matching: Set<String>, fuzzyMatching: Set<String>) {
        guard let matchDomain else { return ([], []) }

        let equivalentDomains = await (try? settingsService.fetchEquivalentDomains()) ?? [[]]

        var matchingDomains = [String]()
        var matchingFuzzyDomains = [String]()
        for domain in equivalentDomains {
            let domainSet = Set(domain)
            if isApp {
                if domainSet.contains(matchDomain) {
                    matchingDomains.append(contentsOf: domainSet)
                } else if let appWebURLHost = appWebURL?.host, domainSet.contains(appWebURLHost) {
                    matchingFuzzyDomains.append(contentsOf: domainSet)
                }
            } else if domainSet.contains(matchDomain) {
                matchingDomains.append(contentsOf: domainSet)
            }
        }

        if matchingDomains.isEmpty {
            matchingDomains.append(isApp ? matchUri : matchDomain)
        }

        if isApp,
           let appWebURLHost = appWebURL?.host,
           matchingFuzzyDomains.isEmpty,
           !matchingDomains.contains(appWebURLHost) {
            matchingFuzzyDomains.append(appWebURLHost)
        }

        return (Set(matchingDomains), Set(matchingFuzzyDomains))
    }
}
