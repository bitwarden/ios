import AuthenticatorBridgeKit
import Foundation

public class MockSharedKeychainStorage: SharedKeychainStorage {
    public var storage = [SharedKeychainItem: any Codable]()

    public init() {}

    public func deleteValue(for item: SharedKeychainItem) async throws {
        storage[item] = nil
    }

    public func getValue<T>(for item: SharedKeychainItem) async throws -> T where T: Codable {
        guard let stored = storage[item] as? T else {
            throw SharedKeychainServiceError.keyNotFound(item)
        }
        return stored
    }

    public func setValue<T>(_ value: T, for item: SharedKeychainItem) async throws where T: Codable {
        storage[item] = value
    }
}
