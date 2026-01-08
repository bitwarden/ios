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
    case replaced
}
