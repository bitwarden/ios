import BitwardenSdk
import Foundation

/// A helper object to handle filtering a list of ciphers that match a URI.
///
enum CipherMatchingHelper {
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

    // MARK: Methods

    /// Returns the list of ciphers that match the URI.
    ///
    /// - Parameters:
    ///   - uri: The URI used to filter the list of ciphers.
    ///   - ciphers: The list of ciphers to filter.
    /// - Returns: The list of ciphers that match the URI.
    ///
    static func ciphersMatching(uri: String?, ciphers: [CipherView]) -> [CipherView] {
        guard let uri else { return [] }

        let matchingCiphers = ciphers.reduce(
            into: (exact: [CipherView], fuzzy: [CipherView])([], [])
        ) { result, cipher in
            switch checkForCipherMatch(cipher: cipher, matchUri: uri) {
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

    /// Returns the result of checking if a cipher matches a URI.
    ///
    /// - Parameters:
    ///   - cipher: The cipher to check if it matches the URI.
    ///   - matchUri: The URI used to check if the cipher matches.
    /// - Returns: The result of the match for the cipher and URI.
    ///
    private static func checkForCipherMatch(cipher: CipherView, matchUri: String) -> MatchResult {
        guard cipher.type == .login,
              let login = cipher.login,
              let loginUris = login.uris,
              cipher.deletedDate == nil else {
            return .none
        }

        var matchResult = MatchResult.none
        for loginUri in loginUris {
            guard let uri = loginUri.uri, !uri.isEmpty else { continue }
            let uriMatchType = loginUri.match ?? .domain

            switch uriMatchType {
            case .domain:
                // TODO: BIT-1097
                matchResult = .none
            case .host:
                let uriHost = URL(string: uri)?.hostWithPort
                let matchUriHost = URL(string: matchUri)?.hostWithPort
                if let uriHost, let matchUriHost, uriHost == matchUriHost {
                    matchResult = .exact
                } else {
                    matchResult = .none
                }
            case .startsWith:
                matchResult = uri.starts(with: matchUri) ? .exact : .none
            case .exact:
                matchResult = uri == matchUri ? .exact : .none
            case .regularExpression:
                let range = uri.range(of: matchUri, options: [.caseInsensitive, .regularExpression])
                matchResult = range != nil ? .exact : .none
            case .never:
                matchResult = .none
            }

            if matchResult != .none {
                break
            }
        }

        return matchResult
    }
}
