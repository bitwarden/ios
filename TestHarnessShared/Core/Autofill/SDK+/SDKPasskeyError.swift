import Foundation

// MARK: - SDKPasskeyError

/// Errors produced by the SDK-backed passkey scenarios.
///
enum SDKPasskeyError: Equatable, Error, LocalizedError {
    /// More than one stored credential matched the requested relying party; picking between
    /// them isn't supported by this scenario yet.
    case ambiguousCredential

    /// No stored credential matched the requested relying party.
    case noMatchingCredential

    var errorDescription: String? {
        switch self {
        case .ambiguousCredential:
            Localizations.sdkAmbiguousCredentialReceived
        case .noMatchingCredential:
            Localizations.sdkNoMatchingCredentialReceived
        }
    }
}
