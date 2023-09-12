// MARK: - KdfType

/// The type of key derivation function.
///
enum KdfType: Int, Codable, Equatable {
    /// The PBKDF2 SHA256 type.
    case pbkdf2sha256 = 0

    /// The Argon2id type.
    case argon2id = 1
}
