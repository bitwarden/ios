import Foundation

/// A struct for storing **encrypted** information about items that are shared between the Bitwarden
/// and Authenticator apps.
///
public struct AuthenticatorBridgeItemDataModel: Codable, Equatable {
    // MARK: Properties

    /// The domain of the Bitwarden account that owns this item. (e.g. https://vault.bitwarden.com)
    public let bitwardenAccountDomain: String?

    /// The email of the Bitwarden account that owns this item.
    public let bitwardenAccountEmail: String?

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
}
