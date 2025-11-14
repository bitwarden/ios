import Foundation

// MARK: - SharedKeychainService

/// A Service to provide a wrapper around the device keychain shared via App Group between
/// the Authenticator and the main Bitwarden app.
///
public protocol SharedKeychainService: AnyObject {
    /// Adds a set of attributes.
    ///
    /// - Parameter attributes: Attributes to add.
    ///
    func add(attributes: CFDictionary) throws

    /// Attempts a deletion based on a query.
    ///
    /// - Parameter query: Query for the delete.
    ///
    func delete(query: CFDictionary) throws

    /// Searches for a query.
    ///
    /// - Parameter query: Query for the search.
    /// - Returns: The search results.
    ///
    func search(query: CFDictionary) throws -> AnyObject?
}

// MARK: - SharedKeychainServiceError

/// Enum with possible error cases that can be thrown from `SharedKeychainService`.
public enum SharedKeychainServiceError: Error, Equatable, CustomNSError, Sendable {
    /// When a `KeychainService` is unable to locate an auth key for a given storage key.
    ///
    /// - Parameter KeychainItem: The potential storage key for the auth key.
    ///
    case keyNotFound(SharedKeychainItem)

    /// The user-info dictionary.
    public var errorUserInfo: [String: Any] {
        switch self {
        case let .keyNotFound(keychainItem):
            ["Keychain Item": keychainItem.unformattedKey]
        }
    }
}
