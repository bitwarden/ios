import BitwardenKit
import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared

struct LocalUserDataKeychainRepositoryTests {
    // MARK: Properties

    let keychainServiceFacade: MockKeychainServiceFacade
    let subject: DefaultKeychainRepository

    // MARK: Setup

    init() {
        keychainServiceFacade = MockKeychainServiceFacade()
        subject = DefaultKeychainRepository(
            keychainService: MockKeychainService(),
            keychainServiceFacade: keychainServiceFacade,
        )
    }

    // MARK: Tests - clearLocalUserDataKeyStates

    /// `clearLocalUserDataKeyStates(userId:)` deletes the stored states via the facade.
    ///
    @Test
    func clearLocalUserDataKeyStates_deletesItem() async throws {
        try await subject.clearLocalUserDataKeyStates(userId: "1")

        let receivedUnformattedKey = keychainServiceFacade.deleteValueReceivedItem?.unformattedKey
        let expectedUnformattedKey = BitwardenKeychainItem.localUserDataKeyStates(userId: "1").unformattedKey
        #expect(receivedUnformattedKey == expectedUnformattedKey)
    }

    /// `clearLocalUserDataKeyStates(userId:)` rethrows errors from the facade.
    ///
    @Test
    func clearLocalUserDataKeyStates_error_rethrows() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainServiceFacade.deleteValueThrowableError = error

        await #expect(throws: error) {
            try await subject.clearLocalUserDataKeyStates(userId: "1")
        }
    }

    // MARK: Tests - getLocalUserDataKeyStates

    /// `getLocalUserDataKeyStates(userId:)` returns decoded states from the facade.
    ///
    @Test
    func getLocalUserDataKeyStates_success() async throws {
        let expected: [String: UserKeyData] = ["key1": UserKeyData(wrappedKey: "encKey1")]
        let jsonData = try JSONEncoder.defaultEncoder.encode(expected)
        keychainServiceFacade.getValueReturnValue = String(data: jsonData, encoding: .utf8)

        let result = try await subject.getLocalUserDataKeyStates(userId: "1")
        let receivedUnformattedKey = keychainServiceFacade.getValueReceivedItem?.unformattedKey
        let expectedUnformattedKey = BitwardenKeychainItem.localUserDataKeyStates(userId: "1").unformattedKey

        #expect(result == expected)
        #expect(receivedUnformattedKey == expectedUnformattedKey)
    }

    /// `getLocalUserDataKeyStates(userId:)` returns nil when the OS status indicates not found.
    ///
    @Test
    func getLocalUserDataKeyStates_osStatusNotFound_returnsNil() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        let result = try await subject.getLocalUserDataKeyStates(userId: "1")

        #expect(result == nil)
    }

    /// `getLocalUserDataKeyStates(userId:)` returns nil when the key is not found.
    ///
    @Test
    func getLocalUserDataKeyStates_keyNotFound_returnsNil() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.localUserDataKeyStates(userId: "1"),
        )

        let result = try await subject.getLocalUserDataKeyStates(userId: "1")

        #expect(result == nil)
    }

    /// `getLocalUserDataKeyStates(userId:)` rethrows unexpected errors.
    ///
    @Test
    func getLocalUserDataKeyStates_otherError_rethrows() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainServiceFacade.getValueThrowableError = error

        await #expect(throws: error) {
            _ = try await subject.getLocalUserDataKeyStates(userId: "1")
        }
    }

    // MARK: Tests - mutateLocalUserDataKeyStates

    /// `mutateLocalUserDataKeyStates(userId:_:)` applies the transform to existing states and stores the result.
    ///
    @Test
    func mutateLocalUserDataKeyStates_transformsExistingStates() async throws {
        let initial: [String: UserKeyData] = ["key1": UserKeyData(wrappedKey: "encKey1")]
        let jsonData = try JSONEncoder.defaultEncoder.encode(initial)
        keychainServiceFacade.getValueReturnValue = String(data: jsonData, encoding: .utf8)

        try await subject.mutateLocalUserDataKeyStates(userId: "1") { states in
            states["key2"] = UserKeyData(wrappedKey: "encKey2")
        }

        let storedJSON = try #require(keychainServiceFacade.setValueReceivedArguments?.value)
        let stored = try JSONDecoder.defaultDecoder.decode(
            [String: UserKeyData].self,
            from: #require(storedJSON.data(using: .utf8)),
        )
        #expect(stored["key1"] == UserKeyData(wrappedKey: "encKey1"))
        #expect(stored["key2"] == UserKeyData(wrappedKey: "encKey2"))
    }

    /// `mutateLocalUserDataKeyStates(userId:_:)` starts with an empty dict when no states are stored.
    ///
    @Test
    func mutateLocalUserDataKeyStates_noExistingStates_startsEmpty() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.localUserDataKeyStates(userId: "1"),
        )

        try await subject.mutateLocalUserDataKeyStates(userId: "1") { states in
            states["key1"] = UserKeyData(wrappedKey: "encKey1")
        }

        let storedJSON = try #require(keychainServiceFacade.setValueReceivedArguments?.value)
        let stored = try JSONDecoder.defaultDecoder.decode(
            [String: UserKeyData].self,
            from: #require(storedJSON.data(using: .utf8)),
        )
        #expect(stored == ["key1": UserKeyData(wrappedKey: "encKey1")])
    }

    /// `mutateLocalUserDataKeyStates(userId:_:)` deletes the keychain item when the transform produces an empty dict.
    ///
    @Test
    func mutateLocalUserDataKeyStates_emptyResultAfterTransform_deletesItem() async throws {
        let initial: [String: UserKeyData] = ["key1": UserKeyData(wrappedKey: "encKey1")]
        let jsonData = try JSONEncoder.defaultEncoder.encode(initial)
        keychainServiceFacade.getValueReturnValue = String(data: jsonData, encoding: .utf8)

        try await subject.mutateLocalUserDataKeyStates(userId: "1") { states in
            states.removeAll()
        }

        let receivedUnformattedKey = keychainServiceFacade.deleteValueReceivedItem?.unformattedKey
        let expectedUnformattedKey = BitwardenKeychainItem.localUserDataKeyStates(userId: "1").unformattedKey
        #expect(receivedUnformattedKey == expectedUnformattedKey)
        #expect(!keychainServiceFacade.setValueCalled)
    }

    /// `mutateLocalUserDataKeyStates(userId:_:)` rethrows errors from getting the current states.
    ///
    @Test
    func mutateLocalUserDataKeyStates_getError_rethrows() async {
        let error = KeychainServiceError.osStatusError(-1)
        keychainServiceFacade.getValueThrowableError = error

        await #expect(throws: error) {
            try await subject.mutateLocalUserDataKeyStates(userId: "1") { _ in }
        }
    }

    /// `mutateLocalUserDataKeyStates(userId:_:)` rethrows errors from storing the updated states.
    ///
    @Test
    func mutateLocalUserDataKeyStates_setError_rethrows() async {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.localUserDataKeyStates(userId: "1"),
        )
        let error = KeychainServiceError.osStatusError(-1)
        keychainServiceFacade.setValueThrowableError = error

        await #expect(throws: error) {
            try await subject.mutateLocalUserDataKeyStates(userId: "1") { states in
                states["key1"] = UserKeyData(wrappedKey: "encKey1")
            }
        }
    }
}
