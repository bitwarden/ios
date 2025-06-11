import AuthenticatorBridgeKit
import Foundation

public class MockSharedKeychainService: SharedKeychainService {
    // MARK: Properties

    public var addAttributes: CFDictionary?
    public var addResult: Result<Void, SharedKeychainServiceError> = .success(())
    public var deleteQueries = [CFDictionary]()
    public var deleteResult: Result<Void, SharedKeychainServiceError> = .success(())
    public var searchQuery: CFDictionary?
    public var searchResult: Result<AnyObject?, SharedKeychainServiceError> = .success(nil)

    public init() {}

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

    public func setSearchResultData(_ data: Data) {
        let dictionary = [kSecValueData as String: data]
        searchResult = .success(dictionary as AnyObject)
    }
}
