import Foundation

// MARK: - AuthenticatorKeychainService

/// A Service to provide a wrapper around the device keychain shared via App Group between
/// the Authenticator and the main Bitwarden app.
///
public protocol AuthenticatorKeychainService: AnyObject {
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
    /// - Parameter query: Query for the delete.
    /// - Returns: The search results.
    ///
    func search(query: CFDictionary) throws -> AnyObject?
}

// MARK: - AuthenticatorKeychainServiceError

/// Enum with possible error cases that can be thrown from `AuthenticatorKeychainService`.
public enum AuthenticatorKeychainServiceError: Error, Equatable {
    /// When a `KeychainService` is unable to locate an auth key for a given storage key.
    ///
    /// - Parameter KeychainItem: The potential storage key for the auth key.
    ///
    case keyNotFound(SharedKeychainItem)
}
