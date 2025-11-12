// MARK: CipherMatchResult

/// An enum describing the strength on a cipher matching operation.
enum CipherMatchResult {
    /// The cipher is an exact match for the "query".
    case exact

    /// The cipher is a close match for the "query".
    case fuzzy

    /// The cipher doesn't match the "query".
    case none
}
