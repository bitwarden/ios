import Foundation

/// A struct for storing **encrypted** information about items that are shared between the Bitwarden
/// and Authenticator apps.
///
public struct AuthenticatorBridgeItemDataModel: Codable, Equatable {
    // MARK: Properties

    /// Bool indicating if this item is a favorite.
    public let favorite: Bool

    /// The unique id of the item.
    public let id: String

    /// The name of the item.
    public let name: String

    /// The TOTP key used to generate codes.
    public let totpKey: String?

    /// The username of the Bitwarden account that owns this iteam.
    public let username: String?
}
