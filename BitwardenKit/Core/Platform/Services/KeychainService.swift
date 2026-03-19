import Foundation

// MARK: - KeychainService

/// A Service to provide a wrapper around the device Keychain.
///
public protocol KeychainService: AnyObject {
    /// Creates an access control for a given set of flags.
    ///
    /// - Parameters:
    ///   - protection: Protection class to be used for the item. Use one of the values that go with the
    ///     `kSecAttrAccessible` attribute key.
    ///   - flags: The `SecAccessControlCreateFlags` for the access control.
    /// - Returns: The SecAccessControl.
    ///
    func accessControl(
        protection: CFTypeRef,
        for flags: SecAccessControlCreateFlags,
    ) throws -> SecAccessControl

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

    /// Updates an existing keychain item.
    ///
    /// - Parameters:
    ///   - query: Query to identify the item to update.
    ///   - attributes: New attributes to set.
    ///
    func update(query: CFDictionary, attributes: CFDictionary) throws
}
