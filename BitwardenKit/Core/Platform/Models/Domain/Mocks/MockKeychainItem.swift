import BitwardenKit
import Foundation

extension MockKeychainItem: Equatable {
    public convenience init(
        unformattedKey: String,
        accessControlFlags: SecAccessControlCreateFlags? = nil,
        protection: CFTypeRef = kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
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
