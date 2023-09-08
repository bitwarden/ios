// MARK: - KdfTypeRequestModel

/// The type of key derivation function.
///
enum KdfTypeRequestModel: Int, Codable, Equatable {
    /// The PBKDF2 SHA256 type.
    case pbkdf2sha256 = 0

    /// The Argon2id type.
    case argon2id = 1
}
