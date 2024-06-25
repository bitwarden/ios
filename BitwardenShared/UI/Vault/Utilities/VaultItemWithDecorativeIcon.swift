import BitwardenSdk

/// A protocol to be used by vault list items that have decorative icons.
protocol VaultItemWithDecorativeIcon {
    /// An image asset for this item that can be used in the UI.
    var icon: ImageAsset { get }

    /// The accessibility ID for the ciphers icon.
    var iconAccessibilityId: String { get }

    /// The login view containing the uri's to download the special decorative icon, if applicable.
    var loginView: BitwardenSdk.LoginView? { get }
}
