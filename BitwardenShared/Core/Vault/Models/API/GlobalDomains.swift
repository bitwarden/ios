/// API model for a group of domains that should be matched together.
///
struct GlobalDomains: Codable, Equatable {
    // MARK: Properties

    /// A list of domains that should all match a URI.
    let domains: [String]?

    /// Whether the domain is excluded.
    let excluded: Bool

    /// The domain type identifier.
    let type: Int?
}
