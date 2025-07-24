import BitwardenResources

/// An enum that describes how a URI should be matched for autofill to occur.
///
enum UriMatchType: Int, CaseIterable, Codable, Equatable, Hashable, Menuable {
    /// Matching of the URI is based on the domain.
    case domain = 0

    /// Matching of the URI is based on the host.
    case host = 1

    /// Matching of the URI is based the start of resource.
    case startsWith = 2

    /// Matching of the URI requires an exact match.
    case exact = 3

    /// Matching of the URI requires an exact match.
    case regularExpression = 4

    /// The URI should never be autofilled.
    case never = 5

    var localizedName: String {
        switch self {
        case .domain: Localizations.baseDomain
        case .host: Localizations.host
        case .startsWith: Localizations.startsWith
        case .exact: Localizations.exact
        case .regularExpression: Localizations.regEx
        case .never: Localizations.never
        }
    }
}
