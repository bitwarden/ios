// MARK: - SeededAccount

/// An account created by the seeder.
///
struct SeededAccount {
    /// The email to log in with.
    let email: String

    /// The master password.
    let password: String

    /// The account's user key, base64 encoded. The seeder needs it to encrypt items for the account.
    let base64EncodedUserKey: String

    /// The account's user ID.
    let userId: String
}
