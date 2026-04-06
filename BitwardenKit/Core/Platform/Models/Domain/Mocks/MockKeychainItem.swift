import BitwardenKit
import Foundation

extension MockKeychainItem: Equatable {
    public convenience init(
        accessControlFlags: SecAccessControlCreateFlags? = nil,
        protection: CFTypeRef = kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        unformattedKey: String = "test_key",
    ) {
        self.init()
        self.accessControlFlags = accessControlFlags
        self.protection = protection
        self.unformattedKey = unformattedKey
    }

    public static func == (
        lhs: MockKeychainItem,
        rhs: MockKeychainItem,
    ) -> Bool {
        lhs.accessControlFlags == rhs.accessControlFlags
            && CFEqual(lhs.protection, rhs.protection)
            && lhs.unformattedKey == rhs.unformattedKey
    }
}
