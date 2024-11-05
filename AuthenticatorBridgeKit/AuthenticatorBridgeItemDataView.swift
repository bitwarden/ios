import Foundation

/// A struct for storing **unencrypted** information about items that are shared between the Bitwarden
/// and Authenticator apps.
///
public struct AuthenticatorBridgeItemDataView: Codable, Equatable {
    // MARK: Properties

    /// The domain of the Bitwarden account that owns this item. (e.g. https://vault.bitwarden.com)
    public let accountDomain: String?

    /// The email of the Bitwarden account that owns this item.
    public let accountEmail: String?

    /// Bool indicating if this item is a favorite.
    public let favorite: Bool

    /// The unique id of the item.
    public let id: String

    /// The name of the item.
    public let name: String

    /// The TOTP key used to generate codes.
    public let totpKey: String?

    /// The username of the item.
    public let username: String?

    /// Initialize an `AuthenticatorBridgeItemDataView` with the values provided.
    ///
    /// - Parameters:
    ///   - accountDomain: The domain of the Bitwarden account that owns this item.
    ///   - accountEmail: The email of the Bitwarden account that owns this item
    ///   - favorite: Bool indicating if this item is a favorite.
    ///   - id: The unique id of the item.
    ///   - name: The name of the item.
    ///   - totpKey: The TOTP key used to generate codes.
    ///   - username: The username of the item.
    ///
    public init(accountDomain: String?,
                accountEmail: String?,
                favorite: Bool,
                id: String,
                name: String,
                totpKey: String?,
                username: String?) {
        self.accountDomain = accountDomain
        self.accountEmail = accountEmail
        self.favorite = favorite
        self.id = id
        self.name = name
        self.totpKey = totpKey
        self.username = username
    }
}
