import BitwardenKit

extension MockKeychainStorageKeyPossessing: Equatable {
    public static func == (
        lhs: MockKeychainStorageKeyPossessing,
        rhs: MockKeychainStorageKeyPossessing
    ) -> Bool {
        lhs.unformattedKey == rhs.unformattedKey
    }
}
