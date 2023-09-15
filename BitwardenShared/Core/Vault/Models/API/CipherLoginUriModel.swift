import Foundation

/// API model for a cipher login URI.
///
struct CipherLoginUriModel: Codable, Equatable {
    // MARK: Properties

    /// How the URI should be matched for autofill to occur.
    let match: UriMatchType?

    /// The login's URI.
    let uri: String?
}
