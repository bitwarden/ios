import BitwardenResources

/// Represents the result of imported credentials or credentials to export of one type.
struct CXFCredentialsResult: Equatable, Sendable {
    // MARK: Types

    /// The available credential type to be used in Credential Exchange.
    enum CXFCredentialType: String, Equatable, Sendable {
        case card = "Card"
        case identity = "Identity"
        case passkey = "Passkey"
        case password = "Password"
        case secureNote = "SecureNote"
        case sshKey = "SSHKey"
    }

    // MARK: Properties

    /// The number of credentials for the type
    let count: Int

    /// The localized type in plural.
    var localizedTypePlural: String {
        return switch type {
        case .card:
            Localizations.cards
        case .identity:
            Localizations.identities
        case .passkey:
            Localizations.passkeys
        case .password:
            Localizations.passwords
        case .secureNote:
            Localizations.secureNotes
        case .sshKey:
            Localizations.sshKeys
        }
    }

    /// Whether the result has no credentials for the type.
    var isEmpty: Bool {
        count == 0 // swiftlint:disable:this empty_count
    }

    /// The credential type.
    let type: CXFCredentialType
}

// MARK: - Identifiable

extension CXFCredentialsResult: Identifiable {
    public var id: CXFCredentialType {
        type
    }
}
