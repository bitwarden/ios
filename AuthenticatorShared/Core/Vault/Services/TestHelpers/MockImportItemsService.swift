import Foundation

@testable import AuthenticatorShared

class MockImportItemsService: ImportItemsService {
    var importItemsData: Data?
    var importItemsUrl: URL?
    var importItemsFormat: ImportFileType?

    func importItems(data: Data, format: ImportFileType) async throws {
        importItemsData = data
        importItemsFormat = format
    }

    func importItems(url: URL, format: ImportFileType) async throws {
        importItemsUrl = url
        importItemsFormat = format
    }
}
