import Foundation

// MARK: - UserDTO

/// The simplified user model used to communicate between the watch and the main app.
public struct UserDTO: Codable {
    // MARK: Properties

    /// The user's email.
    public var email: String?

    /// The user's id.
    public var id: String

    /// The user's name.
    public var name: String?

    // MARK: Initialization

    /// Initializes a `UserDTO`.
    ///
    /// - Parameters:
    ///   - email: The user's email.
    ///   - id: The user's id.
    ///   - name: The user's name.
    ///
    public init(email: String? = nil, id: String, name: String? = nil) {
        self.email = email
        self.id = id
        self.name = name
    }
}
