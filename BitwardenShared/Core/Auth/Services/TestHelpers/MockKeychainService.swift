import Foundation

@testable import BitwardenShared

class MockKeychainService {
    // MARK: Properties

    var accessControlFlags: SecAccessControlCreateFlags?
    var accessControlResult: Result<SecAccessControl, KeychainServiceError> = .failure(.accessControlFailed(nil))
    var addAttributes: CFDictionary?
    var addResult: Result<Void, KeychainServiceError> = .success(())
    var deleteQuery: CFDictionary?
    var deleteResult: Result<Void, KeychainServiceError> = .success(())
    var searchQuery: CFDictionary?
    var searchResult: Result<AnyObject?, KeychainServiceError> = .success(nil)
}

// MARK: KeychainService

extension MockKeychainService: KeychainService {
    func accessControl(for flags: SecAccessControlCreateFlags) throws -> SecAccessControl {
        accessControlFlags = flags
        return try accessControlResult.get()
    }

    func add(attributes: CFDictionary) throws {
        addAttributes = attributes
        try addResult.get()
    }

    func delete(query: CFDictionary) throws {
        deleteQuery = query
        try deleteResult.get()
    }

    func search(query: CFDictionary) throws -> AnyObject? {
        searchQuery = query
        return try searchResult.get()
    }
}

extension MockKeychainService {
    func setSearchResultData(string: String) {
        let dictionary = [kSecValueData as String: Data(string.utf8)]
        searchResult = .success(dictionary as AnyObject)
    }
}
