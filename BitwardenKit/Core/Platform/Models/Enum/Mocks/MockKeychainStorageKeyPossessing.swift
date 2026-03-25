import BitwardenKit

extension MockKeychainItem: Equatable {
    public convenience init(unformattedKey: String) {
        self.init()
        self.unformattedKey = unformattedKey
    }

    public static func == (
        lhs: MockKeychainItem,
        rhs: MockKeychainItem,
    ) -> Bool {
        lhs.unformattedKey == rhs.unformattedKey
    }
}
