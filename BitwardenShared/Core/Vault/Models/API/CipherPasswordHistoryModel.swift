import Foundation

/// API model for a cipher password history.
///
struct CipherPasswordHistoryModel: Codable, Equatable {
    // MARK: Properties

    /// The date that the password was last used.
    let lastUsedDate: Date

    /// The password.
    let password: String
}
