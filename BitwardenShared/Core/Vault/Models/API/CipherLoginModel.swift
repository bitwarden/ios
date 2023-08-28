import Foundation

/// API model for a cipher login.
///
struct CipherLoginModel: Codable, Equatable {
    // MARK: Properties

    /// Whether the login should be autofilled when the page loads.
    let autofillOnPageLoad: Bool?

    /// The login's password.
    let password: String?

    /// The date of the password's last revision.
    let passwordRevisionDate: Date?

    /// The login's TOTP details.
    let totp: String?

    /// The login's URI.
    let uri: String?

    /// The login's list of URI details.
    let uris: [CipherLoginUriModel]?

    /// The login's username.
    let username: String?
}
