import BitwardenSdk
import Foundation

// MARK: CipherMatchingHelper

/// A helper to handle filtering ciphers that match a URI.
///
protocol CipherMatchingHelper { // sourcery: AutoMockable
    /// Returns the result of checking if a cipher matches the prepared URI.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to check if it matches the URI.
    ///   - archiveVaultItemsFF: The `FeatureFlag.archiveVaultItems` flag value.
    func doesCipherMatch(
        cipher: CipherListView,
        archiveVaultItemsFF: Bool,
    ) -> CipherMatchResult

    /// Prepares the cipher matching helper given the URI.
    /// - Parameter uri: URI to initialize the cipher matching helper with.
    func prepare(uri: String) async
}

// MARK: DefaultCipherMatchingHelper

/// Default implementation of `CipherMatchingHelper`.
///
class DefaultCipherMatchingHelper: CipherMatchingHelper {
    // MARK: Properties

    /// The default URI match type to use when a login URI doesn't have one specified.
    var defaultMatchType: UriMatchType = .domain

    /// Domains exactly matching the URI.
    var matchingDomains: Set<String> = []

    /// Domains fuzzy matching the URI.
    var matchingFuzzyDomains: Set<String> = []

    /// The service used by the application to manage user settings.
    let settingsService: SettingsService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// URI to check if matches.
    var uriToMatch: String?

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

    func doesCipherMatch(cipher: CipherListView, archiveVaultItemsFF: Bool) -> CipherMatchResult {
        guard let uriToMatch,
              let login = cipher.type.loginListView,
              let loginUris = login.uris,
              !cipher.isHiddenWithArchiveFF(flag: archiveVaultItemsFF) else {
            return .none
        }

        var matchResult = CipherMatchResult.none
        for loginUri in loginUris {
            guard let uri = loginUri.uri, !uri.isEmpty else { continue }
            let uriMatchType = loginUri.match ?? BitwardenSdk.UriMatchType(type: defaultMatchType)

            switch uriMatchType {
            case .domain:
                matchResult = checkForCipherDomainMatch(
                    isApp: URL(string: uriToMatch)?.isApp ?? false,
                    loginUri: uri,
                    matchingDomains: matchingDomains,
                    matchingFuzzyDomains: matchingFuzzyDomains,
                )
            case .host:
                let uriHost = URL(string: uri)?.hostWithPort
                let matchUriHost = URL(string: uriToMatch)?.hostWithPort
                if let uriHost, let matchUriHost, uriHost == matchUriHost {
                    matchResult = .exact
                }
            case .startsWith:
                if uriToMatch.starts(with: uri) {
                    matchResult = .exact
                }
            case .exact:
                if uri == uriToMatch {
                    matchResult = .exact
                }
            case .regularExpression:
                let range = uriToMatch.range(of: uri, options: [.caseInsensitive, .regularExpression])
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

    func prepare(uri: String) async {
        uriToMatch = uri
        defaultMatchType = await stateService.getDefaultUriMatchType()
        (matchingDomains, matchingFuzzyDomains) = await getMatchingDomains(matchUri: uri)
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
        matchingFuzzyDomains: Set<String>,
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

    /// Returns a list of domains that match the specified domain. If the domain is contained
    /// within the equivalent domains list, this will return all equivalent domains. Otherwise, it
    /// will just return the domain.
    ///
    /// - Parameters:
    ///   - matchUri:The URI to match against.
    /// - Returns: A list of domains to match against.
    ///
    private func getMatchingDomains(matchUri: String) async -> (matching: Set<String>, fuzzyMatching: Set<String>) {
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
}
