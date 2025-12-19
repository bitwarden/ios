import BitwardenKit

extension MockKeychainStorageKeyPossessing: Equatable {
    public convenience init(unformattedKey: String) {
        self.init()
        self.unformattedKey = unformattedKey
    }

    public static func == (
        lhs: MockKeychainStorageKeyPossessing,
        rhs: MockKeychainStorageKeyPossessing,
    ) -> Bool {
        lhs.unformattedKey == rhs.unformattedKey
    }
}
