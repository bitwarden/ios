import BitwardenKit
import Foundation

@testable import BitwardenShared

class MockKeychainService {
    // MARK: Properties

    var accessControlFlags: SecAccessControlCreateFlags?
    var accessControlProtection: CFTypeRef?
    var accessControlResult: Result<SecAccessControl, KeychainServiceError> = .failure(.accessControlFailed(nil))
    var addAttributes: CFDictionary?
    var addCalls = [CFDictionary]()
    var addResult: Result<Void, KeychainServiceError> = .success(())
    var deleteQueries = [CFDictionary]()
    var deleteResult: Result<Void, KeychainServiceError> = .success(())
    var searchQuery: CFDictionary?
    var searchResult: Result<AnyObject?, KeychainServiceError> = .success(nil)
    var updateAttributes: CFDictionary?
    var updateQuery: CFDictionary?
    var updateResult: Result<Void, Error> = .failure(KeychainServiceError.osStatusError(errSecItemNotFound))
}

// MARK: KeychainService

extension MockKeychainService: KeychainService {
    func accessControl(protection: CFTypeRef, for flags: SecAccessControlCreateFlags) throws -> SecAccessControl {
        accessControlFlags = flags
        accessControlProtection = protection
        return try accessControlResult.get()
    }

    func add(attributes: CFDictionary) throws {
        addAttributes = attributes
        addCalls.append(attributes)
        try addResult.get()
    }

    func delete(query: CFDictionary) throws {
        deleteQueries.append(query)
        try deleteResult.get()
    }

    func search(query: CFDictionary) throws -> AnyObject? {
        searchQuery = query
        return try searchResult.get()
    }

    func update(query: CFDictionary, attributes: CFDictionary) throws {
        updateQuery = query
        updateAttributes = attributes
        try updateResult.get()
    }
}

extension MockKeychainService {
    func setSearchResultData(string: String) {
        let dictionary = [kSecValueData as String: Data(string.utf8)]
        searchResult = .success(dictionary as AnyObject)
    }
}
