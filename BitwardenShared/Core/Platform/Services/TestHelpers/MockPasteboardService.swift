@testable import BitwardenShared

class MockPasteboardService: PasteboardService {
    var copiedString: String?

    func copy(_ string: String) {
        copiedString = string
    }
}
