import BitwardenSdk

// MARK: - CipherChange

/// Represents a change to a cipher in the data store.
///
public enum CipherChange {
    /// A cipher was inserted or updated.
    case upserted(Cipher)

    /// A cipher was deleted.
    case deleted(Cipher)

    /// All ciphers were replaced (bulk operation).
    case replacedAll
}

// MARK: - CustomDebugStringConvertible

extension CipherChange: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .upserted(cipher):
            "upserted(\(cipher.id ?? "nil"))"
        case let .deleted(cipher):
            "deleted(\(cipher.id ?? "nil"))"
        case .replacedAll:
            "replacedAll"
        }
    }
}
