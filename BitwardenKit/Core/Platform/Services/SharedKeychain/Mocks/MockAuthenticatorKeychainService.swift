import Foundation

@testable import BitwardenKit

public class MockAuthenticatorKeychainService {
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
    public func add(attributes: CFDictionary) throws {
        addAttributes = attributes
        try addResult.get()
    }

    public func delete(query: CFDictionary) throws {
        deleteQueries.append(query)
        try deleteResult.get()
    }

    public func search(query: CFDictionary) throws -> AnyObject? {
        searchQuery = query
        return try searchResult.get()
    }
}

extension MockAuthenticatorKeychainService {
    public func setSearchResultData(_ data: Data) {
        let dictionary = [kSecValueData as String: data]
        searchResult = .success(dictionary as AnyObject)
    }
}
