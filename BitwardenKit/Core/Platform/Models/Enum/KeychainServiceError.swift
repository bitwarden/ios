import Foundation

// MARK: - KeychainStorageKeyPossessing

/// A protocol for an object that can provide a keychain storage key.
public protocol KeychainStorageKeyPossessing: Equatable { // sourcery: AutoMockable
    /// A keychain storage key that can be used for this object.
    var unformattedKey: String { get }
}

// MARK: - KeychainServiceError

/// An error that can be thrown from a keychain service indicating an issue when
/// interacting with the keychain.
///
public enum KeychainServiceError: Error, Equatable, CustomNSError {
    /// When creating an accessControl fails.
    ///
    /// - Parameters:
    ///   - CFError: The potential system error.
    ///
    case accessControlFailed(CFError?)

    /// When a `KeychainService` is unable to locate a value for a given storage key.
    ///
    /// - Parameters:
    ///   - KeychainStorageKeyPossessing: The storage key for the value.
    ///
    case keyNotFound(any KeychainStorageKeyPossessing)

    /// A passthrough for OSService Error cases.
    ///
    /// - Parameters:
    ///   - OSStatus: The `OSStatus` returned from a keychain operation.
    ///
    case osStatusError(OSStatus)

    /// The user-info dictionary.
    public var errorUserInfo: [String: Any] {
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

    public static func == (lhs: KeychainServiceError, rhs: KeychainServiceError) -> Bool {
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
