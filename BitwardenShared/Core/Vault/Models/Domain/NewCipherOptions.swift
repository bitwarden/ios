/// Options that can be used to pre-populate the add item screen.
///
public struct NewCipherOptions: Equatable, Hashable {
    // MARK: Properties

    /// The name of the new cipher.
    var name: String?

    /// The password of the new cipher.
    var password: String?

    /// The URI of the new cipher.
    var uri: String?

    /// The username of the new cipher.
    var username: String?
}
