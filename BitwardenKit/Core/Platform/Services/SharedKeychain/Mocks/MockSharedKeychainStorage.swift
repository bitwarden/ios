import BitwardenKit
import Foundation

public class MockSharedKeychainStorage: SharedKeychainStorage {
    public var storage = [SharedKeychainItem: Data]()

    public init() {}

    public func deleteValue(for item: SharedKeychainItem) async throws {
        storage[item] = nil
    }
    
    public func getValue(for item: SharedKeychainItem) async throws -> Data {
        guard let stored = storage[item] else {
            throw AuthenticatorKeychainServiceError.keyNotFound(item)
        }
        return stored
    }

    public func setValue(_ value: Data, for item: SharedKeychainItem) async throws {
        storage[item] = value
    }
}
