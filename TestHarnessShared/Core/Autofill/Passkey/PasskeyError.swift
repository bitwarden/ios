import Foundation

// MARK: - PasskeyError

/// Errors produced by the SDK-backed passkey scenarios.
///
enum PasskeyError: Equatable, Error, LocalizedError {
    /// More than one stored credential matched the requested relying party; picking between
    /// them isn't supported by this scenario yet.
    case ambiguousCredential

    /// No stored credential matched the requested relying party.
    case noMatchingCredential

    var errorDescription: String? {
        switch self {
        case .ambiguousCredential:
            Localizations.ambiguousCredentialReceived
        case .noMatchingCredential:
            Localizations.noMatchingCredentialReceived
        }
    }
}
