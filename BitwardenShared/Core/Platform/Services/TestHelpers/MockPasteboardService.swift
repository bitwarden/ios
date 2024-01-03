@testable import BitwardenShared

class MockPasteboardService: PasteboardService {
    var clearClipboardValue: ClearClipboardValue = .never
    var copiedString: String?

    func copy(_ string: String) {
        copiedString = string
    }

    func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue) {
        self.clearClipboardValue = clearClipboardValue
    }
}
