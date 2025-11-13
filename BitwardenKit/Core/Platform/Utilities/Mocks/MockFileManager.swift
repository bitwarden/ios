import Foundation

@testable import BitwardenKit

public class MockFileManager: FileManagerProtocol {
    public var appendDataData: Data?
    public var appendDataResult: Result<Void, Error> = .success(())
    public var appendDataURL: URL?

    public var attributesOfItemPath: String?
    public var attributesOfItemResult: Result<[FileAttributeKey: Any], Error> = .success([:])

    public var createDirectoryURL: URL?
    public var createDirectoryCreateIntermediates: Bool?
    public var createDirectoryResult: Result<Void, Error> = .success(())

    public var removeItemURLs = [URL]()
    public var removeItemResult: Result<Void, Error> = .success(())

    public var setIsExcludedFromBackupValue: Bool?
    public var setIsExcludedFromBackupURL: URL?
    public var setIsExcludedFromBackupResult: Result<Void, Error> = .success(())

    public var writeDataData: Data?
    public var writeDataURL: URL?
    public var writeDataResult: Result<Void, Error> = .success(())

    public init() {}

    public func append(_ data: Data, to url: URL) throws {
        appendDataData = data
        appendDataURL = url
        try appendDataResult.get()
    }

    public func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        attributesOfItemPath = path
        return try attributesOfItemResult.get()
    }

    public func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws {
        createDirectoryURL = url
        createDirectoryCreateIntermediates = createIntermediates
        try createDirectoryResult.get()
    }

    public func removeItem(at url: URL) throws {
        removeItemURLs.append(url)
        try removeItemResult.get()
    }

    public func setIsExcludedFromBackup(_ value: Bool, to url: URL) throws {
        setIsExcludedFromBackupValue = value
        setIsExcludedFromBackupURL = url
        try setIsExcludedFromBackupResult.get()
    }

    public func write(_ data: Data, to url: URL) throws {
        writeDataData = data
        writeDataURL = url
        try writeDataResult.get()
    }
}
