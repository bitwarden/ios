import BitwardenResources
import BitwardenSdk

/// A protocol to be used by vault list items that have decorative icons.
protocol VaultItemWithDecorativeIcon {
    /// An image asset for this item that can be used in the UI.
    var icon: SharedImageAsset { get }

    /// The accessibility ID for the ciphers icon.
    var iconAccessibilityId: String { get }

    /// The cipher's data view to be used for decorative icons.
    var cipherDecorativeIconDataView: CipherDecorativeIconDataView? { get }

    /// Whether the placeholder needs a custom content view to be shown.
    var shouldUseCustomPlaceholderContent: Bool { get }
}

extension VaultItemWithDecorativeIcon {
    var shouldUseCustomPlaceholderContent: Bool {
        false
    }
}
