import BitwardenKit
import Foundation

/// A mock implementation of `KeychainService` for testing purposes.
///
/// This mock allows you to control the behavior and results of keychain operations,
/// and inspect the parameters passed to each method call.
public class MockKeychainService {
    // MARK: Properties

    /// The flags captured from the most recent `accessControl(protection:for:)` call.
    public var accessControlFlags: SecAccessControlCreateFlags?

    /// The protection level captured from the most recent `accessControl(protection:for:)` call.
    public var accessControlProtection: CFTypeRef?

    /// The result to return from `accessControl(protection:for:)` calls.
    /// Defaults to a failure with `.accessControlFailed(nil)`.
    public var accessControlResult: Result<SecAccessControl, KeychainServiceError> = .failure(.accessControlFailed(nil))

    /// The attributes dictionary captured from the most recent `add(attributes:)` call.
    public var addAttributes: CFDictionary?

    /// An array of all attributes dictionaries passed to `add(attributes:)` calls.
    public var addCalls = [CFDictionary]()

    /// The result to return from `add(attributes:)` calls.
    /// Defaults to success.
    public var addResult: Result<Void, KeychainServiceError> = .success(())

    /// An array of all query dictionaries passed to `delete(query:)` calls.
    public var deleteQueries = [CFDictionary]()

    /// The result to return from `delete(query:)` calls.
    /// Defaults to success.
    public var deleteResult: Result<Void, KeychainServiceError> = .success(())

    /// The query dictionary captured from the most recent `search(query:)` call.
    public var searchQuery: CFDictionary?

    /// The result to return from `search(query:)` calls.
    /// Defaults to `nil` (no results found).
    public var searchResult: Result<AnyObject?, KeychainServiceError> = .success(nil)

    /// The attributes dictionary captured from the most recent `update(query:attributes:)` call.
    public var updateAttributes: CFDictionary?

    /// The query dictionary captured from the most recent `update(query:attributes:)` call.
    public var updateQuery: CFDictionary?

    /// The result to return from `update(query:attributes:)` calls.
    /// Defaults to failure with `errSecItemNotFound`.
    public var updateResult: Result<Void, Error> = .failure(KeychainServiceError.osStatusError(errSecItemNotFound))

    /// Initializes a new mock keychain service with default values.
    public init() {}
}

// MARK: KeychainService

extension MockKeychainService: KeychainService {
    /// Creates a `SecAccessControl` object with the specified protection level and flags.
    ///
    /// This mock implementation captures the parameters and returns the value from `accessControlResult`.
    ///
    /// - Parameters:
    ///   - protection: The protection level for the access control.
    ///   - flags: The flags defining when the keychain item can be accessed.
    /// - Returns: A `SecAccessControl` object as configured in `accessControlResult`.
    /// - Throws: A `KeychainServiceError` if `accessControlResult` is set to a failure.
    public func accessControl(
        protection: CFTypeRef,
        for flags: SecAccessControlCreateFlags,
    ) throws -> SecAccessControl {
        accessControlFlags = flags
        accessControlProtection = protection
        return try accessControlResult.get()
    }

    /// Adds a new item to the keychain with the specified attributes.
    ///
    /// This mock implementation captures the attributes and appends them to `addCalls`.
    ///
    /// - Parameter attributes: A dictionary containing the attributes for the keychain item.
    /// - Throws: A `KeychainServiceError` if `addResult` is set to a failure.
    public func add(attributes: CFDictionary) throws {
        addAttributes = attributes
        addCalls.append(attributes)
        try addResult.get()
    }

    /// Deletes keychain items matching the specified query.
    ///
    /// This mock implementation captures the query and appends it to `deleteQueries`.
    ///
    /// - Parameter query: A dictionary specifying the items to delete.
    /// - Throws: A `KeychainServiceError` if `deleteResult` is set to a failure.
    public func delete(query: CFDictionary) throws {
        deleteQueries.append(query)
        try deleteResult.get()
    }

    /// Searches for keychain items matching the specified query.
    ///
    /// This mock implementation captures the query and returns the value from `searchResult`.
    ///
    /// - Parameter query: A dictionary specifying the search criteria.
    /// - Returns: The keychain item data as configured in `searchResult`, or `nil` if not found.
    /// - Throws: A `KeychainServiceError` if `searchResult` is set to a failure.
    public func search(query: CFDictionary) throws -> AnyObject? {
        searchQuery = query
        return try searchResult.get()
    }

    /// Updates keychain items matching the specified query with new attributes.
    ///
    /// This mock implementation captures both the query and attributes.
    ///
    /// - Parameters:
    ///   - query: A dictionary specifying which items to update.
    ///   - attributes: A dictionary containing the new attributes.
    /// - Throws: An error if `updateResult` is set to a failure.
    public func update(query: CFDictionary, attributes: CFDictionary) throws {
        updateQuery = query
        updateAttributes = attributes
        try updateResult.get()
    }
}

public extension MockKeychainService {
    /// Configures `searchResult` to return a dictionary containing string data.
    ///
    /// This is a convenience method for setting up common test scenarios where you want
    /// the keychain search to return string data. The data is stored in a dictionary
    /// with the `kSecValueData` key.
    ///
    /// - Parameter string: The string to return from search operations.
    func setSearchResultData(_ data: Data) {
        let dictionary = [kSecValueData as String: data]
        searchResult = .success(dictionary as AnyObject)
    }

    /// Configures `searchResult` to return a dictionary containing string data.
    ///
    /// This is a convenience method for setting up common test scenarios where you want
    /// the keychain search to return string data. The string is converted to `Data` and
    /// stored in a dictionary with the `kSecValueData` key.
    ///
    /// - Parameter string: The string to return from search operations.
    func setSearchResultData(string: String) {
        let dictionary = [kSecValueData as String: Data(string.utf8)]
        searchResult = .success(dictionary as AnyObject)
    }
}
