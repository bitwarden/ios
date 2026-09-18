import BitwardenKit
import Foundation

// MARK: - PasskeyKeychainItem

/// The keychain items used by the SDK-backed passkey scenarios.
///
enum PasskeyKeychainItem: Equatable, KeychainItem {
    /// The keychain item for the synthetic identity used to bootstrap the SDK client, so the
    /// same identity — and therefore the same crypto keys — can be reconstructed across app
    /// launches.
    case syntheticIdentity

    /// The `SecAccessControlCreateFlags` protection level for this keychain item. No extra
    /// protection is needed since this is throwaway, synthetic identity material with no real
    /// security value.
    ///
    var accessControlFlags: SecAccessControlCreateFlags? { nil }

    /// The protection level for this keychain item.
    var protection: CFTypeRef { kSecAttrAccessibleWhenUnlockedThisDeviceOnly }

    /// The storage key for this keychain item.
    ///
    var unformattedKey: String {
        switch self {
        case .syntheticIdentity:
            "sdkPasskeySyntheticIdentity"
        }
    }
}
