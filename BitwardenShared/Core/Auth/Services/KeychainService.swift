import AuthenticatorBridgeKit
import BitwardenKit
import Foundation

// MARK: - KeychainService

/// A Service to provide a wrapper around the device Keychain.
///
protocol KeychainService: AnyObject {
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
}

// MARK: - DefaultKeychainService

class DefaultKeychainService: KeychainService {
    // MARK: Methods

    func accessControl(
        protection: CFTypeRef,
        for flags: SecAccessControlCreateFlags,
    ) throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            protection,
            flags,
            &error,
        )

        guard let accessControl,
              error == nil
        else {
            throw KeychainServiceError.accessControlFailed(error?.takeUnretainedValue())
        }
        return accessControl
    }

    func add(attributes: CFDictionary) throws {
        try resolve(SecItemAdd(attributes, nil))
    }

    func delete(query: CFDictionary) throws {
        let status = SecItemDelete(query)
        guard [errSecSuccess, errSecItemNotFound].contains(status) else {
            throw KeychainServiceError.osStatusError(status)
        }
    }

    func search(query: CFDictionary) throws -> AnyObject? {
        var foundItem: AnyObject?
        try resolve(SecItemCopyMatching(query, &foundItem))
        return foundItem
    }

    func update(query: CFDictionary, attributes: CFDictionary) throws {
        try resolve(SecItemUpdate(query, attributes))
    }

    // MARK: Private Methods

    /// Ensures that a given status is a success.
    ///     Throws if not `errSecSuccess`.
    ///
    /// - Parameter status: The OSStatus to check.
    ///
    private func resolve(_ status: OSStatus) throws {
        switch status {
        case errSecSuccess:
            break
        default:
            throw KeychainServiceError.osStatusError(status)
        }
    }
}

// MARK: - SharedKeychainService

extension DefaultKeychainService: SharedKeychainService {}
