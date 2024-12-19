/// Represents the result of imported credentials of one type.
struct ImportedCredentialsResult: Equatable, Sendable {
    // MARK: Types

    /// The available imported credential type.
    enum ImportedCredentialType: String, Equatable, Sendable {
        case card = "Card"
        case identity = "Identity"
        case passkey = "Passkey"
        case password = "Password"
        case secureNote = "SecureNote"
        case sshKey = "SSHKey"
    }

    // MARK: Properties

    /// The number of credentials imported for the type
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

    /// The credential type imported.
    let type: ImportedCredentialType
}

// MARK: - Identifiable

extension ImportedCredentialsResult: Identifiable {
    public var id: ImportedCredentialType {
        type
    }
}
