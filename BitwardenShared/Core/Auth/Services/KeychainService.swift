import AuthenticatorSyncKit
import Foundation

// MARK: - KeychainService

/// A Service to provide a wrapper around the device Keychain.
///
protocol KeychainService: AnyObject {
    /// Creates an access control for a given set of flags.
    ///
    /// - Parameter flags: The `SecAccessControlCreateFlags` for the access control.
    /// - Returns: The SecAccessControl.
    ///
    func accessControl(
        for flags: SecAccessControlCreateFlags
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

// MARK: - KeychainServiceError

enum KeychainServiceError: Error, Equatable {
    /// When creating an accessControl fails.
    ///
    /// - Parameter CFError: The potential system error.
    ///
    case accessControlFailed(CFError?)

    /// When a `KeychainService` is unable to locate an auth key for a given storage key.
    ///
    /// - Parameter KeychainItem: The potential storage key for the auth key.
    ///
    case keyNotFound(KeychainItem)

    /// A passthrough for OSService Error cases.
    ///
    /// - Parameter OSStatus: The `OSStatus` returned from a keychain operation.
    ///
    case osStatusError(OSStatus)
}

// MARK: - DefaultKeychainService

class DefaultKeychainService: KeychainService {
    // MARK: Methods

    func accessControl(
        for flags: SecAccessControlCreateFlags
    ) throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            flags,
            &error
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

// MARK: - AuthenticatorKeychainService

extension DefaultKeychainService: AuthenticatorKeychainService {}
