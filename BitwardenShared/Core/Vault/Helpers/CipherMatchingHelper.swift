import BitwardenSdk
import Foundation

// MARK: CipherMatchResult

/// An enum describing the strength that a cipher matches a URI.
///
enum CipherMatchResult {
    /// The cipher is an exact match for the URI.
    case exact

    /// The cipher is a close match for the URI.
    case fuzzy

    /// The cipher doesn't match the URI.
    case none
}

// MARK: CipherMatchingHelper

/// A helper to handle filtering ciphers that match a URI.
///
protocol CipherMatchingHelper { // sourcery: AutoMockable
    /// Returns the list of ciphers that match the URI.
    ///
    /// - Parameters:
    ///   - uri: The URI used to filter the list of ciphers.
    ///   - ciphers: The list of ciphers to filter.
    /// - Returns: The list of ciphers that match the URI.
    ///
    func ciphersMatching(uri: String?, ciphers: [CipherListView]) async -> [CipherListView]

    /// Returns the result of checking if a cipher matches a URI.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to check if it matches the URI.
    ///   - defaultMatchType: The default match type to use if the cipher doesn't specify one.
    ///   - matchUri: The URI used to check if the cipher matches.
    ///   - matchingDomains: A list of domains that match the `matchUri`'s domain to match against.
    ///   - matchingFuzzyDomains: A list of domains that closely match the `matchUri`'s domain to match against.
    /// - Returns: The result of the match for the cipher and URI.
    func doesCipherMatch(
        cipher: CipherListView,
        defaultMatchType: BitwardenShared.UriMatchType,
        matchUri: String,
        matchingDomains: Set<String>,
        matchingFuzzyDomains: Set<String>
    ) -> CipherMatchResult

    /// Returns a list of domains that match the specified domain. If the domain is contained
    /// within the equivalent domains list, this will return all equivalent domains. Otherwise, it
    /// will just return the domain.
    ///
    /// - Parameters:
    ///   - matchUri:The URI to match against.
    /// - Returns: A list of domains to match against.
    ///
    func getMatchingDomains(matchUri: String) async -> (matching: Set<String>, fuzzyMatching: Set<String>)
}

// MARK: DefaultCipherMatchingHelper

/// Default implemenetation of `CipherMatchingHelper`.
///
class DefaultCipherMatchingHelper: CipherMatchingHelper {
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

    func ciphersMatching(uri: String?, ciphers: [CipherListView]) async -> [CipherListView] {
        guard let uri else { return [] }

        let (matching: matchingDomains, fuzzyMatching: matchingFuzzyDomains) = await getMatchingDomains(
            matchUri: uri
        )
        let defaultMatchType = await stateService.getDefaultUriMatchType()

        let matchingCiphers = ciphers.reduce(
            into: (exact: [CipherListView], fuzzy: [CipherListView])([], [])
        ) { result, cipher in
            let match = doesCipherMatch(
                cipher: cipher,
                defaultMatchType: defaultMatchType,
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

    func doesCipherMatch(
        cipher: CipherListView,
        defaultMatchType: UriMatchType,
        matchUri: String,
        matchingDomains: Set<String>,
        matchingFuzzyDomains: Set<String>
    ) -> CipherMatchResult {
        guard let login = cipher.type.loginListView,
              let loginUris = login.uris,
              cipher.deletedDate == nil else {
            return .none
        }

        var matchResult = CipherMatchResult.none
        for loginUri in loginUris {
            guard let uri = loginUri.uri, !uri.isEmpty else { continue }
            let uriMatchType = loginUri.match ?? BitwardenSdk.UriMatchType(type: defaultMatchType)

            switch uriMatchType {
            case .domain:
                matchResult = checkForCipherDomainMatch(
                    isApp: URL(string: matchUri)?.isApp ?? false,
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

    func getMatchingDomains(matchUri: String) async -> (matching: Set<String>, fuzzyMatching: Set<String>) {
        let matchURL = URL(string: matchUri)
        let isApp = matchURL?.isApp ?? false
        let matchDomain = isApp ? matchURL?.domain : matchURL?.sanitized.domain

        guard let matchDomain else {
            return ([], [])
        }

        let appWebURL = matchURL?.appWebURL

        let equivalentDomains = await (try? settingsService.fetchEquivalentDomains()) ?? [[]]

        var matchingDomains = [String]()
        var matchingFuzzyDomains = [String]()
        for domains in equivalentDomains {
            let domainSet = Set(domains)
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
    ) -> CipherMatchResult {
        let loginURL = URL(string: loginUri)
        let loginURLSanitized = isApp
            ? loginURL
            : loginURL?.sanitized
        let loginUriDomain = loginURLSanitized?.domain?.lowercased()

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
}

struct CipherMatchingMetadata {

}
