import Foundation

// MARK: - KeychainItem

/// A protocol for an object that can provide information to store/retrieve data in the keychain.
public protocol KeychainItem: Equatable { // sourcery: AutoMockable
    /// The `SecAccessControlCreateFlags` level for this keychain item.
    /// If `nil`, no extra protection is applied.
    ///
    var accessControlFlags: SecAccessControlCreateFlags? { get }

    /// The protection level for this keychain item.
    var protection: CFTypeRef { get }

    /// The keychain storage key for this item.
    var unformattedKey: String { get }
}
