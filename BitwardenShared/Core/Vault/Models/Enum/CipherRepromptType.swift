/// An enum describing if the user should be re-prompted prior to using the cipher password.
///
enum CipherRepromptType: Int, Codable {
    /// No re-prompt is necessary.
    case none = 0

    /// The user should be prompted for their master password prior to using the cipher password.
    case password = 1
}
