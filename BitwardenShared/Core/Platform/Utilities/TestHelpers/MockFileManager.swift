import Foundation

@testable import BitwardenShared

class MockFileManager: FileManagerProtocol {
    var appendDataData: Data?
    var appendDataResult: Result<Void, Error> = .success(())
    var appendDataURL: URL?

    var attributesOfItemPath: String?
    var attributesOfItemResult: Result<[FileAttributeKey: Any], Error> = .success([:])

    var createDirectoryURL: URL?
    var createDirectoryCreateIntermediates: Bool?
    var createDirectoryResult: Result<Void, Error> = .success(())

    var removeItemURLs = [URL]()
    var removeItemResult: Result<Void, Error> = .success(())

    var setIsExcludedFromBackupValue: Bool?
    var setIsExcludedFromBackupURL: URL?
    var setIsExcludedFromBackupResult: Result<Void, Error> = .success(())

    var writeDataData: Data?
    var writeDataURL: URL?
    var writeDataResult: Result<Void, Error> = .success(())

    func append(_ data: Data, to url: URL) throws {
        appendDataData = data
        appendDataURL = url
        try appendDataResult.get()
    }

    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        attributesOfItemPath = path
        return try attributesOfItemResult.get()
    }

    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws {
        createDirectoryURL = url
        createDirectoryCreateIntermediates = createIntermediates
        try createDirectoryResult.get()
    }

    func removeItem(at url: URL) throws {
        removeItemURLs.append(url)
        try removeItemResult.get()
    }

    func setIsExcludedFromBackup(_ value: Bool, to url: URL) throws {
        setIsExcludedFromBackupValue = value
        setIsExcludedFromBackupURL = url
        try setIsExcludedFromBackupResult.get()
    }

    func write(_ data: Data, to url: URL) throws {
        writeDataData = data
        writeDataURL = url
        try writeDataResult.get()
    }
}
