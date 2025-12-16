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

// MARK: - KeychainServiceError

enum KeychainServiceError: Error, Equatable, CustomNSError {
    /// When creating an accessControl fails.
    ///
    /// - Parameter CFError: The potential system error.
    ///
    case accessControlFailed(CFError?)

    /// When a `KeychainService` is unable to locate an auth key for a given storage key.
    ///
    /// - Parameter KeychainItem: The potential storage key for the auth key.
    ///
    case keyNotFound(any KeychainStorageKeyPossessing)

    /// A passthrough for OSService Error cases.
    ///
    /// - Parameter OSStatus: The `OSStatus` returned from a keychain operation.
    ///
    case osStatusError(OSStatus)

    /// The user-info dictionary.
    var errorUserInfo: [String: Any] {
        switch self {
        case .accessControlFailed:
            [:]
        case let .keyNotFound(keychainItem):
            ["Keychain Item": keychainItem.unformattedKey]
        case let .osStatusError(osStatus):
            ["OS Status": osStatus]
        }
    }

    // MARK: Equatable

    static func == (lhs: KeychainServiceError, rhs: KeychainServiceError) -> Bool {
        switch (lhs, rhs) {
        case let (.accessControlFailed(lError), .accessControlFailed(rError)):
            lError == rError
        case let (.keyNotFound(lKey), .keyNotFound(rKey)):
            lKey.unformattedKey == rKey.unformattedKey
        case let (.osStatusError(lStatus), .osStatusError(rStatus)):
            lStatus == rStatus
        default:
            false
        }
    }
}

protocol KeychainStorageKeyPossessing: Equatable {
    /// A keychain storage key that can be used for this object.
    var unformattedKey: String { get }
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
