import Foundation

// MARK: - CipherDTO

/// The simplified cipher model used to communicate between the watch and the main app.
///
public struct CipherDTO: Identifiable, Codable {
    // MARK: Properties

    /// The id of the cipher.
    public var id: String

    /// The login model of the cipher (all ciphers in the watch are of type login).
    public var login: LoginDTO

    /// The name of the cipher.
    public var name: String?

    /// The user id associated with the cipher.
    public var userId: String?

    enum CodingKeys: CodingKey {
        case id
        case name
        case login
    }

    // MARK: Initialization

    /// Initializes a `CipherDTO`.
    ///
    /// - Parameters:
    ///   - id: The id of the cipher.
    ///   - login: The login model of the cipher (all ciphers in the watch are of type login).
    ///   - name: The name of the cipher.
    ///   - userId: The user id associated with the cipher.
    ///
    public init(
        id: String,
        login: LoginDTO,
        name: String? = nil,
        userId: String? = nil
    ) {
        self.id = id
        self.login = login
        self.name = name
        self.userId = userId
    }
}

// MARK: - LoginDTO

/// The simplified login model used to communicate between the watch and the main app.
///
public struct LoginDTO: Codable {
    // MARK: Properties

    /// The totp code for the login.
    public var totp: String?

    /// The list of uri's for the login.
    public var uris: [LoginUriDTO]?

    /// The login associated with the username.
    public var username: String?

    // MARK: Initialization

    /// Initializes a `LoginDTO`,
    ///
    /// - Parameters:
    ///   - totp: The totp code for the login.
    ///   - uris: The list of uri's for the login.
    ///   - username: The login associated with the username.
    ///
    public init(
        totp: String? = nil,
        uris: [LoginUriDTO]? = nil,
        username: String? = nil
    ) {
        self.totp = totp
        self.uris = uris
        self.username = username
    }
}

// MARK: - LoginUriDTO

/// The simplified login uri used to communicate between the watch and the main app.
///
public struct LoginUriDTO: Codable {
    // MARK: Properties

    /// The uri of the login.
    public var uri: String?

    // MARK: Initialization

    /// Initializes a `LoginUriDTO`,
    ///
    /// - Parameter uri:  The uri of the login.
    ///
    public init(uri: String? = nil) {
        self.uri = uri
    }
}
