import Foundation

// MARK: - AccountTokenProviderError

/// Error logged when the active account changes during a token refresh operation.
///
struct AccountTokenProviderError: Error, CustomStringConvertible {
    // MARK: Properties

    /// The active user ID before the token refresh operation.
    let userIdBefore: String

    /// The active user ID after the token refresh operation.
    let userIdAfter: String

    // MARK: CustomStringConvertible

    var description: String {
        """
        Token refresh race condition detected: Active account changed from '\(userIdBefore)' to '\(userIdAfter)' \
        during token refresh operation. Tokens were not stored.
        """
    }
}
