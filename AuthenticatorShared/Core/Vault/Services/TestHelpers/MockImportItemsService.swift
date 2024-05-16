import Foundation

@testable import AuthenticatorShared

class MockImportItemsService: ImportItemsService {
    var importItemsData: Data?
    var importItemsUrl: URL?
    var importItemsFormat: ImportFileFormat?

    func importItems(data: Data, format: ImportFileFormat) async throws {
        importItemsData = data
        importItemsFormat = format
    }

    func importItems(url: URL, format: ImportFileFormat) async throws {
        importItemsUrl = url
        importItemsFormat = format
    }
}
