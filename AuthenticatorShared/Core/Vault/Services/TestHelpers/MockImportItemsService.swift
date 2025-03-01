import Foundation

@testable import AuthenticatorShared

class MockImportItemsService: ImportItemsService {
    var errorToThrow: Error?
    var importItemsData: Data?
    var importItemsUrl: URL?
    var importItemsFormat: ImportFileFormat?

    func importItems(data: Data, format: ImportFileFormat) async throws {
        if let errorToThrow { throw errorToThrow }
        importItemsData = data
        importItemsFormat = format
    }

    func importItems(url: URL, format: ImportFileFormat) async throws {
        if let errorToThrow { throw errorToThrow }
        importItemsUrl = url
        importItemsFormat = format
    }
}
