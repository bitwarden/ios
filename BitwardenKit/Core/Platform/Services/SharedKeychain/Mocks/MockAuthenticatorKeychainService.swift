import Foundation

@testable import BitwardenKit

public class MockAuthenticatorKeychainService {
    // MARK: Properties

    public var addAttributes: CFDictionary?
    public var addResult: Result<Void, AuthenticatorKeychainServiceError> = .success(())
    public var deleteQueries = [CFDictionary]()
    public var deleteResult: Result<Void, AuthenticatorKeychainServiceError> = .success(())
    public var searchQuery: CFDictionary?
    public var searchResult: Result<AnyObject?, AuthenticatorKeychainServiceError> = .success(nil)

    public init() {}
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
