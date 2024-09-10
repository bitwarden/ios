import Foundation

@testable import AuthenticatorSyncShared

class MockAuthenticatorKeychainService {
    // MARK: Properties

    var addAttributes: CFDictionary?
    var addResult: Result<Void, AuthenticatorKeychainServiceError> = .success(())
    var deleteQueries = [CFDictionary]()
    var deleteResult: Result<Void, AuthenticatorKeychainServiceError> = .success(())
    var searchQuery: CFDictionary?
    var searchResult: Result<AnyObject?, AuthenticatorKeychainServiceError> = .success(nil)
}

// MARK: KeychainService

extension MockAuthenticatorKeychainService: AuthenticatorKeychainService {
    func add(attributes: CFDictionary) throws {
        addAttributes = attributes
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
}

extension MockAuthenticatorKeychainService {
    func setSearchResultData(_ data: Data) {
        let dictionary = [kSecValueData as String: data]
        searchResult = .success(dictionary as AnyObject)
    }
}
