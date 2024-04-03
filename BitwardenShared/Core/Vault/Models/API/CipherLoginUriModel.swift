import Foundation

/// API model for a cipher login URI.
///
struct CipherLoginUriModel: Codable, Equatable, Hashable {
    // MARK: Properties

    /// How the URI should be matched for autofill to occur.
    let match: UriMatchType?

    /// The login's URI.
    let uri: String?

    /// A checksum of the URI.
    let uriChecksum: String?
}
